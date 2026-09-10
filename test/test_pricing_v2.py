"""
VyaparSetu Dynamic Pricing V2 — Comprehensive Test Suite
=========================================================
18 required cases + structural assertions.
Run with:
    .venv-pricing/bin/python -m pytest test/test_pricing_v2.py -v
"""

from __future__ import annotations

import math
import sys
from pathlib import Path

import pytest

# Ensure repo root is on path
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from fastapi.testclient import TestClient

# ── Import app and engine ──────────────────────────────────────────────────
from pricing_api import app, _load_engine

# Ensure engine loaded for tests
_load_engine()

client = TestClient(app)


# ─────────────────────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────────────────────

def _price(payload: dict) -> dict:
    resp = client.post("/price", json=payload)
    assert resp.status_code == 200, f"Expected 200, got {resp.status_code}: {resp.text}"
    data = resp.json()
    # Structural assertions on every successful response
    for field in [
        "suggested_price", "suggested_price_low", "suggested_price_high",
        "confidence", "reason", "signals_used",
    ]:
        assert field in data, f"Missing field: {field}"
    assert data["confidence"] in {"high", "medium", "low"}
    assert isinstance(data["signals_used"], list)
    return data


CANDLE_BASE = {
    "product_name": "Handmade Soy Wax Candle",
    "category": "candles",
    "description": "Hand-poured soy wax scented candle in a reusable decorative jar",
}

CANDLE_WITH_COST = {
    **CANDLE_BASE,
    "raw_material_cost": 220,
    "packaging_cost": 40,
    "labor_cost": 100,
    "other_cost": 20,
    "production_quantity": 2,
    "desired_margin_percent": 25,
}


# ─────────────────────────────────────────────────────────────────────────────
# Case 1 — Known product style (product exists in profile by ID)
# ─────────────────────────────────────────────────────────────────────────────
def test_case_01_known_product_style():
    data = _price({
        "product_name": "Desi Jaggery (Gur)",
        "category": "food processing",
        "description": "100% organic pure desi gur handmade no chemicals",
        "product_id": "PROD000010",
    })
    assert data["suggested_price"] > 0


# ─────────────────────────────────────────────────────────────────────────────
# Case 2 — Unknown product UUID (not in any CSV)
# ─────────────────────────────────────────────────────────────────────────────
def test_case_02_unknown_product_uuid():
    data = _price({
        "product_name": "Mystery Widget",
        "category": "manufacturing",
        "description": "An entirely new product not in any dataset",
        "product_id": "PROD-UNKNOWN-9999",
    })
    assert data["suggested_price"] > 0


# ─────────────────────────────────────────────────────────────────────────────
# Case 3 — product_id entirely omitted
# ─────────────────────────────────────────────────────────────────────────────
def test_case_03_product_id_omitted():
    data = _price({
        "product_name": "Handmade Soy Wax Candle",
        "category": "candles",
        "description": "Hand-poured soy wax scented candle in a reusable decorative jar",
    })
    assert data["suggested_price"] > 0


# ─────────────────────────────────────────────────────────────────────────────
# Case 4 — Unknown producer ID
# ─────────────────────────────────────────────────────────────────────────────
def test_case_04_unknown_producer_id():
    data = _price({
        "product_name": "Handmade Soy Wax Candle",
        "category": "candles",
        "description": "Hand-poured soy wax scented candle",
        "producer_id": "PROD-UNKNOWN-ARTISAN-XYZ",
    })
    assert data["suggested_price"] > 0


# ─────────────────────────────────────────────────────────────────────────────
# Case 5 — Unseen category (candles)
# ─────────────────────────────────────────────────────────────────────────────
def test_case_05_unseen_category():
    data = _price(CANDLE_BASE)
    assert data["suggested_price"] > 0
    # Must still have a sensible price (not zero/null)
    assert data["suggested_price"] >= 50


