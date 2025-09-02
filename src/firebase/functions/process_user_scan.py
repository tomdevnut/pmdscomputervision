import os
import json
import requests
from datetime import timedelta
from google.cloud import secretmanager, storage as google_cloud_storage
from firebase_functions import storage_fn
from firebase_admin import firestore
from config import BUCKET_NAME, BACKEND_API_KEY_SECRET_NAME, BACKEND_SERVER_URL, SERVICE_ACCOUNT, PROJECT_ID


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


@storage_fn.on_object_finalized(bucket=BUCKET_NAME)
def process_user_scan(event: storage_fn.CloudEvent) -> None:
    """
    Triggered when a new object is uploaded to the bucket.
    This function processes user scans by registering them in Firestore
    and notifying a backend server for processing.
    """
    db = firestore.client()
    scans_collection_ref = db.collection('scans')

    BACKEND_API_KEY = get_secret(BACKEND_API_KEY_SECRET_NAME)
    
    bucket_name = event.data.bucket
    file_path = event.data.name
    metadata = event.data.metadata or {}
    
    # Check if the file is a scan
    if not file_path.startswith("scans/"):
        print(f"File {file_path} is not a scan. Ignoring.")
        return
    
    # Extract data from file path and metadata
    scan_id = os.path.splitext(os.path.basename(file_path))[0]
    user_id = metadata.get("user")
    step_id = metadata.get("step")
    scan_name = metadata.get("scan_name")
    timestamp = event.data.time_created

    if not all([user_id, step_id, scan_name, timestamp]):
        print("Error: Essential metadata is missing. Cannot process scan.")
        return
    
    # Generate signed URLs for the scan and step files
    try:
        scan_signed_url = generate_signed_url_with_key(
            bucket_name,
            file_path,
            SERVICE_ACCOUNT,
            timedelta(minutes=15)
        )
        step_signed_url = generate_signed_url_with_key(
            bucket_name,
            f"steps/{step_id}",
            SERVICE_ACCOUNT,
            timedelta(minutes=15)
        )
    except Exception as e:
        print(f"Error generating signed URL: {e}")
        return

    # Register the user-scan association in the Firestore database
    try:
        scan_data = {
            "user": user_id,
            "status": 0,
            "step": step_id,
            "progress": 0,
            "name": scan_name,
            "timestamp": timestamp
        }
        scans_collection_ref.document(scan_id).set(scan_data)
        print(f"Successfully registered scan {scan_id} in Firestore.")
    except Exception as e:
        print(f"Error writing to Firestore: {e}")
        return
    
    # Notify the backend server
    if BACKEND_SERVER_URL:
        try:
            payload = {
                "user": user_id,
                "scan_id": scan_id,
                "scan_url": scan_signed_url,
                "step_url": step_signed_url
            }
            headers = {"Content-Type": "application/json"}
            if BACKEND_API_KEY:
                headers["Authorization"] = f"Bearer {BACKEND_API_KEY}"

            response = requests.post(BACKEND_SERVER_URL, json=payload, headers=headers)
            response.raise_for_status()
            print(f"Successfully notified backend server for scan {scan_id}.")
        except requests.exceptions.RequestException as e:
            print(f"Error notifying backend server: {e}")