from firebase_admin import storage, firestore
import time

def test_delete_scan_trigger_deletes_firestore_and_output_files(get_storage_bucket_name):
    """
    Tests that deleting a scan file from Storage correctly triggers the deletion
    of the associated Firestore documents (in 'scans' and 'stats') and the
    output file from Storage.
    """
    # 1. Setup: Creare tutti i dati e i file necessari
    db = firestore.client()
    bucket = storage.bucket(get_storage_bucket_name)
    
    scan_id = "scan_to_be_deleted_by_trigger"
    user_id = "user_for_trigger_test"
    
    # Percorsi dei file in Storage
    scan_file_path = f"scans/{scan_id}.bin"
    output_file_path = f"comparisons/{scan_id}_output.jpg"

    # Creare il file di scansione principale in Storage
    scan_blob = bucket.blob(scan_file_path)
    scan_blob.upload_from_string("dummy scan data")

    # Creare il file di output (comparison) in Storage
    output_blob = bucket.blob(output_file_path)
    output_blob.upload_from_string("dummy output data")

    # Creare il documento nella collezione 'scans'
    scan_doc_ref = db.collection('scans').document(scan_id)
    scan_doc_ref.set({"user_id": user_id})

    # Creare il documento nella collezione 'stats' con il riferimento al file di output
    stat_doc_ref = db.collection('stats').document(scan_id)
    stat_doc_ref.set({"out_path": output_file_path})

    # Verifica iniziale: assicurarsi che tutto esista prima dell'azione
    assert scan_blob.exists(), "Il file di scansione deve esistere prima del test"
    assert output_blob.exists(), "Il file di output deve esistere prima del test"
    assert scan_doc_ref.get().exists, "Il documento 'scans' deve esistere prima del test"
    assert stat_doc_ref.get().exists, "Il documento 'stats' deve esistere prima del test"

    # 2. Azione: Eliminare il file di scansione da Storage per attivare la funzione
    scan_blob.delete()

    # 3. Attesa: Dare tempo alla funzione trigger di essere eseguita
    time.sleep(5)

    # 4. Verifica: Controllare che la pulizia a cascata sia avvenuta
    assert not bucket.blob(scan_file_path).exists(), "Il file di scansione dovrebbe essere stato eliminato (azione)"
    assert not bucket.blob(output_file_path).exists(), "Il file di output sarebbe dovuto essere eliminato dalla funzione"
    assert not db.collection('scans').document(scan_id).get().exists, "Il documento 'scans' sarebbe dovuto essere eliminato dalla funzione"
    assert not db.collection('stats').document(scan_id).get().exists, "Il documento 'stats' sarebbe dovuto essere eliminato dalla funzione"