from firebase_functions import https_fn
from firebase_admin import firestore, initialize_app, auth

@https_fn.on_request()
def save_fcm_token(request: https_fn.Request) -> https_fn.Response:
    """
    HTTP Cloud Function per salvare o aggiornare l'FCM token di un utente.
    L'utente deve essere autenticato per poter chiamare questa funzione.
    """
    db = firestore.client()

    # Riferimento alla collezione Firestore per i profili utente
    USERS_COLLECTION_REF = db.collection('users')

    # Verifico che l'utente sia autenticato
    auth_header = request.headers.get('Authorization')
    if not auth_header or not auth_header.startswith('Bearer '):
        return https_fn.Response('Unauthorized', status=401)
    
    id_token = auth_header.split('Bearer ')[1]
    try:
        # Verifica il token ID Firebase
        decoded_token = auth.verify_id_token(id_token)
        user_uid = decoded_token['uid']
    except Exception as e:
        print(f"Token ID non valido o scaduto: {e}")
        return https_fn.Response('Unauthorized', status=401)
    
    # Estraggo il token FCM dalla richiesta
    try:
        request_json = request.get_json(silent=True)
        fcm_token = request_json['fcm_token']

        if not fcm_token:
            raise ValueError("Il campo 'fcm_token' è mancante nel corpo della richiesta.")
    except ValueError as e:
        return https_fn.Response(f'Bad Request: {e}', status=400)
    
    # Salvo il token FCM nel documento dell'utente
    try:
        user_doc_ref = USERS_COLLECTION_REF.document(user_uid)
        # Usiamo 'merge=True' per aggiornare solo il campo fcm_token senza sovrascrivere altri dati
        user_doc_ref.set({'fcm_token': fcm_token}, merge=True)
    except Exception as e:
        print(f"Errore nel salvataggio del token in Firestore per l'utente {user_uid}: {e}")
        return https_fn.Response('Internal Server Error', status=500)
    
    return https_fn.Response(f'FCM token per l\'utente {user_uid} salvato con successo.', status=200)