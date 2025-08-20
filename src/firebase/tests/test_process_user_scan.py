from firebase_admin import storage, firestore
import time

def test_process_user_scan_success(create_user_in_emulator, get_storage_bucket_name):
    """
    Tests the process_user_scan trigger by uploading a file with metadata.
    It then checks Firestore for the created scan document.
    """
    # 1. Setup
    user_id = "user_for_scan_test"
    step_id = "step_for_scan_test"
    create_user_in_emulator(uid=user_id, email="scanuser@test.com", password="password", level=1)

    bucket = storage.bucket(get_storage_bucket_name)
    
    # Create dummy files to upload
    scan_content = b"dummy scan data"
    step_content = b"dummy step data"
    
    scan_blob_name = f"scans/test_scan.bin"
    step_blob_name = f"steps/{step_id}.bin"

    # Upload step file (dependency)
    step_blob = bucket.blob(step_blob_name)
    step_blob.upload_from_string(step_content)

    # Upload scan file with metadata to trigger the function
    scan_blob = bucket.blob(scan_blob_name)
    scan_blob.metadata = {"user": user_id, "step": f"{step_id}.bin"}
    scan_blob.upload_from_string(scan_content)

    # 2. Give the function time to execute
    time.sleep(5) # Wait for the trigger to fire and execute

    # 3. Verify the result in Firestore
    db = firestore.client()
    scans_ref = db.collection('scans')
    query = scans_ref.where("user_id", "==", user_id).limit(1).stream()
    
    docs = list(query)
    assert len(docs) == 1, "Scan document was not created in Firestore"
    
    scan_data = docs[0].to_dict()
    assert scan_data["user_id"] == user_id
    assert "scan_url" in scan_data
    assert "step_url" in scan_data
