from flask import Flask, jsonify, request
from datetime import datetime
import os

app = Flask(__name__)

@app.route('/health', methods=['GET'])
def health():
    """Endpoint para health check"""
    return jsonify({
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
        "version": "1.0.0"
    }), 200

@app.route('/api/v1/status', methods=['GET'])
def status():
    """Estado de la aplicación"""
    return jsonify({
        "app": "PCFactory",
        "environment": os.getenv('ENVIRONMENT', 'development'),
        "status": "running"
    }), 200

@app.route('/api/v1/data', methods=['POST'])
def create_data():
    """Crear datos"""
    data = request.get_json()
    if not data:
        return jsonify({"error": "No data provided"}), 400
    
    return jsonify({
        "message": "Data received",
        "data": data,
        "received_at": datetime.now().isoformat()
    }), 201

@app.route('/api/v1/data', methods=['GET'])
def get_data():
    """Obtener datos"""
    return jsonify({
        "items": [],
        "total": 0
    }), 200

@app.errorhandler(404)
def not_found(error):
    return jsonify({"error": "Not found"}), 404

@app.errorhandler(500)
def internal_error(error):
    return jsonify({"error": "Internal server error"}), 500

if __name__ == '__main__':
    port = int(os.getenv('PORT', 8080))
    debug = os.getenv('DEBUG', 'False').lower() == 'true'
    app.run(host='0.0.0.0', port=port, debug=debug)