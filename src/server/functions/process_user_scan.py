import functions_framework
from firebase_admin import initialize_app, firestore, storage
import requests
import os
from datetime import timedelta
from google.cloud import secretmanager

# Inizializza l'SDK di Firebase Admin
initialize_app()
db = firestore.client()

# Inizializzazione secret manager per la gestione dei segreti
secret_client = secretmanager.SecretManagerServiceClient()

# Riferimenti alle collezioni Firestore con associazione scansioni e utenti
scans_collection_ref = db.collection('scans')

# Percorso del segreto in Secret Manager
BACKEND_API_KEY_SECRET_NAME = "api-key-backend" # nome del segreto in Secret Manager
PROJECT_ID = os.environ.get("GCP_PROJECT") # L'ID del progetto viene fornito dalle Cloud Functions

# TODO: Definire l'URL del server di backend
BACKEND_SERVER_URL = "https://server.com/api/scans"

# Funzione per recuperare il segreto
def get_secret(secret_name):
    if not PROJECT_ID:
        print("Errore: ID progetto GCP non trovato.")
        return None
    try:
        name = f"projects/{PROJECT_ID}/secrets/{secret_name}/versions/latest"
        response = secret_client.access_secret_version(request={"name": name})
        return response.payload.data.decode("UTF-8")
    except Exception as e:
        print(f"Errore nel recupero del segreto '{secret_name}': {e}")
        return None

# Recupero la chiave API del backend dal Secret Manager
BACKEND_API_KEY = get_secret(BACKEND_API_KEY_SECRET_NAME)

@functions_framework.cloud_event
def process_user_scan(cloud_event):
    """
    Triggered by a new file upload to Cloud Storage.
    Processes the uploaded scan, associates it with the user, and notifies the backend.
    """
    data = cloud_event.data
    bucket_name = data["bucket"]
    file_path = data["name"] 

    # Ottenere l'ID utente e lo step dal metadata del file
    user_id = data.get("metadata", {}).get("user_id")
    step = data.get("metadata", {}).get("step")

    blob = storage.bucket(bucket_name).blob(file_path)
    scan_signed_url = blob.generate_signed_url(expiration=timedelta(minutes=15), method='GET')
    blob = storage.bucket(bucket_name).blob(f"steps/{step}")
    step_signed_url = blob.generate_signed_url(expiration=timedelta(minutes=15), method='GET')

    # Registrzione dell'associazione utente-scansione nel database Firestore
    try:
        scan_data = {
            "user": user_id,
            "scan_path": file_path,
            "status": 0,
            "step": step,
            "progress": 0
        }
        doc_ref = scans_collection_ref.add(scan_data)
    except Exception as e:
        print(f"Errore durante la scrittura su Firestore: {e}")
        return

    # Notifica il server di backend
    # TODO: Implementare la comunicazione con il server di backend
    if BACKEND_SERVER_URL:
        try:
            payload = {
                "user": user_id,
                "scan_id": doc_ref.id,
                "scan_url": scan_signed_url,
                "step_url": step_signed_url
            }
            headers = {"Content-Type": "application/json"}
            if BACKEND_API_KEY:
                headers["Authorization"] = f"Bearer {BACKEND_API_KEY}"

            response = requests.post(BACKEND_SERVER_URL, json=payload, headers=headers)
            response.raise_for_status()
        except requests.exceptions.RequestException as e:
            print(f"Errore durante la notifica al server di backend: {e}")