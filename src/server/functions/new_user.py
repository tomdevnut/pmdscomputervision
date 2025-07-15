import functions_framework
from firebase_admin import initialize_app, firestore, auth
import json
import os

# Inizializzazione dell'SDK di Firebase Admin
initialize_app()
db = firestore.client()

# Riferimenti alle collezioni Firestore
USERS_PROFILES_COLLECTION_REF = db.collection('users')

# Livello di autorizzazione minimo richiesto per creare nuovi utenti
REQUIRED_AUTH_LEVEL_TO_CREATE_USERS = 2

@functions_framework.http
def create_new_user(request):
    """
    HTTP Cloud Function per creare nuovi utenti in Firebase Authentication
    e salvare i loro dettagli in Firestore.
    Richiede che l'utente che invoca la funzione abbia un livello di autorizzazione pari a 2.
    Args:
        request (flask.Request): La richiesta HTTP contenente i dati del nuovo utente.
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
        caller_role_doc = USERS_PROFILES_COLLECTION_REF.document(caller_uid).get()
        if caller_role_doc.exists:
            caller_role_data = caller_role_doc.to_dict()
            caller_auth_level = caller_role_data.get('level', -1)
        else:
            return ('Forbidden', 403)
    except Exception as e:
        print(f"Errore durante il recupero del ruolo del chiamante: {e}")
        return ('Internal Server Error', 500)

    if caller_auth_level < REQUIRED_AUTH_LEVEL_TO_CREATE_USERS:
        print(f"Utente {caller_uid} (livello {caller_auth_level}) non autorizzato a creare nuovi utenti. Richiesto livello {REQUIRED_AUTH_LEVEL_TO_CREATE_USERS}.")
        return ('Forbidden', 403)

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
        return (f'Bad Request: {e}', 400)
    except Exception as e:
        print(f"Errore nel parsing della richiesta JSON: {e}")
        return ('Bad Request: Formato JSON non valido.', 400)

    # Creazione del nuovo utente in Firebase Authentication
    try:
        user_record = auth.create_user(
            email=email,
            password=password,
            email_verified=True
        )
        new_user_uid = user_record.uid
    except auth.EmailAlreadyExistsError:
        print(f"Errore: L'email {email} esiste già.")
        return ('Conflict: Email già registrata.', 409)
    except Exception as e:
        print(f"Errore nella creazione dell'utente Firebase Auth: {e}")
        return (f'Internal Server Error: Errore nella creazione utente Auth: {e}', 500)

    # Salvataggio dei Dettagli Utente e Livello di Autorizzazione in Firestore
    try:
        user_profile_data = {
            "name": name,
            "surname": surname,
            "level": level,
            "enabled": True,
            "fcm_token": None  # Inizialmente impostato a None, verrà aggiornato una volta che l'utente fa il login dal suo dispositivo
        }
        # Salva il profilo utente nella collezione user_profiles
        USERS_PROFILES_COLLECTION_REF.document(new_user_uid).set(user_profile_data)
    except Exception as e:
        print(f"Errore nel salvataggio dei dettagli utente/ruolo in Firestore: {e}")
        auth.delete_user(new_user_uid)
        return (f'Internal Server Error: Errore nel salvataggio Firestore: {e}', 500)

    return (f'Utente {email} (UID: {new_user_uid}) creato e dettagli salvati con successo!', 201)