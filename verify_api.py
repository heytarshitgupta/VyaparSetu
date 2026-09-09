import sys
from pathlib import Path

sys.path.insert(0, str(Path.cwd()))

from pricing_api import app
from fastapi.testclient import TestClient

client = TestClient(app)
response = client.post(
    '/price',
    json={
        'product_id': 'PROD000010',
        'category': 'Food processing',
        'description': 'Pure handmade organic desi jaggery block no chemicals',
    },
)

print(response.status_code)
print(response.json())
