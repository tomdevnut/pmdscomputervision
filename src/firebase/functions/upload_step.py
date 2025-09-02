import os
from firebase_functions import storage_fn
from firebase_admin import firestore
from config import BUCKET_NAME

@storage_fn.on_object_finalized(bucket=BUCKET_NAME)
def upload_step(event: storage_fn.CloudEvent) -> None:
    """
    Cloud Event Function that triggers when a new "step" file is uploaded to Cloud Storage.
    It creates a document in the 'steps' Firestore collection, associating the user
    (via UID) with the uploaded file's path.
    The user's UID must be provided in the uploaded file's metadata.
    Args:
        event (storage_fn.CloudEvent): The event containing the file data.
    """
    db = firestore.client()

    # Reference to the Firestore collection for steps
    STEPS_COLLECTION_REF = db.collection('steps')

    file_path = event.data.name
    metadata = event.data.metadata or {}

    if not file_path.startswith("steps/"):
        print(f"File {file_path} is not a 'step' file. Ignoring.")
        return
    
    user_id = metadata.get("user")
    step_name = metadata.get("step_name")
    description = metadata.get("description")

    # Validate essential metadata fields
    if not user_id:
        print(f"Error: 'user' is missing from the metadata of file {file_path}.")
        return
    
    if not step_name:
        print(f"Error: 'step_name' is missing from the metadata of file {file_path}.")
        return

    if not description:
        print(f"Error: 'description' is missing from the metadata of file {file_path}.")
        return

    try:
        step_data = {
            "name": step_name,
            "user": user_id,
            "description": description
        }

        # Extract the file's UUID from the path
        file_id = os.path.basename(file_path)
        custom_doc_id = os.path.splitext(file_id)[0]

        # Add the document with the custom ID
        doc_ref = STEPS_COLLECTION_REF.document(custom_doc_id)
        doc_ref.set(step_data)
        print(f"Successfully created Firestore document for step {custom_doc_id}.")
    except Exception as e:
        print(f"Error writing to Firestore: {e}")
        return