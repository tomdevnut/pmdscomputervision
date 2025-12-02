import json
from firebase_functions import https_fn, options
from firebase_admin import firestore, auth, storage
from config import BUCKET_NAME, MANAGE_USERS_MIN_LEVEL

@https_fn.on_request(
    cors=options.CorsOptions(
        cors_origins=[r"*"],
        cors_methods=["get", "post"],
    )
)
def delete_user(request: https_fn.Request) -> https_fn.Response:
    """
    HTTP Cloud Function to delete an existing user from Firebase Authentication
    and all their associated data (scans, stats, profiles, steps) from Cloud Storage and Firestore.
    Requires the invoking user to have an authorization level of 2.
    A level 2 user cannot be deleted.
    Args:
        request (flask.Request): The HTTP request containing the data of the user to be deleted.
    """
    if request.method == 'OPTIONS':
        return https_fn.Response(status=204)
  
    db = firestore.client()

    # Firestore collection references
    USERS_COLLECTION_REF = db.collection('users')
    SCANS_COLLECTION_REF = db.collection('scans')
    STATS_COLLECTION_REF = db.collection('stats')
    STEPS_COLLECTION_REF = db.collection('steps')

    bucket = storage.bucket(BUCKET_NAME)

    # --- Authentication and Caller Authorization Check ---
    auth_header = request.headers.get('Authorization')
    if not auth_header or not auth_header.startswith('Bearer '):
        response_data = {'status': 'error', 'message': 'Unauthorized'}
        return https_fn.Response(json.dumps(response_data), status=401, mimetype='application/json')

    id_token = auth_header.split('Bearer ')[1]
    try:
        decoded_token = auth.verify_id_token(id_token)
        caller_uid = decoded_token['uid']
    except Exception as e:
        response_data = {'status': 'error', 'message': 'Unauthorized: Invalid token'}
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
            raise ValueError("The 'uid' field for the user to be deleted is required.")
    except ValueError as e:
        print(f"Input validation error: {e}")
        response_data = {'status': 'error', 'message': f'Bad Request: {e}'}
        return https_fn.Response(json.dumps(response_data), status=400, mimetype='application/json')
    except Exception as e:
        print(f"Error parsing JSON request: {e}")
        response_data = {'status': 'error', 'message': 'Bad Request: Invalid JSON format.'}
        return https_fn.Response(json.dumps(response_data), status=400, mimetype='application/json')

    # --- Target User Authorization Check ---
    if target_uid == caller_uid:
        print(f"Attempt to delete self ({target_uid}). Operation not allowed.")
        response_data = {'status': 'error', 'message': 'Forbidden: Cannot delete yourself.'}
        return https_fn.Response(json.dumps(response_data), status=403, mimetype='application/json')

    target_user_auth_level = -1
    try:
        target_role_doc = USERS_COLLECTION_REF.document(target_uid).get()
        if not target_role_doc.exists:
            response_data = {'status': 'error', 'message': 'Not Found: User not found.'}
            return https_fn.Response(json.dumps(response_data), status=404, mimetype='application/json')
            
        target_user_auth_level = target_role_doc.to_dict().get('level', -1)
    except Exception as e:
        response_data = {'status': 'error', 'message': 'Internal Server Error: Failed to retrieve target user role.'}
        return https_fn.Response(json.dumps(response_data), status=500, mimetype='application/json')

    if target_user_auth_level >= MANAGE_USERS_MIN_LEVEL:
        response_data = {'status': 'error', 'message': f'Forbidden: Cannot delete a level {MANAGE_USERS_MIN_LEVEL} user.'}
        return https_fn.Response(json.dumps(response_data), status=403, mimetype='application/json')

    # --- Main Deletion Logic ---
    try:
        # Delete user from Firebase Authentication
        try:
            auth.delete_user(target_uid)
        except auth.UserNotFoundError:
            print(f"User {target_uid} not found in Firebase Authentication. It may have already been deleted.")
        except Exception as e:
            raise Exception(f"Failed to delete user from Auth: {e}")

        # Delete associated data from Cloud Storage and Firestore
        deleted_scans_count = 0
        deleted_steps_count = 0

        # Delete scans and related data
        scans_to_delete = SCANS_COLLECTION_REF.where(field_path='user', op_string='==', value=target_uid).stream()
        for doc in scans_to_delete:
            scan_id = doc.id
            
            # Delete scan file from Cloud Storage
            try:
                blob = bucket.blob(f'scans/{scan_id}.ply')
                if blob.exists():
                    blob.delete()
            except Exception as e:
                print(f"Error deleting file {scan_id} from Cloud Storage: {e}")
                
            # Delete associated stats file from Cloud Storage
            try:
                blob = bucket.blob(f'comparisons/{scan_id}.ply')
                if blob.exists():
                    blob.delete()
            except Exception as e:
                print(f"Error deleting stats for scan {scan_id}: {e}")

            # Delete associated stats from Firestore
            try:
                stats_docs_to_delete = STATS_COLLECTION_REF.where(field_path='scan', op_string='==', value=scan_id).stream()
                for stat_doc in stats_docs_to_delete:
                    stat_doc.reference.delete()
            except Exception as e:
                print(f"Error deleting stats for scan {scan_id} from Firestore: {e}")

            # Delete the scan document itself from Firestore
            doc.reference.delete()
            deleted_scans_count += 1
        
        # Delete 'steps' collection data if the user is a level 1 admin
        if target_user_auth_level == 1:
            steps_to_delete = STEPS_COLLECTION_REF.where(field_path='user', op_string='==', value=target_uid).stream()
            for step_doc in steps_to_delete:
                # Delete associated file from Storage
                try:
                    blob = bucket.blob(f'steps/{step_doc.id}.step')
                    if blob.exists():
                        blob.delete()
                except Exception as e:
                    print(f"Error deleting step file {step_doc.id} from Cloud Storage: {e}")
                
                # Delete the step document itself from Firestore
                step_doc.reference.delete()
                deleted_steps_count += 1

        # Delete the user's profile document from Firestore
        USERS_COLLECTION_REF.document(target_uid).delete()
        
        # --- Final Success Response ---
        response_data = {
            'status': 'success',
            'message': f'User {target_uid} and all associated data successfully deleted.',
            'data': {
                'deleted_scans_count': deleted_scans_count,
                'deleted_steps_count': deleted_steps_count
            }
        }
        return https_fn.Response(json.dumps(response_data), status=200, mimetype='application/json')
        
    except Exception as e:
        print(f"Critical error during cleanup: {e}")
        response_data = {'status': 'error', 'message': f'Internal Server Error: Failed to delete user and associated data: {e}'}
        return https_fn.Response(json.dumps(response_data), status=500, mimetype='application/json')