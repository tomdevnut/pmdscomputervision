import requests
from firebase_admin import firestore

def test_save_fcm_token_success(create_user_in_emulator, get_firebase_id_token, get_base_url):
    """Tests that a user can save their FCM token."""
    user_email = "user@test.com"
    user_pass = "password"
    user = create_user_in_emulator(uid="user005", email=user_email, password=user_pass, level=1)
    
    user_token = get_firebase_id_token(user_email, user_pass)
    headers = {"Authorization": f"Bearer {user_token}"}

    url = f"{get_base_url}/save_fcm_token"
    fcm_token = "a_fake_fcm_token_string"
    response = requests.post(url, json={"fcm_token": fcm_token}, headers=headers)

    assert response.status_code == 200

    # Verify in Firestore
    db = firestore.client()
    doc = db.collection('users').document(user.uid).get()
    assert doc.to_dict().get("fcm_token") == fcm_token
