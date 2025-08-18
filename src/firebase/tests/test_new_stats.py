import pytest
from firebase_admin import firestore
import time

def test_new_stats_on_scan_create():
    """
    Tests the new_stats trigger by creating a scan document in Firestore.
    It then checks if the corresponding stats document is created/updated.
    """
    db = firestore.client()
    
    # 1. Setup: Define scan data
    user_id = "user_for_stats_test"
    scan_id = "scan_for_stats_test"
    scan_data = {
        "user_id": user_id,
        "status": "completed",
        # ... other scan fields
    }

    # 2. Action: Create a new document in the 'scans' collection
    scans_ref = db.collection('scans')
    scans_ref.document(scan_id).set(scan_data)

    # 3. Give the function time to execute
    time.sleep(3)

    # 4. Verify: Check if the stats document was created/updated
    stats_ref = db.collection('stats').document(user_id)
    stats_doc = stats_ref.get()

    assert stats_doc.exists, "Stats document was not created for the user"
    
    stats_data = stats_doc.to_dict()
    assert "total_scans" in stats_data
    assert stats_data["total_scans"] > 0
