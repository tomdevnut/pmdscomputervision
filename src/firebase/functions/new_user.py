from firebase_functions import https_fn
from firebase_admin import firestore, auth
from config import MANAGE_USERS_MIN_LEVEL
from _user_utils import create_user_in_firebase

@https_fn.on_request()
def new_user(request: https_fn.Request) -> https_fn.Response:
    """
    HTTP Cloud Function per creare nuovi utenti in Firebase Authentication
    e salvare i loro dettagli in Firestore.
    Richiede che l'utente che invoca la funzione abbia un livello di autorizzazione pari a 2.
    Args:
        request (flask.Request): La richiesta HTTP contenente i dati del nuovo utente.
    """

    db = firestore.client()

    # Riferimenti alle collezioni Firestore
    USERS_PROFILES_COLLECTION_REF = db.collection('users')


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
        caller_role_doc = USERS_PROFILES_COLLECTION_REF.document(caller_uid).get()
        if caller_role_doc.exists:
            caller_role_data = caller_role_doc.to_dict()
            caller_auth_level = caller_role_data.get('level', -1)
        else:
            return https_fn.Response('Forbidden', status=403)
    except Exception as e:
        print(f"Errore durante il recupero del ruolo del chiamante: {e}")
        return https_fn.Response('Internal Server Error', status=500)

    if caller_auth_level < MANAGE_USERS_MIN_LEVEL:
        print(f"Utente {caller_uid} (livello {caller_auth_level}) non autorizzato a creare nuovi utenti. Richiesto livello {MANAGE_USERS_MIN_LEVEL}.")
        return https_fn.Response('Forbidden', status=403)

    # Parsing dei Dati della Richiesta per il nuovo utente
    try:
        request_json = request.get_json(silent=True)
        if not request_json:
            raise ValueError("Corpo della richiesta JSON mancante o non valido.")

        email = request_json.get('email')
        password = request_json.get('password')
        level = request_json.get('level')
        name = request_json.get('name')
        surname = request_json.get('surname')

        # Validazione input
        if not all([email, password, level is not None, name, surname]):
            raise ValueError("Campi 'email', 'password', 'level', 'name', 'surname' sono tutti obbligatori.")
        if not isinstance(level, int) or level not in [0, 1]:
            raise ValueError("Il livello di autorizzazione deve essere 0 o 1.")

    except ValueError as e:
        print(f"Errore di validazione input: {e}")
        return https_fn.Response(f'Bad Request: {e}', status=400)
    except Exception as e:
        print(f"Errore nel parsing della richiesta JSON: {e}")
        return https_fn.Response('Bad Request: Formato JSON non valido.', status=400)

    # Creazione del nuovo utente usando la funzione helper
    try:
        user_record = create_user_in_firebase(db, email, password, level, name, surname)
        new_user_uid = user_record.uid
    except auth.EmailAlreadyExistsError:
        print(f"Errore: L'email {email} esiste già.")
        return https_fn.Response('Conflict: Email già registrata.', status=409)
    except Exception as e:
        print(f"Errore nella creazione dell'utente: {e}")
        return https_fn.Response(f'Internal Server Error: {e}', status=500)

    return https_fn.Response(f'Utente {email} (UID: {new_user_uid}) creato e dettagli salvati con successo!', status=200)