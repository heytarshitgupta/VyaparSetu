"""
VyaparSetu Dynamic Pricing Engine — V2
=======================================
Accepts free-text product attributes + optional cost breakdown.
Does NOT require product_id or producer_id.
Deterministic fallback hierarchy for unseen categories.
"""

from __future__ import annotations

import math
import os
import warnings
from pathlib import Path
from typing import Any, Optional

import numpy as np
import pandas as pd
from sklearn.compose import ColumnTransformer
from sklearn.ensemble import RandomForestRegressor
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import OneHotEncoder

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
BASE_DIR = Path(__file__).resolve().parent
DEFAULT_MARGIN = 0.25          # 25% – documented default when not supplied
BULK_DISCOUNT = 0.85           # bulk price = suggested * 0.85
BULK_MARGIN_FLOOR = 0.10       # bulk price >= cost_floor * 1.10
MARKETPLACE_PRIOR_PRICE = 450  # conservative prior when ALL comparables absent

# WPI category mapping (artisan product label → WPI group name)
WPI_CATEGORY_MAP: dict[str, str] = {
    "food processing": "Manufacture Of Food Products",
    "food": "Manufacture Of Food Products",
    "food articles": "Food Articles",
    "textile": "Manufacture Of Textiles",
    "textiles": "Manufacture Of Textiles",
    "handloom": "Manufacture Of Wearing Apparel",
    "clothing": "Manufacture Of Wearing Apparel",
    "apparel": "Manufacture Of Wearing Apparel",
    "handicraft": "Manufacture Of Wood And Products Of Wood And Cork, Except Furniture; Manufacture Of Articles Of Straw And Plaiting Materials",
    "manufacturing": "Manufacture Of Fabricated Metal Products",
    "leather": "Manufacture Of Leather And Related Products",
    "metal": "Manufacture Of Fabricated Metal Products",
    "wood": "Manufacture Of Wood And Products Of Wood And Cork, Except Furniture; Manufacture Of Articles Of Straw And Plaiting Materials",
}

# Retail category normalisation (loose label → retail_benchmark Category column)
RETAIL_CATEGORY_MAP: dict[str, str] = {
    "food processing": "Food",
    "food": "Food",
    "food articles": "Food",
    "handloom": "Handloom",
    "textile": "Handloom",
    "textiles": "Handloom",
    "clothing": "Handloom",
    "apparel": "Handloom",
    "handicraft": "Handicraft",
    "wood": "Handicraft",
    "manufacturing": "Manufacturing",
    "metal": "Manufacturing",
    "leather": "Handicraft",
}


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _safe_float(v: Any, default: float = 0.0) -> float:
    """Convert value to float; return default for None/NaN/Inf."""
    if v is None:
        return default
    try:
        f = float(v)
    except (TypeError, ValueError):
        return default
    if math.isnan(f) or math.isinf(f):
        return default
    return f


def _normalise_category(raw: str) -> str:
    return raw.strip().lower()


# ---------------------------------------------------------------------------
# Main Engine
# ---------------------------------------------------------------------------

