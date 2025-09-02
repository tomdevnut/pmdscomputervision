import json
from firebase_functions import https_fn, options
from firebase_admin import firestore, auth
from config import MANAGE_USERS_MIN_LEVEL
from _user_utils import create_user_in_firebase

@https_fn.on_request(cors=True)
def new_user(request: https_fn.Request) -> https_fn.Response:
    """
    HTTP Cloud Function to create new users in Firebase Authentication
    and save their details in Firestore.
    Requires the invoking user to have an authorization level of 2.
    Args:
        request (flask.Request): The HTTP request containing the new user's data.
    """
    if request.method == 'OPTIONS':
        return https_fn.Response(status=204)
  
    db = firestore.client()

    # Firestore collection reference
    USERS_PROFILES_COLLECTION_REF = db.collection('users')

    # --- Authentication and Caller Authorization Check ---
    auth_header = request.headers.get('Authorization')
    if not auth_header or not auth_header.startswith('Bearer '):
        response_data = {'status': 'error', 'message': 'Unauthorized'}
        return https_fn.Response(json.dumps(response_data), status=401, mimetype='application/json')

    id_token = auth_header.split('Bearer ')[1]
    try:
        # Verify the caller's Firebase ID token
        decoded_token = auth.verify_id_token(id_token)
        caller_uid = decoded_token['uid']
    except Exception as e:
        response_data = {'status': 'error', 'message': 'Unauthorized'}
        return https_fn.Response(json.dumps(response_data), status=401, mimetype='application/json')

    caller_auth_level = -1
    try:
        caller_role_doc = USERS_PROFILES_COLLECTION_REF.document(caller_uid).get()
        if not caller_role_doc.exists:
            response_data = {'status': 'error', 'message': 'Forbidden: Caller user not found.'}
            return https_fn.Response(json.dumps(response_data), status=403, mimetype='application/json')
            
        caller_auth_level = caller_role_doc.to_dict().get('level', -1)
    except Exception as e:
        print(f"Error while retrieving caller role: {e}")
        response_data = {'status': 'error', 'message': 'Internal Server Error: Failed to retrieve caller role.'}
        return https_fn.Response(json.dumps(response_data), status=500, mimetype='application/json')

    if caller_auth_level < MANAGE_USERS_MIN_LEVEL:
        print(f"User {caller_uid} (level {caller_auth_level}) not authorized to create new users. Required level is {MANAGE_USERS_MIN_LEVEL}.")
        response_data = {'status': 'error', 'message': 'Forbidden: Insufficient privileges.'}
        return https_fn.Response(json.dumps(response_data), status=403, mimetype='application/json')

    # --- Parse Request Data for the New User ---
    try:
        request_json = request.get_json(silent=True)
        if not request_json:
            raise ValueError("Missing or invalid JSON request body.")

        email = request_json.get('email')
        password = request_json.get('password')
        level = request_json.get('level')
        name = request_json.get('name')
        surname = request_json.get('surname')

        # Input validation
        if not all([email, password, level is not None, name, surname]):
            raise ValueError("The fields 'email', 'password', 'level', 'name', 'surname' are all required.")
        if not isinstance(level, int) or level not in [0, 1]:
            raise ValueError("The authorization level must be 0 or 1.")

    except ValueError as e:
        print(f"Input validation error: {e}")
        response_data = {'status': 'error', 'message': f'Bad Request: {e}'}
        return https_fn.Response(json.dumps(response_data), status=400, mimetype='application/json')
    except Exception as e:
        print(f"Error parsing JSON request: {e}")
        response_data = {'status': 'error', 'message': 'Bad Request: Invalid JSON format.'}
        return https_fn.Response(json.dumps(response_data), status=400, mimetype='application/json')

    # --- Create the New User using the Helper Function ---
    try:
        user_record = create_user_in_firebase(db, email, password, level, name, surname)
        new_user_uid = user_record.uid
    except auth.EmailAlreadyExistsError:
        print(f"Error: The email {email} already exists.")
        response_data = {'status': 'error', 'message': 'Conflict: Email already registered.'}
        return https_fn.Response(json.dumps(response_data), status=409, mimetype='application/json')
    except Exception as e:
        print(f"Error creating user: {e}")
        response_data = {'status': 'error', 'message': f'Internal Server Error: {e}'}
        return https_fn.Response(json.dumps(response_data), status=500, mimetype='application/json')

    # --- Final Success Response ---
    response_data = {
        'status': 'success',
        'message': f'User {email} (UID: {new_user_uid}) created and details saved successfully!',
        'data': {
            'uid': new_user_uid
        }
    }
    return https_fn.Response(json.dumps(response_data), status=200, mimetype='application/json')