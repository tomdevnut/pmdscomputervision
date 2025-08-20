from firebase_functions import https_fn
from firebase_admin import firestore, auth, storage
from config import BUCKET_NAME, MANAGE_USERS_MIN_LEVEL


@https_fn.on_request()
def delete_user(request: https_fn.Request) -> https_fn.Response:
    """
    HTTP Cloud Function per eliminare un utente esistente da Firebase Authentication
    e tutti i suoi dati associati (scansioni, statistiche, profili, steps) da Cloud Storage e Firestore.
    Richiede che l'utente che invoca la funzione abbia un livello di autorizzazione di 2.
    Un utente di livello 2 non può essere eliminato.
    Args:
        request (flask.Request): La richiesta HTTP contenente i dati dell'utente da eliminare.
    """

    db = firestore.client()

    # Riferimenti alle collezioni Firestore
    USERS_COLLECTION_REF = db.collection('users')
    SCANS_COLLECTION_REF = db.collection('scans')
    STATS_COLLECTION_REF = db.collection('stats')
    STEPS_COLLECTION_REF = db.collection('steps')

    bucket = storage.bucket(BUCKET_NAME)


    # Autenticazione e Controllo Autorizzazione del Chiamante
    auth_header = request.headers.get('Authorization')
    if not auth_header or not auth_header.startswith('Bearer '):
        return https_fn.Response('Unauthorized', status=401)

    id_token = auth_header.split('Bearer ')[1]
    try:
        # Verifica il token ID Firebase del chiamante
        decoded_token = auth.verify_id_token(id_token)
        caller_uid = decoded_token['uid']
    except Exception as e:
        return https_fn.Response('Unauthorized', status=401)

    # Recupera il livello di autorizzazione del chiamante da Firestore
    caller_auth_level = -1 # Valore predefinito per utenti non trovati o non autorizzati
    try:
        caller_role_doc = USERS_COLLECTION_REF.document(caller_uid).get()
        if caller_role_doc.exists:
            caller_role_data = caller_role_doc.to_dict()
            caller_auth_level = caller_role_data.get('level', -1)
        else:
            return https_fn.Response('Forbidden', status=403)
    except Exception as e:
        return https_fn.Response('Internal Server Error', status=500)

    if caller_auth_level < MANAGE_USERS_MIN_LEVEL:
        return https_fn.Response('Forbidden', status=403)

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
        return https_fn.Response(f'Bad Request: {e}', status=400)
    except Exception as e:
        print(f"Errore nel parsing della richiesta JSON: {e}")
        return https_fn.Response('Bad Request: Formato JSON non valido.', status=400)

    # Controllo Autorizzazione Utente Target (non può essere di livello 2 e non può eliminare se stesso)
    if target_uid == caller_uid:
        print(f"Tentativo di eliminare l'utente stesso ({target_uid}). Operazione non consentita.")
        return https_fn.Response('Forbidden: Non è possibile eliminare se stessi.', status=403)

    target_user_auth_level = -1
    try:
        target_role_doc = USERS_COLLECTION_REF.document(target_uid).get()
        if target_role_doc.exists:
            target_role_data = target_role_doc.to_dict()
            target_user_auth_level = target_role_data.get('level', -1)
        else:
            return https_fn.Response('Not Found: Utente non trovato.', status=404)
    except Exception as e:
        return https_fn.Response('Internal Server Error', status=500)

    if target_user_auth_level == MANAGE_USERS_MIN_LEVEL:
        return https_fn.Response('Forbidden: Non è possibile eliminare un utente di livello 2.', status=403)

    # Eliminazione dell'Utente da Firebase Authentication
    try:
        auth.delete_user(target_uid)
    except auth.UserNotFoundError:
        print(f"Utente {target_uid} non trovato in Firebase Authentication. Potrebbe essere già stato eliminato.")
        # Non è un errore critico se l'utente non esiste già in Authentication, ma i dati associati potrebbero esistere
    except Exception as e:
        return https_fn.Response(f'Internal Server Error: Errore nell\'eliminazione utente Auth: {e}', status=500)

    # Pulizia dei Dati Associati (Cloud Storage e Firestore)
    
    # Eliminazione dei file di scansione da Cloud Storage
    try:
        docs_to_delete_scans = SCANS_COLLECTION_REF.where('user', '==', target_uid).stream()
        
        for doc in docs_to_delete_scans:
            scan_data = doc.to_dict()
            scan_id = doc.id
            
            # Cancella i file su Cloud Storage
            # TODO: definire il corretto formato del file
            try:
                blob = bucket.blob(f'scans/{scan_id}.obj')
                if blob.exists():
                    blob.delete()
            except Exception as e:
                print(f"Errore durante l'eliminazione del file {scan_id} da Cloud Storage: {e}")

            # Cancella le statistiche associate a questa scansione da Cloud Storage
            # TODO: definire il corretto formato del file
            try:
                blob = bucket.blob(f'stats/{scan_id}.json')
                if blob.exists():
                    blob.delete()
            except Exception as e:
                print(f"Errore durante l'eliminazione delle statistiche per la scansione {scan_id}: {e}")

            # Cancella le statistiche associate a questa scansione da Firestore
            try:
                stat_docs = STATS_COLLECTION_REF.where('scan', '==', scan_id).stream()
                # dovrebbe esserci una sola statistica per scansione, ma per precauzione uso un for
                for stat_doc in stat_docs: 
                    stat_doc.reference.delete()
            except Exception as e:
                print(f"Errore durante l'eliminazione delle statistiche per la scansione {scan_id}: {e}")

            # Cancella la scansione stessa da Firestore
            doc.reference.delete()
        
    except Exception as e:
        return https_fn.Response(f"Errore durante la pulizia di Cloud Storage: {e}", status=500)

    # Pulizia della collezione 'steps' in Firestore (solo se l'utente è di livello 1)
    try:
        if target_user_auth_level == 1:
            steps_docs_to_delete = STEPS_COLLECTION_REF.where('user', '==', target_uid).stream()
            for step_doc in steps_docs_to_delete:
                # Cancella i file associati a questo step
                # TODO: definire il corretto formato del file
                blob = storage.bucket(BUCKET).blob(f'steps/{step_doc.id}.obj')
                if blob.exists():
                    blob.delete()
                step_doc.reference.delete()
    except Exception as e:
        return https_fn.Response(f"Errore durante la pulizia della collezione 'steps': {e}", status=500)

    # Pulizia del documento del profilo utente in Firestore
    try:
        USERS_COLLECTION_REF.document(target_uid).delete()
    except Exception as e:
        return https_fn.Response(f'Internal Server Error: Errore nell\'eliminazione del profilo utente in Firestore: {e}', status=500)

    # Aggiungi questa riga per restituire una risposta di successo
    return https_fn.Response(f"Utente {target_uid} eliminato con successo.", status=200)