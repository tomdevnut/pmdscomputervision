import os
from firebase_functions import storage_fn
from firebase_admin import firestore
from config import BUCKET_NAME

@storage_fn.on_object_deleted(bucket=BUCKET_NAME)
def delete_step(event: storage_fn.CloudEvent) -> None:
    """
    Cloud Event Function che si attiva quando un file "step" viene eliminato da Cloud Storage.
    Rimuove il documento corrispondente dalla collezione 'steps' di Firestore.
    Tutte le scan associate assumono valore dello step come None.
    Le regole di eliminazione sono definite nelle regole di Cloud Storage.
    In particolare:

        // Eliminazione (delete): consentito solo a utenti autenticati con livello 1 o superiore da Firestore.
            allow delete: if request.auth != null && getAuthorizationLevel(request.auth.uid) >= 1;

    """

    db = firestore.client()

    # Riferimento alla collezione Firestore per gli step
    STEPS_COLLECTION_REF = db.collection('steps')
    SCANS_COLLECTION_REF = db.collection('scans')


    file_path = event.data.name

    if not file_path.startswith("steps/"):
        print(f"Il file {file_path} non è un file 'step'. Ignorato.")
        return

    try:
        file_name = os.path.basename(file_path)
        doc_id_to_delete = os.path.splitext(file_name)[0]  # è l'ID del documento Firestore

        # Elimina il documento da Firestore usando il suo ID
        STEPS_COLLECTION_REF.document(doc_id_to_delete).delete()

        # Aggiorna le scansioni associate a questo step
        scans = SCANS_COLLECTION_REF.where("step", "==", doc_id_to_delete).stream()
        for scan in scans:
            SCANS_COLLECTION_REF.document(scan.id).update({"step": None})
    except Exception as e:
        print(f"Errore durante l'eliminazione del documento da Firestore: {e}")
        return