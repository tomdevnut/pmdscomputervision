from firebase_functions import https_fn
from firebase_admin import firestore, storage, auth
from config import BUCKET_NAME, SUPERUSER_ROLE_LEVEL

@https_fn.on_request()
def clean_scans(request: https_fn.Request) -> https_fn.Response:
    """
    HTTP Cloud Function per pulire tutti i file di scansione da Cloud Storage
    e le relative entry da Firestore (scans e stats).
    La funzione pulisce tutte le scansioni e tutte le statistiche
    Richiede l'autenticazione di un utente con un livello di autorizzazione sufficiente.
    Args:
        request (flask.Request): La richiesta HTTP per avviare la pulizia.
    """
    
    db = firestore.client()

    # Riferimenti alle collezioni Firestore
    # Collezione che associa scansioni agli utenti
    SCANS_COLLECTION_REF = db.collection('scans')
    # Collezione per le statistiche delle scansioni
    STATS_COLLECTION_REF = db.collection('stats')
    # Collezione per i ruoli degli utenti
    USERS_COLLECTION_REF = db.collection('users')

    # Autenticazione e Controllo Autorizzazione
    auth_header = request.headers.get('Authorization')
    if not auth_header or not auth_header.startswith('Bearer '):
        print("Richiesta non autorizzata.")
        return https_fn.Response('Unauthorized', status=401)

    id_token = auth_header.split('Bearer ')[1]
    try:
        # Verifica il token ID Firebase
        decoded_token = auth.verify_id_token(id_token)
        uid = decoded_token['uid']
        print(f"Utente {uid} ha richiesto la pulizia.")
    except Exception as e:
        print(f"Token ID non valido o scaduto: {e}")
        return https_fn.Response('Unauthorized', status=401)

    # Controllo del ruolo dell'utente
    user_is_authorized = False
    try:
        user_role_doc = USERS_COLLECTION_REF.document(uid).get()
        if user_role_doc.exists:
            user_role_data = user_role_doc.to_dict()
            if user_role_data.get('level', 0) >= SUPERUSER_ROLE_LEVEL and user_role_data.get('enabled', False):
                user_is_authorized = True
        else:
            return https_fn.Response('Forbidden', status=403)

    except Exception as e:
        print(f"Errore durante il recupero del ruolo utente: {e}")
        return https_fn.Response('Internal Server Error', status=500)

    if not user_is_authorized:
        return https_fn.Response('Forbidden', status=403)

    print(f"Utente {uid} autorizzato. Inizio la procedura di pulizia.")

    # Eliminazione dei file da Cloud Storage
    try:
        bucket = storage.bucket(BUCKET_NAME)
        deleted_files_count = 0

        # Pulisce la cartella "comparisons/"
        blobs_comparisons = bucket.list_blobs(prefix="comparisons/")
        for blob in blobs_comparisons:
            blob.delete()
            deleted_files_count += 1

        # Pulisce la cartella "scans/"
        blobs_scans = bucket.list_blobs(prefix="scans/")
        for blob in blobs_scans:
            blob.delete()
            deleted_files_count += 1
        print(f"Eliminati {deleted_files_count} file da Cloud Storage.")
    except Exception as e:
        print(f"Errore durante l'eliminazione dei file da Cloud Storage: {e}")
        return https_fn.Response(f"Errore durante la pulizia di Cloud Storage: {e}", status=500)

    # Pulizia della collezione 'scans' in Firestore
    try:
        docs = SCANS_COLLECTION_REF.stream()
        deleted_user_scans_count = 0
        for doc in docs:
            doc.reference.delete()
            deleted_user_scans_count += 1
        print(f"Eliminate {deleted_user_scans_count} entry dalla collezione 'scans'.")
    except Exception as e:
        print(f"Errore durante la pulizia di 'scans' in Firestore: {e}")
        return https_fn.Response(f"Errore durante la pulizia di Firestore (scans): {e}", status=500)

    # Pulizia della collezione 'stats' in Firestore
    try:
        docs = STATS_COLLECTION_REF.stream()
        deleted_stats_count = 0
        for doc in docs:
            doc.reference.delete()
            deleted_stats_count += 1
        print(f"Eliminate {deleted_stats_count} entry dalla collezione 'stats'.")
    except Exception as e:
        print(f"Errore durante la pulizia di 'stats' in Firestore: {e}")
        return https_fn.Response(f"Errore durante la pulizia di Firestore (stats): {e}", status=500)

    return https_fn.Response('Pulizia completata con successo!', status=200)