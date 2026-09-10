import os
import sys
from pathlib import Path

try:
    from fastapi import FastAPI, HTTPException, Response
    from pydantic import BaseModel
except Exception:
    FastAPI = None
    HTTPException = None
    BaseModel = None

try:
    from flask import Flask, jsonify, request
except Exception:
    Flask = None

# Ensure imports resolve from this repo root, because the attached engine reads
# CSV/XLSX files relative to the working directory.
BASE_DIR = Path(__file__).resolve().parent
os.chdir(str(BASE_DIR))

try:
    from pricing_engine import VyaparSetuPricingEngine
except Exception as exc:
    VyaparSetuPricingEngine = None
    ENGINE_IMPORT_ERROR = exc
else:
    ENGINE_IMPORT_ERROR = None


if FastAPI is not None:
    class PriceRequest(BaseModel):
        product_id: str
        category: str
        description: str

    app = FastAPI(title='VyaparSetu Pricing API')

    @app.options('/price')
    def price_options() -> Response:
        return Response(status_code=200)

    @app.get('/health')
    def health():
        return {'ok': True}

    @app.post('/price')
    def price(payload: PriceRequest):
        try:
            engine = VyaparSetuPricingEngine() if VyaparSetuPricingEngine else None
            if engine is None:
                raise RuntimeError(f'Pricing engine import failed: {ENGINE_IMPORT_ERROR}')

            result = engine.calculate_price_for_product(
                product_id=payload.product_id,
                category=payload.category,
                description=payload.description,
                is_bulk=False,
            )

            return {
                'product_id': result.get('product_id', payload.product_id),
                'pricing_tier': result.get('pricing_tier', 'B2C Retail Tier'),
                'break_even_floor': float(result.get('break_even_floor', 0.0)),
                'recommended_price': float(result.get('recommended_price', result.get('break_even_floor', 0.0))),
                'market_ceiling': float(result.get('market_ceiling', 0.0)),
                'ai_guidance': str(result.get('ai_guidance', '')),
            }
        except Exception as exc:
            raise HTTPException(status_code=500, detail=str(exc))

else:
    app = Flask(__name__)

    class PriceRequest:
        def __init__(self, product_id, category, description):
            self.product_id = product_id
            self.category = category
            self.description = description

    @app.get('/health')
    def health():
        return jsonify({'ok': True})

    @app.post('/price')
    def price():
        payload = request.get_json(silent=True) or {}
        product_id = str(payload.get('product_id', ''))
        category = str(payload.get('category', ''))
        description = str(payload.get('description', ''))

        try:
            engine = VyaparSetuPricingEngine() if VyaparSetuPricingEngine else None
            if engine is None:
                raise RuntimeError(f'Pricing engine import failed: {ENGINE_IMPORT_ERROR}')

            result = engine.calculate_price_for_product(
                product_id=product_id,
                category=category,
                description=description,
                is_bulk=False,
            )
            return jsonify({
                'product_id': result.get('product_id', product_id),
                'pricing_tier': result.get('pricing_tier', 'B2C Retail Tier'),
                'break_even_floor': float(result.get('break_even_floor', 0.0)),
                'recommended_price': float(result.get('recommended_price', result.get('break_even_floor', 0.0))),
                'market_ceiling': float(result.get('market_ceiling', 0.0)),
                'ai_guidance': str(result.get('ai_guidance', '')),
            })
        except Exception as exc:
            return jsonify({'error': str(exc)}), 500


if __name__ == '__main__':
    if FastAPI is not None:
        import uvicorn
        uvicorn.run(app, host='0.0.0.0', port=8000)
    elif Flask is not None:
        app.run(host='0.0.0.0', port=8000, debug=False)
    else:
        print('No web framework available. Install fastapi or flask.')
        sys.exit(1)
