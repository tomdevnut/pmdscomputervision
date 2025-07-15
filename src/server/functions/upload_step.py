import os
import functions_framework
from firebase_admin import initialize_app, firestore

# Inizializzazione dell'SDK di Firebase Admin
initialize_app()
db = firestore.client()

# Riferimento alla collezzione Firestore per gli step
STEPS_COLLECTION_REF = db.collection('steps')

@functions_framework.cloud_event
def upload_step(cloud_event):
    """
    Cloud Event Function che si attiva quando un nuovo file "step" viene caricato su Cloud Storage.
    Crea un documento nella collezione 'steps' di Firestore associando l'utente (tramite UID)
    al percorso del file caricato.
    L'UID dell'utente deve essere fornito nei metadati del file caricato.
    Args:
        cloud_event (CloudEvent): L'evento che contiene i dati del file.
    """
    data = cloud_event.data
    bucket_name = data["bucket"]
    file_path = data["name"]

    if not file_path.startswith("steps/"):
        print(f"Il file {file_path} non è un file 'step'. Ignorato.")
        return
    
    # Ottenere l'ID utente dal metadata del file ed il nome del file step
    user_id = data.get("metadata", {}).get("user_id")
    step_name = data.get("metadata", {}).get("step_name")
    
    if not user_id:
        print(f"Errore: user_id mancante nei metadati del file {file_path}.")
        return
    
    if not step_name:
        print(f"Errore: step_name mancante nei metadati del file {file_path}.")
        return
    
    try:
        step_data = {
            "name": step_name,
            "path": file_path,
            "user": user_id
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


    