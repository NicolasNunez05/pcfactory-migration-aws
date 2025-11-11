import pytest
import sys
import os

# Agregar parent directory al path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from app import app

@pytest.fixture
def client():
    """Fixture para test client"""
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

class TestHealthCheck:
    def test_health_check(self, client):
        """Test health check endpoint"""
        response = client.get('/health')
        assert response.status_code == 200
        assert response.json['status'] == 'healthy'
    
    def test_status_endpoint(self, client):
        """Test status endpoint"""
        response = client.get('/api/v1/status')
        assert response.status_code == 200
        assert response.json['app'] == 'PCFactory'

class TestDataAPI:
    def test_create_data(self, client):
        """Test crear datos"""
        response = client.post('/api/v1/data', json={'name': 'test', 'value': 123})
        assert response.status_code == 201
        assert response.json['message'] == 'Data received'
    
    def test_create_data_empty(self, client):
        """Test crear datos sin payload"""
        response = client.post('/api/v1/data')
        assert response.status_code == 400
    
    def test_get_data(self, client):
        """Test obtener datos"""
        response = client.get('/api/v1/data')
        assert response.status_code == 200
        assert 'items' in response.json

class TestErrors:
    def test_not_found(self, client):
        """Test 404"""
        response = client.get('/nonexistent')
        assert response.status_code == 404