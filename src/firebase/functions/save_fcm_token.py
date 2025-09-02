import json
from firebase_functions import https_fn, options
from firebase_admin import firestore, auth

@https_fn.on_request(cors=True)
def save_fcm_token(request: https_fn.Request) -> https_fn.Response:
    """
    HTTP Cloud Function to save or update a user's FCM token.
    The user must be authenticated to call this function.
    """
    db = firestore.client()
    if request.method == 'OPTIONS':
        return https_fn.Response(status=204)
  
    # Reference to the Firestore collection for user profiles
    USERS_COLLECTION_REF = db.collection('users')

    # --- Authentication Check ---
    auth_header = request.headers.get('Authorization')
    if not auth_header or not auth_header.startswith('Bearer '):
        response_data = {'status': 'error', 'message': 'Unauthorized'}
        return https_fn.Response(json.dumps(response_data), status=401, mimetype='application/json')
    
    id_token = auth_header.split('Bearer ')[1]
    try:
        # Verify the Firebase ID token
        decoded_token = auth.verify_id_token(id_token)
        user_uid = decoded_token['uid']
    except Exception as e:
        print(f"Invalid or expired ID token: {e}")
        response_data = {'status': 'error', 'message': 'Unauthorized: Invalid or expired token.'}
        return https_fn.Response(json.dumps(response_data), status=401, mimetype='application/json')
    
    # --- Extract FCM token from the request ---
    try:
        request_json = request.get_json(silent=True)
        if not request_json:
            raise ValueError("Missing or invalid JSON request body.")
            
        fcm_token = request_json.get('fcm_token')
        if not fcm_token:
            raise ValueError("The 'fcm_token' field is missing from the request body.")
            
    except ValueError as e:
        response_data = {'status': 'error', 'message': f'Bad Request: {e}'}
        return https_fn.Response(json.dumps(response_data), status=400, mimetype='application/json')
    except Exception as e:
        response_data = {'status': 'error', 'message': 'Bad Request: Invalid JSON format.'}
        return https_fn.Response(json.dumps(response_data), status=400, mimetype='application/json')
    
    # --- Save the FCM token to the user's document ---
    try:
        user_doc_ref = USERS_COLLECTION_REF.document(user_uid)
        # Use 'merge=True' to update only the fcm_token field without overwriting other data
        user_doc_ref.set({'fcm_token': fcm_token}, merge=True)
    except Exception as e:
        print(f"Error saving token to Firestore for user {user_uid}: {e}")
        response_data = {'status': 'error', 'message': 'Internal Server Error: Failed to save FCM token.'}
        return https_fn.Response(json.dumps(response_data), status=500, mimetype='application/json')
    
    # --- Final Success Response ---
    response_data = {
        'status': 'success',
        'message': f'FCM token for user {user_uid} saved successfully.'
    }
    return https_fn.Response(json.dumps(response_data), status=200, mimetype='application/json')