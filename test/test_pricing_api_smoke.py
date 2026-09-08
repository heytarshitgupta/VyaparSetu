from fastapi.testclient import TestClient

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from pricing_api import app

client = TestClient(app)

def test_price_endpoint_returns_json_with_recommended_price_and_fallback_shape():
    response = client.post(
        '/price',
        json={
            'product_id': 'PROD000010',
            'category': 'Food processing',
            'description': 'Pure handmade organic desi jaggery block no chemicals',
        },
    )

    assert response.status_code == 200, response.text
    payload = response.json()
    assert 'recommended_price' in payload
    assert 'break_even_floor' in payload
    assert 'ai_guidance' in payload
