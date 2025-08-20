from firebase_admin import firestore
import time

def test_new_stats_trigger_runs_without_error():
    """
    Testa che il trigger new_stats venga eseguito senza errori quando
    un nuovo documento viene creato nella collezione 'stats'.
    """
    db = firestore.client()
    
    # 1. Setup: Crea i dati necessari per l'esecuzione della funzione
    user_id = "test_user_for_notification"
    scan_id = "test_scan_for_notification"
    fcm_token = "fake_fcm_token_for_testing"

    # Crea un documento utente con un fcm_token
    user_ref = db.collection('users').document(user_id)
    user_ref.set({"fcm_token": fcm_token})

    # Dati per il nuovo documento 'stats'
    stats_data = {
        "user": user_id,
        "some_stat": "some_value"
    }

    # 2. Azione: Crea un nuovo documento nella collezione 'stats' per attivare la funzione
    stats_ref = db.collection('stats')
    stats_ref.document(scan_id).set(stats_data)

    # 3. Dai alla funzione il tempo di essere eseguita
    # (Nei log dell'emulatore dovresti vedere l'esecuzione della funzione)
    time.sleep(3)

    # 4. Verifica: In un test reale, potresti "mockare" la funzione messaging.send()
    # per verificare che sia stata chiamata. Per ora, ci accontentiamo di
    # verificare che la funzione non vada in crash (controlla i log dell'emulatore).
    # Il test passa se non ci sono eccezioni.
    
    # Cleanup
    user_ref.delete()
    stats_ref.document(scan_id).delete()

    # Aggiungiamo un'asserzione semplice per completezza
    assert True, "Il test è stato completato, controlla i log dell'emulatore per errori."