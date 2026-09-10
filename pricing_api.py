"""
VyaparSetu Pricing API — V2
============================
FastAPI server exposing the V2 pricing engine.

Port: 8001  (PRICING_API_PORT env override)

Start:
    .venv-pricing/bin/uvicorn pricing_api:app --host 0.0.0.0 --port 8001
"""

from __future__ import annotations

import math
import os
import sys
from pathlib import Path
from typing import Any, List, Optional

# Ensure working directory = repo root so data files resolve correctly
BASE_DIR = Path(__file__).resolve().parent
os.chdir(str(BASE_DIR))
sys.path.insert(0, str(BASE_DIR))

from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel, field_validator, model_validator

from pricing_engine import VyaparSetuPricingEngine

# ---------------------------------------------------------------------------
# App
# ---------------------------------------------------------------------------
app = FastAPI(
    title="VyaparSetu Pricing API",
    version="2.0.0",
    description="Dynamic pricing for artisan and MSME producers. product_id is optional.",
)

app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=r"^https?://(localhost|127\.0\.0\.1)(:[0-9]+)?$",
    allow_credentials=False,
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["*"],
)

# Singleton engine loaded at startup
_engine: Optional[VyaparSetuPricingEngine] = None
_engine_error: Optional[str] = None


@app.on_event("startup")
def _load_engine() -> None:
    global _engine, _engine_error
    try:
        _engine = VyaparSetuPricingEngine()
    except Exception as exc:  # noqa: BLE001
        _engine_error = str(exc)


# ---------------------------------------------------------------------------
# Request / Response models
# ---------------------------------------------------------------------------

def _reject_non_finite(v: Optional[float], field: str) -> Optional[float]:
    if v is None:
        return v
    if math.isnan(v) or math.isinf(v):
        raise ValueError(f"{field} must be a finite number")
    return v


def _reject_negative(v: Optional[float], field: str) -> Optional[float]:
    if v is None:
        return v
    if v < 0:
        raise ValueError(f"{field} must be >= 0")
    return v


class PriceRequestV2(BaseModel):
    # Required
    product_name: str
    category: str
    description: str

    # Optional metadata (never used as predictive features)
    product_id: Optional[str] = None
    producer_id: Optional[str] = None
    unit: Optional[str] = None
    current_price: Optional[float] = None

    # Cost fields
    raw_material_cost: Optional[float] = None
    packaging_cost: Optional[float] = None
    labor_cost: Optional[float] = None
    other_cost: Optional[float] = None
    production_quantity: Optional[float] = None
    desired_margin_percent: Optional[float] = None

    # Demand signals
    active_request_count: Optional[int] = None
    average_target_price: Optional[float] = None
    recent_completed_price: Optional[float] = None
    completed_order_count: Optional[int] = None

    @field_validator("product_name", "category", "description")
    @classmethod
    def _non_empty_str(cls, v: str) -> str:
        if not v or not v.strip():
            raise ValueError("Field must not be blank")
        return v.strip()

    @field_validator(
        "raw_material_cost", "packaging_cost", "labor_cost", "other_cost",
        mode="before",
    )
    @classmethod
    def _validate_cost(cls, v: Any) -> Any:
        if v is None:
            return v
        try:
            fv = float(v)
        except (TypeError, ValueError):
            raise ValueError("Cost field must be a number")
        if math.isnan(fv) or math.isinf(fv):
            raise ValueError("Cost field must be a finite number")
        if fv < 0:
            raise ValueError("Cost field must be >= 0")
        return fv

    @field_validator("production_quantity", mode="before")
    @classmethod
    def _validate_qty(cls, v: Any) -> Any:
        if v is None:
            return v
        try:
            fv = float(v)
        except (TypeError, ValueError):
            raise ValueError("production_quantity must be a number")
        if math.isnan(fv) or math.isinf(fv):
            raise ValueError("production_quantity must be a finite number")
        if fv <= 0:
            raise ValueError("production_quantity must be > 0")
        return fv

    @field_validator("desired_margin_percent", mode="before")
    @classmethod
    def _validate_margin(cls, v: Any) -> Any:
        if v is None:
            return v
        try:
            fv = float(v)
        except (TypeError, ValueError):
            raise ValueError("desired_margin_percent must be a number")
        if math.isnan(fv) or math.isinf(fv):
            raise ValueError("desired_margin_percent must be a finite number")
        if fv < 0:
            raise ValueError("desired_margin_percent must be >= 0")
        return fv

    @field_validator("average_target_price", "recent_completed_price", mode="before")
    @classmethod
    def _validate_signal_price(cls, v: Any) -> Any:
        if v is None:
            return v
        try:
            fv = float(v)
        except (TypeError, ValueError):
            raise ValueError("Signal price must be a number")
        if math.isnan(fv) or math.isinf(fv):
            raise ValueError("Signal price must be a finite number")
        return fv

    @field_validator("active_request_count", "completed_order_count", mode="before")
    @classmethod
    def _validate_count(cls, v: Any) -> Any:
        if v is None:
            return v
        try:
            iv = int(v)
        except (TypeError, ValueError):
            raise ValueError("Count field must be an integer")
        if iv < 0:
            raise ValueError("Count field must be >= 0")
        return iv


class PriceResponseV2(BaseModel):
    suggested_price: float
    suggested_price_low: float
    suggested_price_high: float
    market_typical_price: Optional[float]
    estimated_unit_cost: Optional[float]
    cost_floor: Optional[float]
    bulk_price: Optional[float]
    confidence: str
    reason: str
    signals_used: List[str]


# ---------------------------------------------------------------------------
# Exception handlers
# ---------------------------------------------------------------------------

@app.exception_handler(Exception)
async def _generic_handler(request: Request, exc: Exception) -> JSONResponse:
    return JSONResponse(status_code=500, content={"error": "Internal pricing error."})


# ---------------------------------------------------------------------------
# Endpoints
# ---------------------------------------------------------------------------

@app.get("/health")
def health() -> dict:
    return {
        "ok": True,
        "engine_loaded": _engine is not None,
        "engine_error": _engine_error,
        "version": "2.0.0",
    }


@app.post("/price", response_model=PriceResponseV2)
def price(payload: PriceRequestV2) -> dict:
    if _engine is None:
        raise HTTPException(
            status_code=503,
            detail=f"Pricing engine not available: {_engine_error}",
        )
    try:
        result = _engine.price_product(
            product_name=payload.product_name,
            category=payload.category,
            description=payload.description,
            unit=payload.unit,
            product_id=payload.product_id,
            producer_id=payload.producer_id,
            current_price=payload.current_price,
            raw_material_cost=payload.raw_material_cost,
            packaging_cost=payload.packaging_cost,
            labor_cost=payload.labor_cost,
            other_cost=payload.other_cost,
            production_quantity=payload.production_quantity,
            desired_margin_percent=payload.desired_margin_percent,
            active_request_count=payload.active_request_count,
            average_target_price=payload.average_target_price,
            recent_completed_price=payload.recent_completed_price,
            completed_order_count=payload.completed_order_count,
        )
        return result
    except ValueError as exc:
        raise HTTPException(status_code=422, detail=str(exc)) from exc
    except Exception as exc:  # noqa: BLE001
        raise HTTPException(status_code=500, detail="Pricing calculation failed.") from exc


# ---------------------------------------------------------------------------
# CLI entry-point
# ---------------------------------------------------------------------------
if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PRICING_API_PORT", "8001"))
    uvicorn.run(app, host="0.0.0.0", port=port)
