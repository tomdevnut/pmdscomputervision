import pytest
from firebase_admin import storage, firestore
import time

def test_delete_step_trigger():
    """
    Tests the delete_step trigger.
    It verifies that deleting a step file from Storage:
    1. Deletes the corresponding document from the 'steps' collection.
    2. Sets the 'step' field to None in any associated scan documents.
    """
    db = firestore.client()
    bucket = storage.bucket()

    # 1. Setup
    step_id = "step_to_be_deleted_001"
    scan_id = "scan_associated_with_deleted_step"
    file_name = f"{step_id}.bin"
    storage_path = f"steps/{file_name}"

    # Create a dummy file in Storage
    blob = bucket.blob(storage_path)
    blob.upload_from_string("data to be deleted")
    assert blob.exists(), "Pre-test check: Step file should exist in Storage."

    # Create a corresponding document in 'steps' collection
    step_ref = db.collection('steps').document(step_id)
    step_ref.set({"file_name": file_name})
    assert step_ref.get().exists, "Pre-test check: Step document should exist in Firestore."

    # Create an associated scan document
    scan_ref = db.collection('scans').document(scan_id)
    scan_ref.set({"step": step_id})
    assert scan_ref.get().to_dict()['step'] == step_id, "Pre-test check: Scan should be linked to the step."

    # 2. Action: Delete the file from Storage to trigger the function
    blob.delete()

    # 3. Give the function time to execute
    time.sleep(5)

    # 4. Verify
    # Check that the step document was deleted
    assert not step_ref.get().exists, "Step document was not deleted from Firestore."

    # Check that the associated scan was updated
    updated_scan_doc = scan_ref.get()
    assert updated_scan_doc.exists, "Scan document was unexpectedly deleted."
    assert updated_scan_doc.to_dict()['step'] is None, "Scan document's step field was not set to None."