class VyaparSetuPricingEngine:
    """
    V2 Pricing Engine.

    Instantiate once; call ``price_product()`` per request.
    All data files are loaded relative to BASE_DIR.
    Missing data files degrade gracefully – only WPI/CSV enrichment is skipped.
    """

    def __init__(self) -> None:
        self._load_data()
        self._ml_model: Optional[Pipeline] = None
        if self._retail_df is not None:
            try:
                self._ml_model = self._train_model(self._retail_df)
            except Exception as exc:  # noqa: BLE001
                warnings.warn(f"[PricingEngine] ML model training skipped: {exc}")

    # ------------------------------------------------------------------
    # Data loading
    # ------------------------------------------------------------------

    def _load_data(self) -> None:
        self._pricing_profiles: Optional[pd.DataFrame] = self._load_csv("pricing_profile.csv")
        self._buyer_requests: Optional[pd.DataFrame] = self._load_csv("buyer_request.csv")
        self._retail_df: Optional[pd.DataFrame] = self._load_csv("retail_benchmark.csv")
        self._wpi_df: Optional[pd.DataFrame] = self._load_wpi()

    def _load_csv(self, filename: str) -> Optional[pd.DataFrame]:
        path = BASE_DIR / filename
        if not path.exists():
            warnings.warn(f"[PricingEngine] {filename} not found – skipping.")
            return None
        try:
            return pd.read_csv(path)
        except Exception as exc:  # noqa: BLE001
            warnings.warn(f"[PricingEngine] Failed to load {filename}: {exc}")
            return None

    def _load_wpi(self) -> Optional[pd.DataFrame]:
        for name in ["wpi_3 (1).xlsx", "wpi_3.xlsx", "wpi.xlsx"]:
            path = BASE_DIR / name
            if path.exists():
                try:
                    df = pd.read_excel(path, sheet_name="WPI Data")
                    return df
                except Exception as exc:  # noqa: BLE001
                    warnings.warn(f"[PricingEngine] WPI load failed: {exc}")
        return None

    # ------------------------------------------------------------------
    # ML model
    # ------------------------------------------------------------------

    def _train_model(self, retail: pd.DataFrame) -> Pipeline:
        preprocessor = ColumnTransformer(
            transformers=[
                ("cat", OneHotEncoder(handle_unknown="ignore"), ["Category"]),
                ("text", TfidfVectorizer(max_features=100, stop_words="english"), "Description"),
            ]
        )
        pipeline = Pipeline(
            [
                ("preprocessor", preprocessor),
                ("regressor", RandomForestRegressor(n_estimators=100, random_state=42)),
            ]
        )
        pipeline.fit(retail[["Category", "Description"]], retail["Selling_Price"])
        return pipeline

    # ------------------------------------------------------------------
    # WPI adjustment
    # ------------------------------------------------------------------

    def _wpi_multiplier(self, category_raw: str) -> float:
        """Returns WPI inflation multiplier; 1.0 on any failure."""
        if self._wpi_df is None:
            return 1.0
        wpi_group = WPI_CATEGORY_MAP.get(_normalise_category(category_raw))
        if not wpi_group:
            return 1.0  # unknown category → neutral
        try:
            matched = self._wpi_df[self._wpi_df["group"] == wpi_group]
            if matched.empty:
                return 1.0
            return float(matched["index_value"].mean()) / 100.0
        except Exception:  # noqa: BLE001
            return 1.0

    # ------------------------------------------------------------------
    # Cost floor
    # ------------------------------------------------------------------

    def _compute_cost_floor(
        self,
        raw_material_cost: Optional[float],
        packaging_cost: Optional[float],
        labor_cost: Optional[float],
        other_cost: Optional[float],
        production_quantity: Optional[float],
        desired_margin_percent: Optional[float],
    ) -> tuple[Optional[float], Optional[float]]:
        """
        Returns (estimated_unit_cost, cost_floor).
        Both None when no cost data provided.
        """
        has_cost = any(
            v is not None
            for v in [raw_material_cost, packaging_cost, labor_cost, other_cost]
        )
        if not has_cost:
            return None, None

        batch = (
            _safe_float(raw_material_cost)
            + _safe_float(packaging_cost)
            + _safe_float(labor_cost)
            + _safe_float(other_cost)
        )

        qty = _safe_float(production_quantity, default=1.0)
        if qty <= 0:
            qty = 1.0

        unit_cost = batch / qty

        margin = _safe_float(desired_margin_percent)
        if margin <= 0 or margin >= 100:
            margin = DEFAULT_MARGIN * 100  # 25
        margin_frac = margin / 100.0

        cost_floor = unit_cost * (1 + margin_frac)
        return round(unit_cost, 2), round(cost_floor, 2)

    # ------------------------------------------------------------------
    # Market comparable lookup
    # ------------------------------------------------------------------

    def _market_comparables(
        self,
        category_raw: str,
        product_name: str,
        description: str,
    ) -> tuple[Optional[float], list[float], str]:
        """
        Returns (ml_prediction, comparable_prices, method_used).
        Uses fallback hierarchy:
          1. ML model on normalised retail category + description
          2. Same-category retail benchmark prices
          3. Text-similar retail benchmark prices
          4. All retail benchmark prices (median)
          5. pricing_profile derived prices (aggregate)
          6. marketplace prior
        """
        norm_cat = _normalise_category(category_raw)
        retail_cat = RETAIL_CATEGORY_MAP.get(norm_cat)
        comparable_prices: list[float] = []
        ml_pred: Optional[float] = None
        method = "marketplace_prior"

        # 1. ML prediction
        if self._ml_model is not None and self._retail_df is not None:
            pred_cat = retail_cat or "Food"  # fallback known category for ML
            try:
                pred_df = pd.DataFrame([{"Category": pred_cat, "Description": description or product_name}])
                ml_pred = float(self._ml_model.predict(pred_df)[0])
                method = "ml_random_forest"
            except Exception:  # noqa: BLE001
                ml_pred = None

        # 2. Same-category retail comparables
        if self._retail_df is not None and retail_cat:
            same_cat = self._retail_df[self._retail_df["Category"] == retail_cat]
            if not same_cat.empty:
                comparable_prices = same_cat["Selling_Price"].dropna().tolist()
                method = "same_category_benchmark"

        # 3. Text-similar retail comparables (TF-IDF cosine on description)
        if self._retail_df is not None and len(comparable_prices) < 3:
            try:
                query = f"{product_name} {description}".strip().lower()
                corpus = self._retail_df["Description"].fillna("").tolist()
                vec = TfidfVectorizer(max_features=200, stop_words="english")
                tfidf = vec.fit_transform(corpus + [query])
                sims = (tfidf[:-1] @ tfidf[-1].T).toarray().flatten()
                top_idx = sims.argsort()[::-1][:5]
                top_prices = self._retail_df.iloc[top_idx]["Selling_Price"].dropna().tolist()
                if top_prices:
                    comparable_prices = list(set(comparable_prices + top_prices))
                    method = "text_similar_benchmark"
            except Exception:  # noqa: BLE001
                pass

        # 4. Broader retail median
        if self._retail_df is not None and not comparable_prices:
            all_prices = self._retail_df["Selling_Price"].dropna().tolist()
            if all_prices:
                comparable_prices = all_prices
                method = "marketplace_median"

        # 5. pricing_profile derived prices as fallback
        if not comparable_prices and self._pricing_profiles is not None:
            try:
                pp = self._pricing_profiles.copy()
                pp["derived_price"] = (
                    (pp["base_material_cost"] * pp["material_qty"])
                    + (pp["labor_hours_per_unit"] * pp["hourly_wage_inr"])
                    + pp["packaging_cost_inr"]
                ) * (1 + pp["target_margin_pct"])
                comparable_prices = pp["derived_price"].dropna().tolist()
                method = "profile_derived_prior"
            except Exception:  # noqa: BLE001
                pass

        return ml_pred, comparable_prices, method

    # ------------------------------------------------------------------
    # Demand signal adjustment
    # ------------------------------------------------------------------

    def _demand_adjustment(
        self,
        base_price: float,
        active_request_count: Optional[int],
        average_target_price: Optional[float],
        recent_completed_price: Optional[float],
        completed_order_count: Optional[int],
    ) -> tuple[float, list[str]]:
        """Modest adjustments from live demand signals. Returns (adjusted, signals_used)."""
        adjusted = base_price
        signals: list[str] = []

        if active_request_count is not None and active_request_count > 5:
            adjusted *= 1.05
            signals.append("active_buyer_demand")

        if average_target_price is not None and average_target_price > 0:
            # Weight: 30% buyer target, 70% current
            adjusted = 0.70 * adjusted + 0.30 * average_target_price
            signals.append("buyer_target_price")

        if recent_completed_price is not None and recent_completed_price > 0:
            # Weight: 20% recent transaction, 80% current
            adjusted = 0.80 * adjusted + 0.20 * recent_completed_price
            signals.append("recent_completed_price")

        return adjusted, signals

    # ------------------------------------------------------------------
    # Confidence scoring
    # ------------------------------------------------------------------

    def _confidence(
        self,
        comparable_prices: list[float],
        ml_pred: Optional[float],
        has_cost: bool,
        method: str,
    ) -> str:
        if has_cost and len(comparable_prices) >= 5 and ml_pred is not None:
            return "high"
        if has_cost or (len(comparable_prices) >= 3 and ml_pred is not None):
            return "medium"
        if comparable_prices or ml_pred is not None:
            return "medium"
        return "low"

    # ------------------------------------------------------------------
    # Public API
    # ------------------------------------------------------------------

    def price_product(
        self,
        *,
        product_name: str,
        category: str,
        description: str,
        unit: Optional[str] = None,
        product_id: Optional[str] = None,
        producer_id: Optional[str] = None,
        current_price: Optional[float] = None,
        # Cost fields
        raw_material_cost: Optional[float] = None,
        packaging_cost: Optional[float] = None,
        labor_cost: Optional[float] = None,
        other_cost: Optional[float] = None,
        production_quantity: Optional[float] = None,
        desired_margin_percent: Optional[float] = None,
        # Demand signals
        active_request_count: Optional[int] = None,
        average_target_price: Optional[float] = None,
        recent_completed_price: Optional[float] = None,
        completed_order_count: Optional[int] = None,
    ) -> dict[str, Any]:
        """
        Main V2 pricing entry point. product_id and producer_id are never used
        as predictive features – they are metadata only.
        """
        # ---- Cost floor ------------------------------------------------
        estimated_unit_cost, cost_floor = self._compute_cost_floor(
            raw_material_cost,
            packaging_cost,
            labor_cost,
            other_cost,
            production_quantity,
            desired_margin_percent,
        )
        has_cost = cost_floor is not None

        # ---- WPI adjustment (secondary) --------------------------------
        wpi_mult = self._wpi_multiplier(category)

        # ---- Market comparables ----------------------------------------
        ml_pred, comparable_prices, method = self._market_comparables(
            category, product_name, description
        )

        # ---- Base price synthesis --------------------------------------
        signals_used: list[str] = [method]

        if comparable_prices:
            median_comparable = float(np.median(comparable_prices))
            p25 = float(np.percentile(comparable_prices, 25))
            p75 = float(np.percentile(comparable_prices, 75))
        else:
            median_comparable = MARKETPLACE_PRIOR_PRICE
            p25 = MARKETPLACE_PRIOR_PRICE * 0.80
            p75 = MARKETPLACE_PRIOR_PRICE * 1.20

        # Blend ML prediction with comparable median
        if ml_pred is not None:
            base_price = 0.55 * ml_pred + 0.45 * median_comparable
            signals_used.append("ml_prediction")
        else:
            base_price = median_comparable

        # Apply WPI only for known mapped categories
        if wpi_mult != 1.0:
            base_price *= wpi_mult
            signals_used.append("wpi_adjustment")

        # ---- Demand signal adjustment ----------------------------------
        base_price, demand_sigs = self._demand_adjustment(
            base_price,
            active_request_count,
            average_target_price,
            recent_completed_price,
            completed_order_count,
        )
        signals_used.extend(demand_sigs)

        # ---- Enforce cost floor ----------------------------------------
        if cost_floor is not None:
            base_price = max(base_price, cost_floor)

        suggested_price = round(base_price, 2)
        suggested_low = round(max(p25, cost_floor or 0.0), 2)
        suggested_high = round(p75, 2)

        # Ensure low <= suggested <= high makes semantic sense
        if suggested_low > suggested_price:
            suggested_low = round(suggested_price * 0.88, 2)
        if suggested_high < suggested_price:
            suggested_high = round(suggested_price * 1.18, 2)

        # ---- Bulk price ------------------------------------------------
        bulk_raw = suggested_price * BULK_DISCOUNT
        if cost_floor is not None:
            bulk_floor = cost_floor * (1 + BULK_MARGIN_FLOOR)
            bulk_price = round(max(bulk_raw, bulk_floor), 2)
        else:
            bulk_price = round(bulk_raw, 2)

        # ---- Market typical price -------------------------------------
        market_typical = round(median_comparable, 2) if comparable_prices else None

        # ---- Confidence -----------------------------------------------
        confidence = self._confidence(comparable_prices, ml_pred, has_cost, method)

        # ---- Human reason text ----------------------------------------
        if has_cost and comparable_prices:
            reason = (
                f"Based on your making cost and similar market products, "
                f"₹{suggested_price:,.0f} is a balanced price."
            )
        elif has_cost:
            reason = (
                f"Based on your making cost (₹{estimated_unit_cost:,.0f} per unit). "
                f"Add market comparables for a stronger suggestion."
            )
        elif comparable_prices:
            reason = (
                f"Similar products usually sell between ₹{suggested_low:,.0f} "
                f"and ₹{suggested_high:,.0f}. "
                f"₹{suggested_price:,.0f} is a balanced price based on available market data. "
                f"Add your making cost for a stronger suggestion."
            )
        else:
            reason = (
                f"Based on a conservative marketplace estimate. "
                f"Add your making cost and category for a stronger suggestion."
            )

        return {
            "suggested_price": suggested_price,
            "suggested_price_low": suggested_low,
            "suggested_price_high": suggested_high,
            "market_typical_price": market_typical,
            "estimated_unit_cost": estimated_unit_cost,
            "cost_floor": cost_floor,
            "bulk_price": bulk_price,
            "confidence": confidence,
            "reason": reason,
            "signals_used": signals_used,
        }


