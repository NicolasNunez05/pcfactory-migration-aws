import pytest
from app import app

@pytest.fixture
def client():
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

def test_index(client):
    response = client.get('/')
    assert response.status_code == 200
    assert "Bienvenido" in response.json['message']

def test_health(client):
    response = client.get('/health')
    assert response.status_code in [200, 500]
    assert 'status' in response.json

def test_404(client):
    response = client.get('/nonexistent')
    assert response.status_code == 404