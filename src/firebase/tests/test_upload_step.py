from firebase_admin import storage, firestore
import time
import uuid

def test_upload_step_trigger_creates_document_with_correct_data(get_storage_bucket_name, create_user_in_emulator):
    """
    Tests the upload_step trigger by uploading a file with the required metadata.
    It then verifies that a corresponding document with the correct data is created
    in the 'steps' collection in Firestore.
    """
    # 1. Setup
    db = firestore.client()
    bucket = storage.bucket(get_storage_bucket_name)
    
    step_id = f"test-step-{uuid.uuid4()}"
    step_name = "Initial Calibration"
    storage_path = f"steps/{step_id}.bin"

    admin_uid = "admin_001"
    admin_email = "admin@test.com"
    admin_pass = "password"

    create_user_in_emulator(uid=admin_uid, email=admin_email, password=admin_pass, level=2)

    # 2. Action: Upload a dummy file with the required metadata
    blob = bucket.blob(storage_path)
    blob.metadata = {"user": admin_uid, "name": step_name}
    
    blob.upload_from_string(
        "dummy step data",
        content_type="application/octet-stream"
    )

    # 3. Give the function time to execute
    print(f"File {storage_path} caricato. In attesa del trigger...")
    time.sleep(5)

    # 4. Verify: Check that the document was created in Firestore
    step_ref = db.collection('steps').document(step_id)
    step_doc = step_ref.get()
    
    assert step_doc.exists, f"Il documento dello step '{step_id}' non è stato creato in Firestore."
    
    # Verifica che i dati nel documento siano corretti
    step_data = step_doc.to_dict()
    assert step_data.get("name") == step_name
    assert step_data.get("user") == admin_uid
    assert step_data.get("path") == storage_path