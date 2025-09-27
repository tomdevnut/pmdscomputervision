from datetime import timedelta
import json
from firebase_functions import https_fn, options
from firebase_admin import firestore
from google.cloud import secretmanager, storage as google_cloud_storage
from config import BUCKET_NAME, BACKEND_API_KEY_SECRET_NAME, SERVICE_ACCOUNT, PROJECT_ID

# Function to retrieve a secret from Secret Manager
def get_secret(secret_name):
    """Retrieves a secret from Google Cloud Secret Manager."""
    if not PROJECT_ID:
        print("Error: GCP Project ID not found.")
        return None
    try:
        secret_client = secretmanager.SecretManagerServiceClient()
        name = f"projects/{PROJECT_ID}/secrets/{secret_name}/versions/latest"
        response = secret_client.access_secret_version(request={"name": name})
        return response.payload.data.decode("UTF-8")
    except Exception as e:
        print(f"Error retrieving secret '{secret_name}': {e}")
        return None

# Function to generate signed URLs using a private key
def generate_signed_url_with_key(bucket_name, file_path, private_key_secret, expiration_time):
    """
    Generates a V4 signed URL for a file in a GCS bucket using a service account private key.
    
    Args:
        bucket_name (str): The name of the GCS bucket.
        file_path (str): The path to the file in the bucket.
        private_key_secret (str): The name of the secret in Secret Manager containing the private key.
        expiration_time (timedelta): The expiration time for the signed URL.
        
    Returns:
        str: The generated signed URL.
    """
    private_key_json = get_secret(private_key_secret)
    if not private_key_json:
        raise ValueError("Private key for URL signing not found.")

    credentials_info = json.loads(private_key_json)
    
    storage_client = google_cloud_storage.Client.from_service_account_info(credentials_info)
    bucket = storage_client.bucket(bucket_name)
    blob = bucket.blob(file_path)

    signed_url = blob.generate_signed_url(
        version="v4",
        expiration=expiration_time,
        method="GET"
    )
    return signed_url



@https_fn.on_request(
    cors=options.CorsOptions(
        cors_origins=[r"*"],
        cors_methods=["get", "post"],
    )
)

def get_all_pending(request: https_fn.Request) -> https_fn.Response:
    """
    Http function fo be called by the backend server after a restart or a loss of connection. This function retreives all scans with a status of '1' (received from firebase but not yet sent to backend server).

    The server must provide the API key in the request header to be authenticated. The API key is fetched in Google Secret Manager and compared to the one provided in the request header.
    """

    db = firestore.client()
    if request.method == 'OPTIONS':
        return https_fn.Response(status=204)
  
    # Reference to the Firestore collection for scans
    SCANS_COLLECTION_REF = db.collection('scans')

    # --- Authentication Check ---
    auth_header = request.headers.get('Authorization')
    if not auth_header or not auth_header.startswith('Bearer '):
        response_data = {'status': 'error', 'message': 'Unauthorized'}
        return https_fn.Response(json.dumps(response_data), status=401, mimetype='application/json')
    
    # Extract the token from the header bearer
    id_token = auth_header.split('Bearer ')[1]

    # Retrieve the expected API key from Secret Manager
    expected_api_key = get_secret(BACKEND_API_KEY_SECRET_NAME)

    if id_token != expected_api_key:
        response_data = {'status': 'error', 'message': 'Unauthorized'}
        return https_fn.Response(json.dumps(response_data), status=401, mimetype='application/json')
    # --- End of Authentication Check ---

    # Query Firestore for all scans with status '1' (pending)
    pending_scans_query = SCANS_COLLECTION_REF.where(field_path = 'status', op_string = '==', value = 1)

    response_data = {'status': 'success', 'data': []}

    # For all pending scans, retreive the document ID and the step ID
    for doc in pending_scans_query.stream():
        doc_id = doc.id
        step_id = doc.get('step_id')

        try:
            scan_signed_url = generate_signed_url_with_key(
                BUCKET_NAME,
                f"scans/{doc_id}.ply",
                SERVICE_ACCOUNT,
                timedelta(minutes=15)
            )
            step_signed_url = generate_signed_url_with_key(
                BUCKET_NAME,
                f"steps/{step_id}.step",
                SERVICE_ACCOUNT,
                timedelta(minutes=15)
            )
        except Exception as e:
            print(f"Error generating signed URL: {e}")
            doc.update({'status': -1})  # Mark as error on server side
            continue

        # Add the signed URLs to the response data
        response_data['data'].append({
            'scan_id': doc_id,
            'step_id': step_id,
            'scan_url': scan_signed_url,
            'step_url': step_signed_url
        })

    return https_fn.Response(json.dumps(response_data), status=200, mimetype='application/json')