from flask import Flask
import firebase_admin
from firebase_admin import credentials
import json
from app.config import Config

app = Flask(__name__)
app.config.from_object(Config)

try:
    service_account_str = app.config.get("FIREBASE_SERVICE_ACCOUNT_KEY")
    
    if service_account_str:
        service_account_info = json.loads(service_account_str)
        cred = credentials.Certificate(service_account_info)
        firebase_admin.initialize_app(cred)
        print("Firebase Admin SDK inizializzato con Service Account")
    else:
        # Se la chiave non è fornita, prova con Application Default Credentials (account locale).
        firebase_admin.initialize_app()
        print("Firebase Admin SDK inizializzato con ADC")
        
    # Call the cloud function to get all pending scans
    import requests
    from app.queue_manager import queue_manager
    
    link = 'https://get-all-pending-5ja5umnfkq-ey.a.run.app'
    try:
        response = requests.get(link)
        response.raise_for_status()
        pending_scans = response.json()
        print(f"Retrieved {len(pending_scans) if isinstance(pending_scans, list) else 'N/A'} pending scans")
        
        # Add all pending scans to the queue
        if isinstance(pending_scans, list):
            for scan in pending_scans:
                queue_manager.add_scan(scan)
            print(f"Added {len(pending_scans)} scans to the processing queue")
        
    except requests.exceptions.RequestException as req_error:
        print(f"Errore durante la chiamata alla Cloud Function: {req_error}")

except Exception as e:
    print(f"Errore durante l'inizializzazione di Firebase: {e}")

from app import routes