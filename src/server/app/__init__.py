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

except Exception as e:
    print(f"Errore durante l'inizializzazione di Firebase: {e}")

from app import routes