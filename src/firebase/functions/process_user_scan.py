from firebase_functions import storage_fn
from firebase_admin import firestore
import requests
import os
from datetime import timedelta
from google.cloud import secretmanager, storage as google_cloud_storage
from config import BUCKET_NAME, BACKEND_API_KEY_SECRET_NAME, BACKEND_SERVER_URL, SERVICE_ACCOUNT, PROJECT_ID
import json

# Funzione per recuperare il segreto
def get_secret(secret_name):
    if not PROJECT_ID:
        print("Errore: ID progetto GCP non trovato.")
        return None
    try:
        secret_client = secretmanager.SecretManagerServiceClient()
        name = f"projects/{PROJECT_ID}/secrets/{secret_name}/versions/latest"
        response = secret_client.access_secret_version(request={"name": name})
        return response.payload.data.decode("UTF-8")
    except Exception as e:
        print(f"Errore nel recupero del segreto '{secret_name}': {e}")
        return None

# Funzione per generare URL firmati usando una chiave privata
def generate_signed_url_with_key(bucket_name, file_path, private_key_secret, expiration_time):
    # Recupera la chiave privata dal Secret Manager
    private_key_json = get_secret(private_key_secret)
    if not private_key_json:
        raise ValueError("Chiave privata per la firma dell'URL non trovata.")

    # Converti la chiave da JSON a un dizionario Python
    credentials_info = json.loads(private_key_json)
    
    # Crea un client di Storage con le credenziali del servizio
    storage_client = google_cloud_storage.Client.from_service_account_info(credentials_info)
    bucket = storage_client.bucket(bucket_name)
    blob = bucket.blob(file_path)

    # Genera l'URL firmato
    signed_url = blob.generate_signed_url(
        version="v4",
        expiration=expiration_time,
        method="GET"
    )
    return signed_url

@storage_fn.on_object_finalized(bucket=BUCKET_NAME)
def process_user_scan(event: storage_fn.CloudEvent) -> None:
    db = firestore.client()
    scans_collection_ref = db.collection('scans')

    BACKEND_API_KEY = get_secret(BACKEND_API_KEY_SECRET_NAME)
    
    bucket_name = event.data.bucket
    file_path = event.data.name
    metadata = event.data.metadata or {}
    
    # URL del file di scansione
    if not file_path.startswith("scans/"):
        print(f"Il file {file_path} non è una scansione. Ignorato.")
        return
    
    scan_id = file_path.split("/")[-1].split(".")[0]
    user_id = metadata.get("user")
    step = metadata.get("step")
    name = metadata.get("scan_name")
    timestamp = event.data.time_created

    if not user_id or not step or not name or not timestamp:
        print("Errore: metadati essenziali mancanti.")
        return
    
    # Genera gli URL firmati usando la funzione helper
    try:
        scan_signed_url = generate_signed_url_with_key(
            bucket_name,
            file_path,
            SERVICE_ACCOUNT,
            timedelta(minutes=15)
        )
        step_signed_url = generate_signed_url_with_key(
            bucket_name,
            f"steps/{step}",
            SERVICE_ACCOUNT,
            timedelta(minutes=15)
        )
    except Exception as e:
        print(f"Errore nella generazione dell'URL firmato: {e}")
        return

    # Registrzione dell'associazione utente-scansione nel database Firestore
    try:
        scan_data = {
            "user": user_id,
            "status": 0,
            "step": step,
            "progress": 0,
            "name": name,
            "timestamp": timestamp
        }
        scans_collection_ref.document(scan_id).set(scan_data)
    except Exception as e:
        print(f"Errore durante la scrittura su Firestore: {e}")
        return
    
    # Notifica il server di backend
    if BACKEND_SERVER_URL:
        try:
            payload = {
                "user": user_id,
                "scan_id": scan_id,
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