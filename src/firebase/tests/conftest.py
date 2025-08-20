import pytest
import firebase_admin
from firebase_admin import firestore, auth, storage
import os
import requests

# --- Emulator Configuration ---
os.environ["FIREBASE_AUTH_EMULATOR_HOST"] = "127.0.0.1:9099"
os.environ["FIRESTORE_EMULATOR_HOST"] = "127.0.0.1:8080"
os.environ["STORAGE_EMULATOR_HOST"] = "http://127.0.0.1:9199"
PROJECT_ID = "pmds-project"
BUCKET_NAME = "pmds-project.firebasestorage.app"
BASE_URL = "http://127.0.0.1:5001/pmds-project/us-central1"

@pytest.fixture(scope="session", autouse=True)
def firebase_emulator_setup():
    """
    Initializes the Firebase Admin SDK to connect to the local emulators.
    This fixture runs once per test session.
    """
    if not firebase_admin._apps:
        firebase_admin.initialize_app(options={
            'projectId': PROJECT_ID,
            'storageBucket': BUCKET_NAME
        })
    yield


@pytest.fixture(autouse=True)
def clear_emulator_data():
    """
    Clears all data from Auth, Firestore, and Storage emulators before each test.
    This ensures that tests run in a clean, predictable environment.
    """
    # Clear Firestore
    db = firestore.client()
    for collection in db.collections():
        for doc in collection.stream():
            doc.reference.delete()

    # Clear Auth
    users = auth.list_users().iterate_all()
    uids_to_delete = [user.uid for user in users]
    if uids_to_delete:
        auth.delete_users(uids_to_delete)

    # Clear Storage
    bucket = storage.bucket(BUCKET_NAME)
    blobs = list(bucket.list_blobs())
    for blob in blobs:
        blob.delete()


@pytest.fixture
def create_user_in_emulator():
    """
    A factory fixture to create users in the Auth and Firestore emulators.
    Returns a function that can be called within tests to set up user data.
    """
    def _create_user(uid, email, password, level, disabled=False, name="Test", surname="User"):
        # Create user in Firebase Authentication
        user_record = auth.create_user(
            uid=uid,
            email=email,
            password=password,
            disabled=disabled
        )
        # Create user profile in Firestore
        db = firestore.client()
        db.collection('users').document(uid).set({
            'level': level,
            'enabled': not disabled,
            'name': name,
            'surname': surname,
            'email': email
        })
        return user_record
    return _create_user


@pytest.fixture
def get_firebase_id_token():
    """
    Logs in a user via the emulator's REST API and returns a valid ID token.
    This is necessary for testing functions that require authentication.
    """
    def _get_token(email, password):
        rest_api_url = f"http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=fake-api-key"
        payload = {
            "email": email,
            "password": password,
            "returnSecureToken": True
        }
        try:
            response = requests.post(rest_api_url, json=payload)
            response.raise_for_status()
            return response.json()["idToken"]
        except requests.exceptions.RequestException as e:
            pytest.fail(f"Failed to get ID token for {email}: {e.response.text if e.response else e}")

    return _get_token

@pytest.fixture(scope="session")
def get_storage_bucket_name():
    return BUCKET_NAME

@pytest.fixture(scope="session")
def get_base_url():
    return BASE_URL