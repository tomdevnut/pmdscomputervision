import functions_framework
from firebase_admin import firestore, initialize_app, auth

# Inizializzazione dell'SDK di Firebase Admin
initialize_app()
db = firestore.client()

# Riferimento alla collezione Firestore per i profili utente
USERS_COLLECTION_REF = db.collection('user')

@functions_framework.http
def save_fcm_token(request):
    """
    HTTP Cloud Function per salvare o aggiornare l'FCM token di un utente.
    L'utente deve essere autenticato per poter chiamare questa funzione.
    """

    # Verifico che l'utente sia autenticato
    auth_header = request.headers.get('Authorization')
    if not auth_header or not auth_header.startswith('Bearer '):
        return ('Unauthorized', 401)
    
    id_token = auth_header.split('Bearer ')[1]
    try:
        # Verifica il token ID Firebase
        decoded_token = auth.verify_id_token(id_token)
        user_uid = decoded_token['uid']
    except Exception as e:
        print(f"Token ID non valido o scaduto: {e}")
        return ('Unauthorized', 401)
    
    # Estraggo il token FCM dalla richiesta
    try:
        request_json = request.get_json(silent=True)
        fcm_token = request_json['fcm_token']

        if not fcm_token:
            raise ValueError("Il campo 'fcm_token' è mancante nel corpo della richiesta.")
    except ValueError as e:
        return (f'Bad Request: {e}', 400)
    
    # Salvo il token FCM nel documento dell'utente
    try:
        user_doc_ref = USERS_COLLECTION_REF.document(user_uid)
        # Usiamo 'merge=True' per aggiornare solo il campo fcm_token senza sovrascrivere altri dati
        user_doc_ref.set({'fcm_token': fcm_token}, merge=True)
    except Exception as e:
        print(f"Errore nel salvataggio del token in Firestore per l'utente {user_uid}: {e}")
        return ('Internal Server Error', 500)
    
    return (f'FCM token per l\'utente {user_uid} salvato con successo.', 200)