# ─────────────────────────────────────────────────────────────────────────────
# Case 6 — Unseen category with cost data
# ─────────────────────────────────────────────────────────────────────────────
def test_case_06_unseen_category_with_costs():
    data = _price(CANDLE_WITH_COST)
    assert data["suggested_price"] > 0
    assert data["estimated_unit_cost"] is not None
    assert data["cost_floor"] is not None


# ─────────────────────────────────────────────────────────────────────────────
# Case 7 — No cost data at all
# ─────────────────────────────────────────────────────────────────────────────
def test_case_07_no_cost_data():
    data = _price(CANDLE_BASE)
    assert data["estimated_unit_cost"] is None
    assert data["cost_floor"] is None
    assert data["suggested_price"] > 0


# ─────────────────────────────────────────────────────────────────────────────
# Case 8 — Complete cost data
# ─────────────────────────────────────────────────────────────────────────────
def test_case_08_complete_cost_data():
    data = _price(CANDLE_WITH_COST)
    # batch = 220+40+100+20 = 380, qty = 2, unit_cost = 190
    assert data["estimated_unit_cost"] == pytest.approx(190.0, abs=0.01)
    assert data["cost_floor"] is not None
    assert data["cost_floor"] > 190.0  # floor includes margin


# ─────────────────────────────────────────────────────────────────────────────
# Case 9 — Custom desired margin
# ─────────────────────────────────────────────────────────────────────────────
def test_case_09_custom_desired_margin():
    base = _price(CANDLE_WITH_COST)  # 25% margin
    high_margin = _price({**CANDLE_WITH_COST, "desired_margin_percent": 60})
    # Higher margin must produce higher or equal cost_floor
    assert high_margin["cost_floor"] >= base["cost_floor"]


# ─────────────────────────────────────────────────────────────────────────────
# Case 10 — suggested_price >= cost_floor
# ─────────────────────────────────────────────────────────────────────────────
def test_case_10_suggested_price_gte_cost_floor():
    data = _price(CANDLE_WITH_COST)
    assert data["suggested_price"] >= data["cost_floor"]


# ─────────────────────────────────────────────────────────────────────────────
# Case 11 — bulk_price >= cost_floor
# ─────────────────────────────────────────────────────────────────────────────
def test_case_11_bulk_price_gte_cost_floor():
    data = _price(CANDLE_WITH_COST)
    assert data["bulk_price"] is not None
    assert data["bulk_price"] >= data["cost_floor"]


# ─────────────────────────────────────────────────────────────────────────────
# Case 12 — Unknown WPI mapping (candles → neutral)
# ─────────────────────────────────────────────────────────────────────────────
def test_case_12_unknown_wpi_mapping():
    data = _price(CANDLE_BASE)
    # Should still succeed with a valid price (WPI fallback = 1.0)
    assert data["suggested_price"] > 0
    # wpi_adjustment should NOT appear in signals (neutral category)
    assert "wpi_adjustment" not in data["signals_used"]


# ─────────────────────────────────────────────────────────────────────────────
# Case 13 — No demand signals
# ─────────────────────────────────────────────────────────────────────────────
def test_case_13_no_demand_signals():
    data = _price(CANDLE_BASE)
    demand_sigs = {
        "active_buyer_demand", "buyer_target_price", "recent_completed_price"
    }
    assert not demand_sigs.intersection(data["signals_used"])


# ─────────────────────────────────────────────────────────────────────────────
# Case 14 — Negative cost rejected with 422
# ─────────────────────────────────────────────────────────────────────────────
def test_case_14_negative_cost_rejected():
    resp = client.post("/price", json={**CANDLE_BASE, "raw_material_cost": -100})
    assert resp.status_code == 422


# ─────────────────────────────────────────────────────────────────────────────
# Case 15 — Zero quantity rejected with 422
# ─────────────────────────────────────────────────────────────────────────────
def test_case_15_zero_quantity_rejected():
    resp = client.post("/price", json={**CANDLE_BASE, "production_quantity": 0})
    assert resp.status_code == 422


