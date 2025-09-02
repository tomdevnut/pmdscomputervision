import json
from firebase_functions import https_fn
from firebase_admin import firestore, storage, auth
from config import BUCKET_NAME, SUPERUSER_ROLE_LEVEL

@https_fn.on_request()
def clean_scans(request: https_fn.Request) -> https_fn.Response:
    """
    HTTP Cloud Function to clean all scan files from Cloud Storage
    and their corresponding entries from Firestore (scans and stats).
    Requires authentication of a user with a sufficient authorization level.
    """
    
    db = firestore.client()
    SCANS_COLLECTION_REF = db.collection('scans')
    STATS_COLLECTION_REF = db.collection('stats')
    USERS_COLLECTION_REF = db.collection('users')

    auth_header = request.headers.get('Authorization')
    if not auth_header or not auth_header.startswith('Bearer '):
        response_data = {'status': 'error', 'message': 'Unauthorized'}
        return https_fn.Response(json.dumps(response_data), status=401, mimetype='application/json')

    id_token = auth_header.split('Bearer ')[1]
    try:
        decoded_token = auth.verify_id_token(id_token)
        uid = decoded_token['uid']
        print(f"User {uid} requested cleanup.")
    except Exception as e:
        response_data = {'status': 'error', 'message': f'Unauthorized: {e}'}
        return https_fn.Response(json.dumps(response_data), status=401, mimetype='application/json')

    try:
        user_role_doc = USERS_COLLECTION_REF.document(uid).get()
        if not user_role_doc.exists:
            response_data = {'status': 'error', 'message': 'Forbidden: User not found'}
            return https_fn.Response(json.dumps(response_data), status=403, mimetype='application/json')
            
        user_role_data = user_role_doc.to_dict()
        if not (user_role_data.get('level', 0) >= SUPERUSER_ROLE_LEVEL and user_role_data.get('enabled', False)):
            response_data = {'status': 'error', 'message': 'Forbidden: Insufficient privileges'}
            return https_fn.Response(json.dumps(response_data), status=403, mimetype='application/json')
    except Exception as e:
        print(f"Error while retrieving user role: {e}")
        response_data = {'status': 'error', 'message': 'Internal Server Error: Failed to retrieve user role'}
        return https_fn.Response(json.dumps(response_data), status=500, mimetype='application/json')

    print(f"User {uid} is authorized. Starting cleanup process.")

    deleted_files_count = 0
    deleted_scans_docs_count = 0
    deleted_stats_docs_count = 0

    # Deleting files from Cloud Storage
    try:
        bucket = storage.bucket(BUCKET_NAME)
        prefixes = ["comparisons/", "scans/"]
        for prefix in prefixes:
            blobs = bucket.list_blobs(prefix=prefix)
            for blob in blobs:
                # Avoid deleting the root folder itself if it's not empty
                if blob.name != prefix:
                    blob.delete()
                    deleted_files_count += 1
        print(f"Deleted {deleted_files_count} files from Cloud Storage.")
    except Exception as e:
        print(f"Error while deleting files from Cloud Storage: {e}")
        response_data = {'status': 'error', 'message': f"Internal Server Error: Failed to clean Cloud Storage: {e}"}
        return https_fn.Response(json.dumps(response_data), status=500, mimetype='application/json')

    # Cleaning the 'scans' collection in Firestore
    try:
        docs = SCANS_COLLECTION_REF.stream()
        for doc in docs:
            doc.reference.delete()
            deleted_scans_docs_count += 1
        print(f"Deleted {deleted_scans_docs_count} entries from the 'scans' collection.")
    except Exception as e:
        print(f"Error while cleaning 'scans' in Firestore: {e}")
        response_data = {'status': 'error', 'message': f"Internal Server Error: Failed to clean Firestore (scans): {e}"}
        return https_fn.Response(json.dumps(response_data), status=500, mimetype='application/json')

    # Cleaning the 'stats' collection in Firestore
    try:
        docs = STATS_COLLECTION_REF.stream()
        for doc in docs:
            doc.reference.delete()
            deleted_stats_docs_count += 1
        print(f"Deleted {deleted_stats_docs_count} entries from the 'stats' collection.")
    except Exception as e:
        print(f"Error while cleaning 'stats' in Firestore: {e}")
        response_data = {'status': 'error', 'message': f"Internal Server Error: Failed to clean Firestore (stats): {e}"}
        return https_fn.Response(json.dumps(response_data), status=500, mimetype='application/json')

    response_data = {
        'status': 'success',
        'message': 'Successfully deleted all data!',
        'data': {
            'deleted_files': deleted_files_count,
            'deleted_scans_docs': deleted_scans_docs_count,
            'deleted_stats_docs': deleted_stats_docs_count
        }
    }
    return https_fn.Response(json.dumps(response_data), status=200, mimetype='application/json')