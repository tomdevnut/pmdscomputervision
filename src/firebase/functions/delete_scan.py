from firebase_functions import storage_fn
from firebase_admin import firestore, storage
import os
from config import BUCKET_NAME

@storage_fn.on_object_deleted(bucket=BUCKET_NAME)
def delete_scan(event: storage_fn.CloudEvent):
    """
    Trigger that activates when a file is deleted from Cloud Storage.
    If the file is a scan, it performs a cascading cleanup of the
    corresponding data in Firestore and related statistics files in Storage.
    The deletion rules are defined in the Cloud Storage security rules.
    """
    db = firestore.client()

    # Firestore collection references
    SCANS_COLLECTION_REF = db.collection('scans')
    STATS_COLLECTION_REF = db.collection('stats')

    bucket_name = event.data.bucket
    file_path = event.data.name

    # Only execute for files in the 'scans/' folder
    if not file_path.startswith('scans/'):
        print(f"File deletion for '{file_path}' ignored as it is not a scan.")
        return

    # Extract the ID from the file name (which corresponds to the document ID)
    try:
        file_name = os.path.basename(file_path)
        doc_id = os.path.splitext(file_name)[0]  # This is the Firestore document and stat ID
    except Exception as e:
        print(f"Could not extract ID from file path '{file_path}': {e}")
        return

    print(f"Starting cascading deletion for scan with ID: {doc_id}")
    
    # Track the success of each deletion
    deleted_stats_file = False
    deleted_scan_doc = False
    deleted_stat_doc = False

    try:
        bucket = storage.bucket(bucket_name)

        # Retrieve and delete the associated stat file (the stat ID is the same as the scan)
        stats_blob = bucket.blob(f'comparisons/{doc_id}.ply')
        if stats_blob.exists():
            stats_blob.delete()
            print(f"Deleted the stat file '{stats_blob.name}'.")
            deleted_stats_file = True

        # Delete the main scan document from Firestore
        scan_doc_ref = SCANS_COLLECTION_REF.document(doc_id)
        if scan_doc_ref.get().exists:
            scan_doc_ref.delete()
            print(f"Deleted the scan document with ID '{doc_id}'.")
            deleted_scan_doc = True
        else:
            print(f"Scan document with ID '{doc_id}' does not exist. Skipping deletion.")

        # Delete the stats document from Firestore
        stat_doc_ref = STATS_COLLECTION_REF.document(doc_id)
        if stat_doc_ref.get().exists:
            stat_doc_ref.delete()
            print(f"Deleted the stat document with ID '{doc_id}'.")
            deleted_stat_doc = True
        else:
            print(f"Stat document with ID '{doc_id}' does not exist. Skipping deletion.")

    except Exception as e:
        print(f"Critical error during cleanup for ID {doc_id}: {e}")
        return

    # Final success message
    print(f"Cleanup for scan {doc_id} completed.")
    print(f"Summary: Stat file deleted: {deleted_stats_file}, Scan doc deleted: {deleted_scan_doc}, Stat doc deleted: {deleted_stat_doc}")