from firebase_admin import auth, firestore

def create_user_in_firebase(db: firestore.Client, email: str, password: str, level: int, name: str, surname: str):
    """
    Funzione helper per creare un utente in Firebase Auth e Firestore.
    """
    USERS_PROFILES_COLLECTION_REF = db.collection('users')

    # Creazione del nuovo utente in Firebase Authentication
    try:
        user_record = auth.create_user(
            email=email,
            password=password,
            email_verified=True
        )
    except Exception as e:
        raise e

    # Salvataggio dei Dettagli Utente in Firestore
    try:
        user_profile_data = {
            "name": name,
            "surname": surname,
            "email": email,
            "level": level,
            "enabled": True,
            "fcm_token": None
        }
        USERS_PROFILES_COLLECTION_REF.document(user_record.uid).set(user_profile_data)
        
        return user_record

    except Exception as e:
        # Se Firestore fallisce, cancella l'utente appena creato in Auth
        auth.delete_user(user_record.uid)
        raise e