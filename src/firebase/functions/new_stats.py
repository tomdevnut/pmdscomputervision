from firebase_functions import firestore_fn
from firebase_admin import firestore, messaging

@firestore_fn.on_document_created(document='stats/{scan_id}')
def new_stats(event: firestore_fn.Event[firestore_fn.Change]) -> None:
    """
    Trigger that activates upon the creation of a new stat document in Firestore.
    It sends a push notification to the user who requested the scan.
    """

    db = firestore.client()

    # Firestore collection references
    STATS_COLLECTION_REF = db.collection('stats')
    USERS_COLLECTION_REF = db.collection('users')

    try:
        scan_id = event.params["scan_id"]

        stats_doc = STATS_COLLECTION_REF.document(scan_id).get()
        if not stats_doc.exists:
            print(f"Stats document with ID {scan_id} not found.")
            return
        
        user_id = stats_doc.to_dict().get("user")
        if not user_id:
            print(f"User ID not found in stats document with ID {scan_id}.")
            return

        user_doc = USERS_COLLECTION_REF.document(user_id).get()
        if not user_doc.exists:
            print(f"User profile with ID {user_id} not found.")
            return
            
        fcm_token = user_doc.to_dict().get("fcm_token")
        if not fcm_token:
            print(f"FCM token not found for user {user_id}. Cannot send notification.")
            return

        # Send the push notification to the user
        message = messaging.Message(
            notification=messaging.Notification(
                title="Processing Completed!",
                body="Your scan has been successfully analyzed."
            ),
            token=fcm_token
        )

        response = messaging.send(message)
        print(f"Notification sent successfully: {response}")
    except Exception as e:
        print(f"Error during notification send: {e}")