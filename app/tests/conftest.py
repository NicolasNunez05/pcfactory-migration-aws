#!/bin/bash
# tests/conftest.py - Configuración de pytest

import pytest
import sys
import os

# Agregar app al path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../app')))


@pytest.fixture
def client():
    """Fixture para cliente de pruebas Flask"""
    from app import create_app
    
    app = create_app()
    app.config['TESTING'] = True
    
    with app.test_client() as client:
        yield client


@pytest.fixture
def app_context():
    """Fixture para contexto de aplicación"""
    from app import create_app
    
    app = create_app()
    
    with app.app_context():
        yield app