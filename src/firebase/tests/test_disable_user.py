import requests
import pytest

BASE_URL = "http://127.0.0.1:5001/pmds-project/us-central1"

def test_disable_user_success(create_user_in_emulator, get_firebase_id_token):
    """Tests that an admin can successfully disable a user."""
    admin_email = "admin@test.com"
    admin_pass = "password"
    target_email = "target@test.com"
    target_pass = "password"
    
    admin_user = create_user_in_emulator(uid="admin002", email=admin_email, password=admin_pass, level=2)
    target_user = create_user_in_emulator(uid="target002", email=target_email, password=target_pass, level=1, disabled=False)

    admin_token = get_firebase_id_token(admin_email, admin_pass)
    headers = {"Authorization": f"Bearer {admin_token}"}

    url = f"{BASE_URL}/disable_user"
    response = requests.post(url, json={"uid": target_user.uid}, headers=headers)

    assert response.status_code == 200
    assert f"Utente {target_user.uid} disabilitato con successo!" in response.text

def test_disable_user_unauthorized():
    """Tests that the function requires authentication."""
    url = f"{BASE_URL}/disable_user"
    response = requests.post(url, json={"uid": "some-uid"})
    assert response.status_code == 401
