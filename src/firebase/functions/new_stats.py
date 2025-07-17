from firebase_functions import firestore_fn
from firebase_admin import initialize_app, firestore, messaging

@firestore_fn.on_document_created(document='stats/{scan_id}')
def new_stats(event: firestore_fn.Event[firestore_fn.Change]) -> None:
    """
    Trigger che si attiva alla creazione di una nuova statistica in Firestore.
    Invia una notifica push all'utente che ha richiesto la scansione.
    """

    db = firestore.client()

    # Riferimento alla collezione Firestore per le statistiche
    SCANS_COLLECTION_REF = db.collection('stats')
    USERS_COLLECTION_REF = db.collection('users')

    try:
        stat_data = event.data.to_dict()
        scan_id = stat_data.get("scan")

        scan_doc = SCANS_COLLECTION_REF.document(scan_id).get()
        if not scan_doc.exists:
            print(f"Documento scansione con ID {scan_id} non trovato.")
            return
        user_id = scan_doc.to_dict().get("user")

        user_doc = USERS_COLLECTION_REF.document(user_id).get()
        if not user_doc.exists:
            print(f"Profilo utente con ID {user_id} non trovato.")
            return
        fcm_token = user_doc.to_dict().get("fcm_token")

        # Invio la notifica push all'utente
        message = messaging.Message(
            notification=messaging.Notification(
                title="Elaborazione completata!",
                body=f"La tua scansione è stata analizzata con successo."
            ),
            token=fcm_token
        )

        response = messaging.send(message)
        print(f"Notifica inviata con successo: {response}")
    except Exception as e:
        print(f"Errore durante l'invio della notifica: {e}")
        return
    