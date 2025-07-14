import functions_framework
from firebase_admin import initialize_app, firestore, auth
import json
import os

# Inizializzazione dell'SDK di Firebase Admin
initialize_app()
db = firestore.client()

# Riferimenti alle collezioni Firestore
USERS_COLLECTION_REF = db.collection('users')

# Livello di autorizzazione minimo richiesto per disabilitare altri utenti
REQUIRED_AUTH_LEVEL_TO_DISABLE_USERS = 2

@functions_framework.http
def disable_user(request):
    """
    HTTP Cloud Function per disabilitare un utente esistente in Firebase Authentication
    e aggiornare il suo stato nel database Firestore.
    Richiede che l'utente che invoca la funzione abbia un livello di autorizzazione di 2.
    Un utente di livello 2 non può essere disabilitato.
    Args:
        request (flask.Request): La richiesta HTTP contenente i dati dell'utente da disabilitare.
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
            caller_auth_level = caller_role_data.get('level', -1)
        else:
            return ('Forbidden', 403)
    except Exception as e:
        return ('Internal Server Error', 500)

    if caller_auth_level < REQUIRED_AUTH_LEVEL_TO_DISABLE_USERS:
        return ('Forbidden', 403)

    # Parsing dei Dati della Richiesta per l'utente target
    try:
        request_json = request.get_json(silent=True)
        if not request_json:
            raise ValueError("Corpo della richiesta JSON mancante o non valido.")

        target_uid = request_json.get('uid')

        # Validazione input
        if not target_uid:
            raise ValueError("Il campo 'uid' dell'utente da disabilitare è obbligatorio.")

    except ValueError as e:
        return (f'Bad Request: {e}', 400)
    except Exception as e:
        return ('Bad Request: Formato JSON non valido.', 400)

    # Controllo Autorizzazione Utente Target (non può essere di livello 2)
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

    if target_user_auth_level == REQUIRED_AUTH_LEVEL_TO_DISABLE_USERS:
        return ('Forbidden: Non è possibile disabilitare un utente di livello 2.', 403)

    # Disabilitazione dell'Utente in Firebase Authentication (TODO: tenere o rimuovere?)
    try:
        auth.update_user(
            uid=target_uid,
            disabled=True
        )
    except auth.UserNotFoundError:
        return ('Not Found: Utente non trovato.', 404)
    except Exception as e:
        return (f'Internal Server Error: Errore nella disabilitazione utente Auth: {e}', 500)

    # Aggiornamento dello Stato nel Database Firestore
    try:
        USERS_COLLECTION_REF.document(target_uid).update({
            "enabled": False
        })

    except Exception as e:
        return (f'Internal Server Error: Errore nell\'aggiornamento Firestore: {e}', 500)

    return (f'Utente {target_uid} disabilitato con successo!', 200)