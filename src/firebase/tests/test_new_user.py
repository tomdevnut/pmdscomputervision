import requests
import pytest

BASE_URL = "http://127.0.0.1:5001/pmds-project/us-central1"

def test_new_user_success(create_user_in_emulator, get_firebase_id_token):
    """Tests successful creation of a new user by an admin."""
    admin_email = "admin@test.com"
    admin_pass = "password"
    create_user_in_emulator(uid="admin004", email=admin_email, password=admin_pass, level=2)
    
    admin_token = get_firebase_id_token(admin_email, admin_pass)
    headers = {"Authorization": f"Bearer {admin_token}"}

    url = f"{BASE_URL}/new_user"
    payload = {
        "email": "new.user@test.com",
        "password": "newpassword",
        "level": 1,
        "name": "New",
        "surname": "User"
    }
    response = requests.post(url, json=payload, headers=headers)

    assert response.status_code == 200
    assert "Utente creato con successo" in response.json()["message"]

def test_new_user_unauthorized():
    """Tests that the function requires authentication."""
    url = f"{BASE_URL}/new_user"
    response = requests.post(url, json={})
    assert response.status_code == 401
