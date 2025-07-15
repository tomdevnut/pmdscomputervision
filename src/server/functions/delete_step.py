import os
import functions_framework
from firebase_admin import firestore, initialize_app

# Inizializzazione dell'SDK di Firebase Admin
initialize_app()
db = firestore.client()

# Riferimento alla collezione Firestore per gli step
STEPS_COLLECTION_REF = db.collection('steps')

@functions_framework.cloud_event
def delete_step(cloud_event):
    """
    Cloud Event Function che si attiva quando un file "step" viene eliminato da Cloud Storage.
    Rimuove il documento corrispondente dalla collezione 'steps' di Firestore.
    Args:
        cloud_event (CloudEvent): L'evento che contiene i dati del file eliminato.
    """

    data = cloud_event.data
    file_path = data["name"]

    if not file_path.startswith("steps/"):
        print(f"Il file {file_path} non è un file 'step'. Ignorato.")
        return
    
    try:
        file_name = os.path.basename(file_path)
        doc_id_to_delete = os.path.splitext(file_name)[0]

        # Elimina il documento da Firestore usando il suo ID
        STEPS_COLLECTION_REF.document(doc_id_to_delete).delete()
    except Exception as e:
        print(f"Errore durante l'eliminazione del documento da Firestore: {e}")
        return