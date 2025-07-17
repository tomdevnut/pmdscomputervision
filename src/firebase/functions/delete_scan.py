from firebase_functions import storage_fn
from firebase_admin import initialize_app, firestore, storage
import os

@storage_fn.on_object_deleted()
def delete_scan(event: storage_fn.CloudEvent):
    """
    Trigger che si attiva all'eliminazione di un file da Cloud Storage.
    Se il file è una scansione, esegue la pulizia a cascata dei dati
    corrispondenti in Firestore e dei file di output in Storage.
    """
    db = firestore.client()

    # Riferimenti alle collezioni Firestore
    SCANS_COLLECTION_REF = db.collection('scans')
    STATS_COLLECTION_REF = db.collection('stats')

    bucket_name = event.data.bucket
    file_path = event.data.name

    # Esegui solo per i file nella cartella 'scans/'
    if not file_path.startswith('scans/'):
        print(f"Eliminazione del file '{file_path}' ignorata perché non è una scansione.")
        return

    # Estrai l'ID dal nome del file (che corrisponde all'ID dei documenti)
    try:
        file_name = os.path.basename(file_path)
        doc_id = os.path.splitext(file_name)[0]
    except Exception as e:
        print(f"Impossibile estrarre l'ID dal percorso del file '{file_path}': {e}")
        return

    try:
        bucket = storage.bucket(bucket_name)

        # Recupera e elimina la statistica associata
        stat_doc_ref = STATS_COLLECTION_REF.document(doc_id)
        stat_doc = stat_doc_ref.get()

        if stat_doc.exists:
            stat_data = stat_doc.to_dict()
            out_path = stat_data.get('out_path')
            
            # Elimina il file di output della comparison
            if out_path:
                blob = bucket.blob(out_path)
                if blob.exists():
                    blob.delete()
            
            # Elimina il documento della statistica
            stat_doc_ref.delete()

        # Elimina il documento della scansione principale
        scan_doc_ref = SCANS_COLLECTION_REF.document(doc_id)
        if scan_doc_ref.get().exists:
            scan_doc_ref.delete()
    except Exception as e:
        print(f"Errore critico durante la pulizia per l'ID {doc_id}: {e}")