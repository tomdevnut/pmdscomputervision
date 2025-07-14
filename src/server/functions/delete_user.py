import functions_framework
from firebase_admin import initialize_app, firestore, auth, storage
import json
import os

# Inizializza l'SDK di Firebase Admin
initialize_app()
db = firestore.client()

# Riferimenti alle collezioni Firestore
USERS_COLLECTION_REF = db.collection('users')
SCANS_COLLECTION_REF = db.collection('scans')
STATS_COLLECTION_REF = db.collection('stats')
STEPS_COLLECTION_REF = db.collection('steps')

# Nome del bucket di Cloud Storage dove sono salvate le scansioni
BUCKET = "pmds-project.appspot.com"

# Livello di autorizzazione minimo richiesto per eliminare altri utenti
REQUIRED_AUTH_LEVEL_TO_DELETE_USERS = 2

@functions_framework.http
def delete_user(request):
    """
    HTTP Cloud Function per eliminare un utente esistente da Firebase Authentication
    e tutti i suoi dati associati (scansioni, statistiche, profili, steps) da Cloud Storage e Firestore.
    Richiede che l'utente che invoca la funzione abbia un livello di autorizzazione di 2.
    Un utente di livello 2 non può essere eliminato.
    Args:
        request (flask.Request): La richiesta HTTP contenente i dati dell'utente da eliminare.
    """
    # Autenticazione e Controllo Autorizzazione del Chiamante
    auth_header = request.headers.get('Authorization')
    if not auth_header or not auth_header.startswith('Bearer '):
        return ('Unauthorized', 401)

    id_token = auth_header.split('Bearer ')[1]
    try:
        # Verifica il token ID Firebase del chiamante
        decoded_token = auth.verify_id_token(id_token)
        caller_uid = decoded_token['uid']
    except Exception as e:
        return ('Unauthorized', 401)

    # Recupera il livello di autorizzazione del chiamante da Firestore
    caller_auth_level = -1 # Valore predefinito per utenti non trovati o non autorizzati
    try:
        caller_role_doc = USERS_COLLECTION_REF.document(caller_uid).get()
        if caller_role_doc.exists:
            caller_role_data = caller_role_doc.to_dict()
            caller_auth_level = caller_role_data.get('authorization_level', -1)
        else:
            return ('Forbidden', 403)
    except Exception as e:
        return ('Internal Server Error', 500)

    if caller_auth_level < REQUIRED_AUTH_LEVEL_TO_DELETE_USERS:
        return ('Forbidden', 403)

    # Parsing dei Dati della Richiesta per l'Utente Target
    try:
        request_json = request.get_json(silent=True)
        if not request_json:
            raise ValueError("Corpo della richiesta JSON mancante o non valido.")

        target_uid = request_json.get('uid')

        # Validazione input
        if not target_uid:
            raise ValueError("Il campo 'uid' dell'utente da eliminare è obbligatorio.")

    except ValueError as e:
        print(f"Errore di validazione input: {e}")
        return (f'Bad Request: {e}', 400)
    except Exception as e:
        print(f"Errore nel parsing della richiesta JSON: {e}")
        return ('Bad Request: Formato JSON non valido.', 400)

    # Controllo Autorizzazione Utente Target (non può essere di livello 2 e non può eliminare se stesso)
    if target_uid == caller_uid:
        print(f"Tentativo di eliminare l'utente stesso ({target_uid}). Operazione non consentita.")
        return ('Forbidden: Non è possibile eliminare se stessi.', 403)

    target_user_auth_level = -1
    try:
        target_role_doc = USERS_COLLECTION_REF.document(target_uid).get()
        if target_role_doc.exists:
            target_role_data = target_role_doc.to_dict()
            target_user_auth_level = target_role_data.get('authorization_level', -1)
        else:
            return ('Not Found: Utente non trovato.', 404)
    except Exception as e:
        return ('Internal Server Error', 500)

    if target_user_auth_level == REQUIRED_AUTH_LEVEL_TO_DELETE_USERS:
        return ('Forbidden: Non è possibile eliminare un utente di livello 2.', 403)

    # Eliminazione dell'Utente da Firebase Authentication
    try:
        auth.delete_user(target_uid)
    except auth.UserNotFoundError:
        print(f"Utente {target_uid} non trovato in Firebase Auth. Potrebbe essere già stato eliminato.")
        # Non è un errore critico se l'utente non esiste già in Auth, ma i dati associati potrebbero esistere
    except Exception as e:
        return (f'Internal Server Error: Errore nell\'eliminazione utente Auth: {e}', 500)

    # Pulizia dei Dati Associati (Cloud Storage e Firestore)
    
    # Eliminazione dei file di scansione da Cloud Storage
    try:
        bucket = storage.bucket(BUCKET)
        docs_to_delete_scans = SCANS_COLLECTION_REF.where('user', '==', target_uid).stream()
        
        for doc in docs_to_delete_scans:
            scan_data = doc.to_dict()
            scan_path = scan_data.get('scan_path')
            scan_id = doc.id
            
            # Cancella i file su Cloud Storage
            if scan_path:
                try:
                    blob = bucket.blob(scan_path)
                    if blob.exists():
                        blob.delete()
                except Exception as e:
                    print(f"Errore durante l'eliminazione del file {scan_path} da Cloud Storage: {e}")
            
            # Cancella le statistiche associate a questa scansione
            try:
                # Query per eliminare le statistiche associate a questa scansione
                stats_docs_to_delete = STATS_COLLECTION_REF.where('scan', '==', scan_id).stream()
                for stat_doc in stats_docs_to_delete:
                    blob = bucket.blob(stat_doc.to_dict().get('out_path'))
                    if blob.exists():
                        blob.delete()
                    stat_doc.reference.delete()
            except Exception as e:
                print(f"Errore durante l'eliminazione delle statistiche per la scansione {scan_id}: {e}")

            # Cancella la scansione stessa
            doc.reference.delete()
        
    except Exception as e:
        return (f"Errore durante la pulizia di Cloud Storage: {e}", 500)
   
    # Pulizia della collezione 'steps' in Firestore (solo se l'utente è di livello 1)
    try:
        if target_user_auth_level == 1:
            steps_docs_to_delete = STEPS_COLLECTION_REF.where('user', '==', target_uid).stream()
            for step_doc in steps_docs_to_delete:
                # Cancella i file associati a questo step
                blob = storage.bucket(BUCKET).blob(step_doc.to_dict().get('step_path'))
                if blob.exists():
                    blob.delete()
                step_doc.reference.delete()
    except Exception as e:
        return (f"Errore durante la pulizia della collezione 'steps': {e}", 500)

    # Pulizia del documento del profilo utente in Firestore
    try:
        USERS_COLLECTION_REF.document(target_uid).delete()
    except Exception as e:
        return (f'Internal Server Error: Errore nell\'eliminazione del profilo utente in Firestore: {e}', 500)