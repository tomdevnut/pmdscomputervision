import os
from firebase_functions import storage_fn
from firebase_admin import firestore
from config import BUCKET_NAME

@storage_fn.on_object_finalized(bucket=BUCKET_NAME)
def upload_step(event: storage_fn.CloudEvent) -> None:
    """
    Cloud Event Function che si attiva quando un nuovo file "step" viene caricato su Cloud Storage.
    Crea un documento nella collezione 'steps' di Firestore associando l'utente (tramite UID)
    al percorso del file caricato.
    L'UID dell'utente deve essere fornito nei metadati del file caricato.
    Args:
        event (storage_fn.CloudEvent): L'evento che contiene i dati del file.
    """
    db = firestore.client()

    # Riferimento alla collezzione Firestore per gli step
    STEPS_COLLECTION_REF = db.collection('steps')

    file_path = event.data.name
    metadata = event.data.metadata or {}

    if not file_path.startswith("steps/"):
        print(f"Il file {file_path} non è un file 'step'. Ignorato.")
        return
    
    user_id = metadata.get("user")
    step_name = metadata.get("step_name")
    description = metadata.get("description")

    if not user_id:
        print(f"Errore: user mancante nei metadati del file {file_path}.")
        return
    
    if not step_name:
        print(f"Errore: step_name mancante nei metadati del file {file_path}.")
        return

    if not description:
        print(f"Errore: description mancante nei metadati del file {file_path}.")
        return

    try:
        step_data = {
            "name": step_name,
            "user": user_id,
            "description": description
        }

        # Estraggo l'UUID del file dal percorso
        file_id = os.path.basename(file_path)
        custom_doc_id = os.path.splitext(file_id)[0]

        # Aggiungo il file con l'ID personalizzato
        doc_ref = STEPS_COLLECTION_REF.document(custom_doc_id)
        doc_ref.set(step_data)
    except Exception as e:
        print(f"Errore durante la scrittura su Firestore: {e}")
        return


    