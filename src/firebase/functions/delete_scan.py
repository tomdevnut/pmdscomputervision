from firebase_functions import storage_fn
from firebase_admin import firestore, storage
import os
from config import BUCKET_NAME

@storage_fn.on_object_deleted(bucket=BUCKET_NAME)
def delete_scan(event: storage_fn.CloudEvent):
    """
    Trigger che si attiva all'eliminazione di un file da Cloud Storage.
    Se il file è una scansione, esegue la pulizia a cascata dei dati
    corrispondenti in Firestore e dei file di statistiche corrispondenti in Storage.
    Le regole di eliminazione sono definite nelle regole di Cloud Storage.
    In particolare:

    // Eliminazione (delete): consentita a qualsiasi utente autenticato SOLO SE
    // il documento corrispondente in Firestore ha 'progress' a 100 OPPURE 'status' a -1 (errore) E
    // chi sta cancellando la scansione è il proprietario oppure ha livello >= 1.
    allow delete: if request.auth != null && 
                    (firestore.get(/databases/(default)/documents/scans/$(fileName.split('.')[0])).data.progress == 100 ||
                    firestore.get(/databases/(default)/documents/scans/$(fileName.split('.')[0])).data.status == -1) &&
                    (getAuthorizationLevel(request.auth.id) >= 1 ||
                    request.resource.metadata.user == request.auth.uid);

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
        doc_id = os.path.splitext(file_name)[0] # è l'ID del documento Firestore e della statistica
    except Exception as e:
        print(f"Impossibile estrarre l'ID dal percorso del file '{file_path}': {e}")
        return

    try:
        bucket = storage.bucket(bucket_name)

        # Recupera e elimina la statistica associata (l'id della statistica è lo stesso della scansione)

        # TODO: definire il formato corretto
        stats_blob = bucket.blob(f'comparisons/{doc_id}.json')
        if stats_blob.exists():
            stats_blob.delete()
            print(f"Eliminato il file di statistiche '{stats_blob.name}'.")

        # Elimina il documento della scansione principale
        scan_doc_ref = SCANS_COLLECTION_REF.document(doc_id)
        if scan_doc_ref.get().exists:
            scan_doc_ref.delete()

        # Elimina il documento della statistica dal Firestore
        stat_doc_ref = STATS_COLLECTION_REF.document(doc_id)
        if stat_doc_ref.get().exists:
            stat_doc_ref.delete()

    except Exception as e:
        print(f"Errore critico durante la pulizia per l'ID {doc_id}: {e}")