# ─────────────────────────────────────────────────────────────────────────────
# Case 16 — NaN rejected (sent as string "nan" — JSON-safe way to test)
# ─────────────────────────────────────────────────────────────────────────────
def test_case_16_nan_rejected():
    # Python json module cannot serialize float("nan"); send as string
    # which Pydantic's float validator must reject with 422.
    resp = client.post(
        "/price",
        content=b'{"product_name":"Candle","category":"candles","description":"test","raw_material_cost":"nan"}',
        headers={"Content-Type": "application/json"},
    )
    assert resp.status_code == 422


# ─────────────────────────────────────────────────────────────────────────────
# Case 17 — Infinity rejected (sent as string "Infinity" — JSON-safe)
# ─────────────────────────────────────────────────────────────────────────────
def test_case_17_infinity_rejected():
    # JSON spec does not support Infinity; send string which must be rejected.
    resp = client.post(
        "/price",
        content=b'{"product_name":"Candle","category":"candles","description":"test","raw_material_cost":"Infinity"}',
        headers={"Content-Type": "application/json"},
    )
    assert resp.status_code == 422


# ─────────────────────────────────────────────────────────────────────────────
# Case 18 — pricing_profile product ID absence no longer fails
# ─────────────────────────────────────────────────────────────────────────────
def test_case_18_absent_product_id_no_longer_fails():
    """
    V1 engine raised ValueError for product IDs not in pricing_profile.csv.
    V2 must succeed for any product_id.
    """
    data = _price({
        "product_name": "Handmade Soy Wax Candle",
        "category": "candles",
        "description": "Hand-poured soy wax scented candle",
        "product_id": "PROD-NOT-IN-CSV-AT-ALL",
    })
    assert data["suggested_price"] > 0


# ─────────────────────────────────────────────────────────────────────────────
# Additional structural tests
# ─────────────────────────────────────────────────────────────────────────────

def test_health_endpoint():
    resp = client.get("/health")
    assert resp.status_code == 200
    assert resp.json()["ok"] is True


def test_phulkari_no_product_id():
    """Required real-product test: Phulkari Dupatta without product_id."""
    data = _price({
        "product_name": "Hand Embroidered Phulkari Dupatta",
        "category": "clothing",
        "description": "Hand embroidered traditional Punjabi phulkari dupatta",
    })
    assert data["suggested_price"] > 0
    assert data["confidence"] in {"high", "medium", "low"}


def test_demand_signals_used_when_provided():
    data = _price({
        **CANDLE_BASE,
        "active_request_count": 10,
        "average_target_price": 700,
    })
    assert "active_buyer_demand" in data["signals_used"]
    assert "buyer_target_price" in data["signals_used"]


def test_candle_no_cost_response_shape():
    """Candle no-cost: complete response shape check."""
    data = _price(CANDLE_BASE)
    assert data["estimated_unit_cost"] is None
    assert data["cost_floor"] is None
    assert data["suggested_price"] > 0
    assert data["suggested_price_low"] > 0
    assert data["suggested_price_high"] > 0
    assert data["suggested_price_high"] >= data["suggested_price_low"]
    assert "Add your making cost" in data["reason"]


def test_candle_with_cost_unit_cost_exact():
    """batch=380, qty=2 → unit_cost=190 exactly."""
    data = _price(CANDLE_WITH_COST)
    assert data["estimated_unit_cost"] == pytest.approx(190.0, abs=0.01)
    # cost_floor = 190 * 1.25 = 237.5
    assert data["cost_floor"] == pytest.approx(237.5, abs=0.01)


def test_negative_margin_treated_as_default():
    """Negative desired_margin_percent is rejected by validator with 422.
    The spec requires the field to be >= 0 or omitted. -10 is invalid input."""
    resp = client.post("/price", json={**CANDLE_WITH_COST, "desired_margin_percent": -10})
    assert resp.status_code == 422


def test_blank_product_name_rejected():
    resp = client.post("/price", json={**CANDLE_BASE, "product_name": "   "})
    assert resp.status_code == 422


def test_missing_required_fields_rejected():
    resp = client.post("/price", json={"product_name": "Test"})
    assert resp.status_code == 422
