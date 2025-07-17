import os
from firebase_functions import storage_fn
from firebase_admin import firestore, initialize_app

@storage_fn.on_object_deleted()
def delete_step(event: storage_fn.CloudEvent) -> None:
    """
    Cloud Event Function che si attiva quando un file "step" viene eliminato da Cloud Storage.
    Rimuove il documento corrispondente dalla collezione 'steps' di Firestore.
    Tutte le scan associate assumono valore dello step come None.
    Args:
        event (storage_fn.CloudEvent): L'evento che contiene i dati del file eliminato.
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
        doc_id_to_delete = os.path.splitext(file_name)[0]

        # Elimina il documento da Firestore usando il suo ID
        STEPS_COLLECTION_REF.document(doc_id_to_delete).delete()

        # Aggiorna le scansioni associate a questo step
        scans = SCANS_COLLECTION_REF.where("step", "==", doc_id_to_delete).stream()
        for scan in scans:
            SCANS_COLLECTION_REF.document(scan.id).update({"step": None})
    except Exception as e:
        print(f"Errore durante l'eliminazione del documento da Firestore: {e}")
        return