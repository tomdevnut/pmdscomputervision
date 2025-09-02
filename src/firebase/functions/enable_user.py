import json
from firebase_functions import https_fn, options
from firebase_admin import firestore, auth
from config import MANAGE_USERS_MIN_LEVEL

@https_fn.on_request(
    cors=options.CorsOptions(
        cors_origins=[r"firebase\.com$", r"https://flutter\.com"],
        cors_methods=["get", "post"],
    )
)
def enable_user(request: https_fn.Request) -> https_fn.Response:
    """
    HTTP Cloud Function to enable an existing user in Firebase Authentication
    and update their status in the Firestore database.
    Requires the invoking user to have an authorization level of 2.
    Args:
        request (flask.Request): The HTTP request containing the data of the user to be enabled.
    """
    if request.method == 'OPTIONS':
        return https_fn.Response(status=204)
  
    db = firestore.client()

    # Firestore collection reference
    USERS_COLLECTION_REF = db.collection('users')

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
        response_data = {'status': 'error', 'message': f'Unauthorized: Invalid token. {e}'}
        return https_fn.Response(json.dumps(response_data), status=401, mimetype='application/json')

    caller_auth_level = -1
    try:
        caller_role_doc = USERS_COLLECTION_REF.document(caller_uid).get()
        if not caller_role_doc.exists:
            response_data = {'status': 'error', 'message': 'Forbidden: Caller user not found.'}
            return https_fn.Response(json.dumps(response_data), status=403, mimetype='application/json')
            
        caller_auth_level = caller_role_doc.to_dict().get('level', -1)
    except Exception as e:
        response_data = {'status': 'error', 'message': 'Internal Server Error: Failed to retrieve caller role.'}
        return https_fn.Response(json.dumps(response_data), status=500, mimetype='application/json')

    if caller_auth_level < MANAGE_USERS_MIN_LEVEL:
        response_data = {'status': 'error', 'message': 'Forbidden: Insufficient privileges.'}
        return https_fn.Response(json.dumps(response_data), status=403, mimetype='application/json')

    # --- Parse Request Data for Target User ---
    try:
        request_json = request.get_json(silent=True)
        if not request_json:
            raise ValueError("Missing or invalid JSON request body.")
        
        target_uid = request_json.get('uid')
        if not target_uid:
            raise ValueError("The 'uid' field for the user to be enabled is required.")
    except ValueError as e:
        response_data = {'status': 'error', 'message': f'Bad Request: {e}'}
        return https_fn.Response(json.dumps(response_data), status=400, mimetype='application/json')
    except Exception as e:
        response_data = {'status': 'error', 'message': 'Bad Request: Invalid JSON format.'}
        return https_fn.Response(json.dumps(response_data), status=400, mimetype='application/json')

    # --- Main Enabling Logic ---
    try:
        # Update user in Firebase Auth
        auth.update_user(uid=target_uid, disabled=False)

        # Update user status in Firestore
        USERS_COLLECTION_REF.document(target_uid).update({"enabled": True})

        response_data = {'status': 'success', 'message': f'User {target_uid} successfully enabled.'}
        return https_fn.Response(json.dumps(response_data), status=200, mimetype='application/json')

    except auth.UserNotFoundError:
        response_data = {'status': 'error', 'message': 'Not Found: User not found in Firebase Auth.'}
        return https_fn.Response(json.dumps(response_data), status=404, mimetype='application/json')
    except Exception as e:
        response_data = {'status': 'error', 'message': f'Internal Server Error: {e}'}
        return https_fn.Response(json.dumps(response_data), status=500, mimetype='application/json')