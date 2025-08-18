import pytest
from firebase_admin import storage, firestore
import time
import uuid

def test_upload_step_trigger_creates_document_with_correct_data():
    """
    Tests the upload_step trigger by uploading a file with the required metadata.
    It then verifies that a corresponding document with the correct data is created
    in the 'steps' collection in Firestore.
    """
    # 1. Setup
    db = firestore.client()
    bucket = storage.bucket()
    
    step_id = f"test-step-{uuid.uuid4()}" # Usa un ID unico per evitare conflitti
    user_id = "test-user-for-upload"
    step_name = "Initial Calibration"
    storage_path = f"steps/{step_id}.bin"

    # 2. Action: Upload a dummy file with the required metadata
    blob = bucket.blob(storage_path)
    
    # Imposta i metadati personalizzati che la funzione si aspetta
    custom_metadata = {"user": user_id, "name": step_name}
    blob.metadata = {"metadata": custom_metadata} # L'SDK richiede questo doppio "metadata"
    
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
    assert step_data.get("user") == user_id
    assert step_data.get("path") == storage_path