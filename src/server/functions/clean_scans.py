import functions_framework
from firebase_admin import initialize_app, firestore, storage, auth
import requests
import os
from datetime import timedelta
from google.cloud import secretmanager

# Inizializzazione dell'SDK di Firebase Admin
initialize_app()
db = firestore.client()

# Inizializzazione Secret Manager
secret_client = secretmanager.SecretManagerServiceClient()

# Riferimenti alle collezioni Firestore
# TODO: Definire la collezione Firestore per le scansioni e gli utenti (associazione utente-scansione)
SCANS_COLLECTION_REF = db.collection('user_scans')
# TODO: Definire la collezione Firestore per le statistiche delle scansioni
STATS_COLLECTION_REF = db.collection('scan_stats')
# TODO: Definire la collezione Firestore per i gradi di autorizzazione degli utenti
USERS_ROLES_COLLECTION_REF = db.collection('user_roles')

# Nome del bucket di Cloud Storage dove sono salvate le scansioni
# TODO: Sostituire con il nome effettivo del bucket
SCANS_BUCKET_NAME = "qualcosa.qualcosaltro.com"


# TODO: Definire il ruolo minimo richiesto per eseguire la pulizia
ADMIN_ROLE = "admin"
SUPERUSER_ROLE_LEVEL = 10

@functions_framework.http
def clean_scans(request):
    """
    HTTP Cloud Function per pulire tutti i file di scansione da Cloud Storage
    e le relative entry da Firestore (user_scans e scan_stats).
    Richiede l'autenticazione di un utente con un livello di autorizzazione sufficiente.
    """
    # Autenticazione e Controllo Autorizzazione
    auth_header = request.headers.get('Authorization')
    if not auth_header or not auth_header.startswith('Bearer '):
        print("Richiesta non autorizzata.")
        return ('Unauthorized', 401)

    id_token = auth_header.split('Bearer ')[1]
    try:
        # Verifica il token ID Firebase
        decoded_token = auth.verify_id_token(id_token)
        uid = decoded_token['uid']
        print(f"Utente {uid} ha richiesto la pulizia.")
    except Exception as e:
        print(f"Token ID non valido o scaduto: {e}")
        return ('Unauthorized', 401)

    # TODO: Implementare il controllo del grado di autorizzazione dell'utente dal database
    user_is_authorized = False
    try:
        user_role_doc = USERS_ROLES_COLLECTION_REF.document(uid).get()
        if user_role_doc.exists:
            user_role_data = user_role_doc.to_dict()
            if user_role_data.get('role') == ADMIN_ROLE or user_role_data.get('level', 0) >= SUPERUSER_ROLE_LEVEL:
                user_is_authorized = True
        else:
            print(f"Nessun ruolo trovato per l'utente {uid}.")
            return ('Forbidden', 403)

    except Exception as e:
        print(f"Errore durante il recupero del ruolo utente: {e}")
        return ('Internal Server Error', 500)

    if not user_is_authorized:
        print(f"Utente {uid} non autorizzato a eseguire la pulizia.")
        return ('Forbidden', 403)

    print(f"Utente {uid} autorizzato. Inizio la procedura di pulizia.")

    # Eliminazione dei file da Cloud Storage
    try:
        bucket = storage.bucket(SCANS_BUCKET_NAME)
        blobs = bucket.list_blobs()
        deleted_files_count = 0
        for blob in blobs:
            blob.delete()
            deleted_files_count += 1
        print(f"Eliminati {deleted_files_count} file da Cloud Storage.")
    except Exception as e:
        print(f"Errore durante l'eliminazione dei file da Cloud Storage: {e}")
        return (f"Errore durante la pulizia di Cloud Storage: {e}", 500)

    # Pulizia della collezione 'user_scans' in Firestore
    try:
        docs = SCANS_COLLECTION_REF.stream()
        deleted_user_scans_count = 0
        for doc in docs:
            doc.reference.delete()
            deleted_user_scans_count += 1
        print(f"Eliminate {deleted_user_scans_count} entry dalla collezione 'user_scans'.")
    except Exception as e:
        print(f"Errore durante la pulizia di 'user_scans' in Firestore: {e}")
        return (f"Errore durante la pulizia di Firestore (user_scans): {e}", 500)

    # Pulizia della collezione 'scan_stats' in Firestore
    try:
        docs = STATS_COLLECTION_REF.stream()
        deleted_stats_count = 0
        for doc in docs:
            doc.reference.delete()
            deleted_stats_count += 1
        print(f"Eliminate {deleted_stats_count} entry dalla collezione 'scan_stats'.")
    except Exception as e:
        print(f"Errore durante la pulizia di 'scan_stats' in Firestore: {e}")
        return (f"Errore durante la pulizia di Firestore (scan_stats): {e}", 500)

    return ('Pulizia completata con successo!', 200)