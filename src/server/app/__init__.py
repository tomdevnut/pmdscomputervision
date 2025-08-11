from flask import Flask
import firebase_admin
from firebase_admin import credentials, firestore
import json
from config import Config

app = Flask(__name__)
app.config.from_object('config.Config')

try:
    # Carica le credenziali dal secret manager
    service_account_json = app.config['FIREBASE_SERVICE_ACCOUNT_KEY']
    if service_account_json:
        cred = credentials.Certificate(json.loads(service_account_json))
        firebase_admin.initialize_app(cred)
        db_firestore = firestore.client()
        print("Firebase Admin SDK initialized successfully.")
    else:
        print("Firebase service account key not found.")
except Exception as e:
    print(f"Error initializing Firebase Admin SDK: {e}")

# Importa le rotte dell'applicazione
from app import routes