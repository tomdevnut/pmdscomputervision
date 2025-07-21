import pytest
from firebase_admin import storage, firestore
import time

def test_upload_step_trigger():
    """
    Tests the upload_step trigger by uploading a file to the 'steps/' directory.
    It then verifies that a corresponding document is created in the 'steps' collection.
    """
    # 1. Setup
    bucket = storage.bucket()
    step_id = "new_test_step_001"
    file_name = f"{step_id}.bin"
    storage_path = f"steps/{file_name}"
    
    # 2. Action: Upload a dummy file to trigger the function
    blob = bucket.blob(storage_path)
    blob.upload_from_string("dummy step data")

    # 3. Give the function time to execute
    time.sleep(3)

    # 4. Verify: Check that the document was created in Firestore
    db = firestore.client()
    step_ref = db.collection('steps').document(step_id)
    step_doc = step_ref.get()

    assert step_doc.exists, f"Step document '{step_id}' was not created in Firestore."
    
    step_data = step_doc.to_dict()
    assert "created_at" in step_data
    assert "file_name" in step_data
    assert step_data["file_name"] == file_name