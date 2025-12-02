import os
from firebase_functions import storage_fn
from firebase_admin import firestore
from config import BUCKET_NAME

@storage_fn.on_object_deleted(bucket=BUCKET_NAME)
def delete_step(event: storage_fn.CloudEvent) -> None:
    """
    Cloud Event Function that triggers when a "step" file is deleted from Cloud Storage.
    It removes the corresponding document from the 'steps' Firestore collection
    and sets the 'step' field to None for all associated scans.
    Deletion rules are defined in Cloud Storage security rules.
    Specifically:

    // Deletion (delete): allowed only for authenticated users with level 1 or higher from Firestore.
        allow delete: if request.auth != null && getAuthorizationLevel(request.auth.uid) >= 1;
    """
    db = firestore.client()

    # Firestore collection references
    STEPS_COLLECTION_REF = db.collection('steps')
    SCANS_COLLECTION_REF = db.collection('scans')

    file_path = event.data.name

    if not file_path.startswith("steps/"):
        print(f"File {file_path} is not a 'step' file. Skipping.")
        return

    try:
        file_name = os.path.basename(file_path)
        doc_id_to_delete = os.path.splitext(file_name)[0]  # This is the Firestore document ID

        print(f"Starting cleanup for step with ID: {doc_id_to_delete}")
        
        # Delete the document from Firestore using its ID
        steps_doc_ref = STEPS_COLLECTION_REF.document(doc_id_to_delete)
        if steps_doc_ref.get().exists:
            steps_doc_ref.delete()
            print(f"Deleted step document with ID: {doc_id_to_delete}")
        else:
            print(f"Step document with ID '{doc_id_to_delete}' not found. Skipping deletion.")

        # Update the scans associated with this step
        scans_to_update = SCANS_COLLECTION_REF.where(field_path="step", op_string="==", value=doc_id_to_delete).stream()
        
        updated_scan_count = 0
        for scan in scans_to_update:
            SCANS_COLLECTION_REF.document(scan.id).update({"step": None})
            updated_scan_count += 1

        print(f"Successfully updated {updated_scan_count} associated scans.")

    except Exception as e:
        # Log the error for debugging
        print(f"Error during document cleanup in Firestore: {e}")