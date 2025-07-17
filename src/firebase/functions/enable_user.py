from firebase_functions import https_fn
from firebase_admin import initialize_app, firestore, auth
import json
import os

# Livello di autorizzazione minimo richiesto per abilitare altri utenti
REQUIRED_AUTH_LEVEL_TO_ENABLE_USERS = 2

@https_fn.on_request()
def enable_user(request: https_fn.Request) -> https_fn.Response:
    """
    HTTP Cloud Function per abilitare un utente esistente in Firebase Authentication
    e aggiornare il suo stato nel database Firestore.
    Richiede che l'utente che invoca la funzione abbia un livello di autorizzazione di 2.
    Args:
        request (flask.Request): La richiesta HTTP contenente i dati dell'utente da abilitare.
    """

    db = firestore.client()

    # Riferimenti alle collezioni Firestore
    USERS_COLLECTION_REF = db.collection('users')


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

    if caller_auth_level < REQUIRED_AUTH_LEVEL_TO_ENABLE_USERS:
        return https_fn.Response('Forbidden', status=403)

    # Parsing dei Dati della richiesta per l'utente target
    try:
        request_json = request.get_json(silent=True)
        if not request_json:
            raise ValueError("Corpo della richiesta JSON mancante o non valido.")

        target_uid = request_json.get('uid')

        # Validazione input
        if not target_uid:
            raise ValueError("Il campo 'uid' dell'utente da abilitare è obbligatorio.")

    except ValueError as e:
        return https_fn.Response(f'Bad Request: {e}', status=400)
    except Exception as e:
        return https_fn.Response('Bad Request: Formato JSON non valido.', status=400)

    # Abilitazione dell'Utente in Firebase Authentication (TODO: tenere o rimuovere?)
    try:
        auth.update_user(
            uid=target_uid,
            disabled=False
        )
    except auth.UserNotFoundError:
        return https_fn.Response('Not Found: Utente non trovato.', status=404)
    except Exception as e:
        return https_fn.Response(f'Internal Server Error: Errore nell\'abilitazione utente Auth: {e}', status=500)

    # Aggiornamento dello Stato nel Database Firestore
    try:
        USERS_COLLECTION_REF.document(target_uid).update({
            "enabled": True
        })

    except Exception as e:
        return https_fn.Response(f'Internal Server Error: Errore nell\'aggiornamento Firestore: {e}', status=500)

    return https_fn.Response(f'Utente {target_uid} abilitato con successo!', status=200)