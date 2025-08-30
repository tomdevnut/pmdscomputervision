from firebase_functions import https_fn
from firebase_admin import auth, firestore, messaging
from config import MANAGE_USERS_MIN_LEVEL

@https_fn.on_request()
def change_password(request: https_fn.Request) -> https_fn.Response:
    """
    Modifica la password di un utente, revoca le sessioni e notifica.
    Viene invocata solamente dagli amministratori per modificare la password di altri utenti
    """
    db = firestore.client()
    USERS_COLLECTION_REF = db.collection('users')

    # Autenticazione del chiamante
    try:
        auth_header = request.headers.get('Authorization')
        if not auth_header or not auth_header.startswith('Bearer '):
            return https_fn.Response('Unauthorized', status=401)
        id_token = auth_header.split('Bearer ')[1]
        decoded_token = auth.verify_id_token(id_token)
        caller_uid = decoded_token['uid']
    except Exception:
        return https_fn.Response('Unauthorized', status=401)

    # Parsing dei dati
    try:
        data = request.get_json()
        new_password = data.get('new_password')
        target_email = data.get('email')
    except Exception as e:
        return https_fn.Response(f'Bad Request: {e}', status=400)

    # Logica di modifica
    try:
        uid_to_update = caller_uid
        admin_action = False

        # Admin modifica la password di un altro utente
        caller_doc = USERS_COLLECTION_REF.document(caller_uid).get()
        if not caller_doc.exists or caller_doc.to_dict().get('level') < MANAGE_USERS_MIN_LEVEL:
            return https_fn.Response('Forbidden: Non hai i permessi per modificare la password di altri utenti.', status=403)
        
        try:
            target_user_record = auth.get_user_by_email(target_email)
            uid_to_update = target_user_record.uid
        except auth.UserNotFoundError:
            return https_fn.Response(f"Utente con email '{target_email}' non trovato.", status=404)

        # Aggiorna la password in Firebase Auth
        auth.update_user(uid_to_update, password=new_password)

        # Revoca i token di aggiornamento per forzare il logout su tutti i dispositivi
        auth.revoke_refresh_tokens(uid_to_update)

        # Invia notifica PUSH per notificare il logout forzato all'utente a cui è stata cambiata la password
        if admin_action:
            target_doc = USERS_COLLECTION_REF.document(uid_to_update).get()
            if target_doc.exists:
                fcm_token = target_doc.to_dict().get("fcm_token")
                message = messaging.Message(
                    notification=messaging.Notification(
                        title="Sessione terminata",
                        body=f"La tua password è stata modificata da un amministratore. Esegui nuovamente l'accesso."
                    ),
                    token=fcm_token
                )
                try:
                    messaging.send(message)
                except Exception as e:
                    print(f"Errore durante l'invio della notifica FCM a {uid_to_update}: {e}")


        return https_fn.Response('Password aggiornata e sessioni revocate con successo.', status=200)

    except Exception as e:
        print(f"Errore durante la modifica della password: {e}")
        return https_fn.Response(f'Internal Server Error: {e}', status=500)