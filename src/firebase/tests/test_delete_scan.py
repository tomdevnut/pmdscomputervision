import pytest
from firebase_admin import storage, firestore
import time

def test_delete_scan_trigger(create_user_in_emulator):
    """
    Tests the delete_scan trigger by creating and then deleting a scan document.
    It verifies that the associated file in Storage is also deleted.
    """
    # 1. Setup
    user_id = "user_for_delete_scan_test"
    scan_id = "scan_to_be_deleted"
    file_name = f"{user_id}_{scan_id}.bin"
    storage_path = f"scans/{file_name}"

    create_user_in_emulator(uid=user_id, email="deletescan@test.com", password="password", level=1)

    # Create a dummy file in Storage
    bucket = storage.bucket()
    blob = bucket.blob(storage_path)
    blob.upload_from_string("dummy data for deletion test")
    assert blob.exists(), "File should exist in Storage before test"

    # Create a corresponding document in Firestore
    db = firestore.client()
    scan_ref = db.collection('scans').document(scan_id)
    scan_ref.set({
        "user_id": user_id,
        "file_name": file_name # Function needs to know the file name
    })

    # 2. Action: Delete the Firestore document to trigger the function
    scan_ref.delete()

    # 3. Give the function time to execute
    time.sleep(5)

    # 4. Verify: Check that the file in Storage was deleted
    assert not bucket.blob(storage_path).exists(), "File was not deleted from Storage"
