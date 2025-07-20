from flask import Flask, request, render_template, jsonify
import requests
import os
from app import app

@app.route('/')
def index():
    return render_template('')

@app.post('/start_pipeline')
def start_pipeline():
    # Verifica della chiave API
    auth_header = request.headers.get('Authorization')
    expected_token = f"Bearer {app.config['BACKEND_API_KEY']}"

    if not auth_header or auth_header != expected_token:
        return jsonify({"msg": "Unauthorized"}), 401

    data = request.get_json()

    scan_url = data.get('scan_url')
    step_url = data.get('step_url')
    user_id = data.get('user')
    scan_id = data.get('scan_id')

    if not scan_url or not step_url:
        return jsonify({"msg": "scan_url and step_url are required"}), 400

    try:
        # Scarico il file di scansione
        scan_response = requests.get(scan_url, timeout=30)
        scan_response.raise_for_status()

        # Scarico il file step
        step_response = requests.get(step_url, timeout=30)
        step_response.raise_for_status()

        # Creo una directory temporanea per salvare i dati che verranno usati dalla pipeline
        os.makedirs('/tmp/scans', exist_ok=True)
        os.makedirs('/tmp/steps', exist_ok=True)

        # Salvo temporaneamente i file
        # TODO: capire estensione dei file
        scan_filename = f"/tmp/scans/{scan_id}_scan"
        step_filename = f"/tmp/steps/{scan_id}_step"

        with open(scan_filename, 'wb') as scan_file:
            scan_file.write(scan_response.content)

        with open(step_filename, 'wb') as step_file:
            step_file.write(step_response.content)

        # TODO: Avviare la pipeline con i file scaricati in parallelo rispetto a questo thread

        # Elimino i file temporanei
        os.remove(scan_filename)
        os.remove(step_filename)

        return jsonify({"msg": "Pipeline started successfully"}), 200
    except requests.exceptions.RequestException as e:
        return jsonify({"msg": f"Errore durante il download: {str(e)}"}), 500
    except Exception as e:
        return jsonify({"msg": f"Errore durante l'elaborazione: {str(e)}"}), 500