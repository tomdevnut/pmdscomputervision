from flask import request, jsonify, current_app
from app import app
from functools import wraps
from app.queue_manager import queue_manager

def require_api_key(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        api_key = current_app.config.get('API_KEY_BACKEND')

        # Se la chiave API non è configurata, bypassa il check
        if not api_key:
            return f(*args, **kwargs)

        auth_header = request.headers.get('Authorization')
        if not auth_header or not auth_header.startswith('Bearer '):
            return jsonify({"error": "Authorization header mancante o malformato"}), 403

        provided_key = auth_header.split('Bearer ')[1]
        if provided_key != api_key:
            return jsonify({"error": "Chiave API non valida"}), 403
        
        return f(*args, **kwargs)
    return decorated_function

@app.route('/health')
def health():
    """Per controllare che sia tutto ok, non richiede autenticazione"""
    return jsonify({"status": "ok"}), 200

@app.route('/start_pipeline', methods=['POST'])
@require_api_key
def start_pipeline():
    data = request.get_json()
    if not data or 'scan_url' not in data or 'scan_id' not in data or 'step_url' not in data:
        return jsonify({"error": "JSON invalido"}), 400

    scan_url = data.get('scan_url')
    step_url = data.get('step_url')
    scan_id = data.get('scan_id')

    # Aggiungi la scansione alla coda invece di avviarla immediatamente
    queue_manager.add_scan({
        'scan_id': scan_id,
        'scan_url': scan_url,
        'step_url': step_url
    })

    return jsonify({
        "message": "Pipeline aggiunta alla coda", 
        "scan_id": scan_id,
        "queue_size": queue_manager.get_queue_size()
    }), 202