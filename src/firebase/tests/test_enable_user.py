import requests
import pytest

# The base URL for the emulated functions
BASE_URL = "http://127.0.0.1:5001/pmds-project-emulator/us-central1"

def test_enable_user_unauthorized():
    """Tests that the function requires authentication."""
    url = f"{BASE_URL}/enable_user"
    response = requests.post(url, json={"uid": "some-uid"})
    assert response.status_code == 401

def test_enable_user_forbidden_for_low_level_users():
    """Tests that a user with level < 2 cannot enable other users."""
    # This test requires a valid token from a non-admin user
    # Implementation depends on get_firebase_id_token fixture
    pass # Placeholder

def test_enable_user_success(create_user_in_emulator, get_firebase_id_token):
    """Tests that an admin can successfully enable a disabled user."""
    admin_email = "admin@test.com"
    admin_pass = "password"
    target_email = "target@test.com"
    target_pass = "password"
    
    # 1. Setup: Create an admin and a disabled target user
    admin_user = create_user_in_emulator(uid="admin001", email=admin_email, password=admin_pass, level=2)
    target_user = create_user_in_emulator(uid="target001", email=target_email, password=target_pass, level=1, disabled=True)

    # 2. Get admin's token
    admin_token = get_firebase_id_token(admin_email, admin_pass)
    headers = {"Authorization": f"Bearer {admin_token}"}

    # 3. Call the function
    url = f"{BASE_URL}/enable_user"
    response = requests.post(url, json={"uid": target_user.uid}, headers=headers)

    # 4. Assert
    assert response.status_code == 200
    assert f"Utente {target_user.uid} abilitato con successo!" in response.text

def test_enable_user_missing_uid():
    """Tests that the function returns 400 if 'uid' is missing."""
    # This test requires a valid admin token
    pass # Placeholder

def test_enable_user_user_not_found(create_user_in_emulator, get_firebase_id_token):
    """Tests that the function returns 404 if the target user doesn't exist."""
    admin_email = "admin@test.com"
    admin_pass = "password"
    
    create_user_in_emulator(uid="admin001", email=admin_email, password=admin_pass, level=2)
    admin_token = get_firebase_id_token(admin_email, admin_pass)
    headers = {"Authorization": f"Bearer {admin_token}"}

    url = f"{BASE_URL}/enable_user"
    response = requests.post(url, json={"uid": "non-existent-uid"}, headers=headers)

    assert response.status_code == 404