# ---------------------------------------------------------------------------
# Quick CLI test
# ---------------------------------------------------------------------------
if __name__ == "__main__":
    engine = VyaparSetuPricingEngine()

    print("\n--- TEST 1: Soy Candle (no cost) ---")
    r1 = engine.price_product(
        product_name="Handmade Soy Wax Candle",
        category="candles",
        description="Hand-poured soy wax scented candle in a reusable decorative jar",
    )
    for k, v in r1.items():
        print(f"  {k}: {v}")

    print("\n--- TEST 2: Soy Candle (with cost) ---")
    r2 = engine.price_product(
        product_name="Handmade Soy Wax Candle",
        category="candles",
        description="Hand-poured soy wax scented candle in a reusable decorative jar",
        raw_material_cost=220,
        packaging_cost=40,
        labor_cost=100,
        other_cost=20,
        production_quantity=2,
        desired_margin_percent=25,
    )
    for k, v in r2.items():
        print(f"  {k}: {v}")

    print("\n--- TEST 3: Phulkari Dupatta (no product_id) ---")
    r3 = engine.price_product(
        product_name="Hand Embroidered Phulkari Dupatta",
        category="clothing",
        description="Hand embroidered traditional Punjabi phulkari dupatta",
    )
    for k, v in r3.items():
        print(f"  {k}: {v}")
