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

# TODO: Definire la collezione Firestore per le scansioni e gli utenti (associazione utente-scansione)
scans_collection_ref = db.collection('user_scans')

# Percorso del segreto in Secret Manager
# TODO: Sostituire YOUR_PROJECT_ID con l'ID del progetto GCP
# TODO: Sostituire BACKEND_API_KEY_SECRET_NAME con il nome del segreto
BACKEND_API_KEY_SECRET_NAME = "BACKEND_API_KEY" # nome del segreto in Secret Manager
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

    # TODO: Estrarre l'ID utente dal percorso del file o dai metadati
    # Vedere dopo la configurazione se la struttura è corretta
    try:
        user_id = file_path.split('/')[1]
        if not user_id:
            raise ValueError("Impossibile estrarre l'ID utente dal percorso del file.")
    except (IndexError, ValueError) as e:
        print(f"Errore nell'estrazione dell'ID utente dal percorso '{file_path}': {e}")
        return

    blob = storage.bucket(bucket_name).blob(file_path)
    signed_url = blob.generate_signed_url(expiration=timedelta(minutes=15), method='GET')

    # Registrzione dell'associazione utente-scansione nel database Firestore (rifinire dopo aver definito la struttura)
    try:
        scan_data = {
            "userId": user_id,
            "scanPath": file_path,
            "scanUrl": signed_url,
            "timestamp": firestore.SERVER_TIMESTAMP
        }
        # TODO: Sostituire con la collezione Firestore
        doc_ref = scans_collection_ref.add(scan_data)
    except Exception as e:
        print(f"Errore durante la scrittura su Firestore: {e}")
        return

    # Notifica il server di backend
    # TODO: Implementare la comunicazione con il server di backend
    # Esempio:
    if BACKEND_SERVER_URL:
        try:
            payload = {
                "userId": user_id,
                "scanFirebaseUrl": signed_url,
                "scanId": doc_ref.id
            }
            headers = {"Content-Type": "application/json"}
            if BACKEND_API_KEY:
                headers["Authorization"] = f"Bearer {BACKEND_API_KEY}"

            response = requests.post(BACKEND_SERVER_URL, json=payload, headers=headers)
            response.raise_for_status()
        except requests.exceptions.RequestException as e:
            print(f"Errore durante la notifica al server di backend: {e}")