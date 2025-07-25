import requests
import pytest

BASE_URL = "http://127.0.0.1:5001/pmds-project/us-central1"

def test_clean_scans_unauthorized():
    """Tests that the function requires authentication."""
    url = f"{BASE_URL}/clean_scans"
    response = requests.post(url, json={})
    assert response.status_code == 401

def test_clean_scans_success_as_admin(create_user_in_emulator, get_firebase_id_token):
    """
    Tests that an admin can successfully trigger the clean_scans function.
    Note: This test only checks for a successful response (200 OK).
    A more thorough test would involve creating old scan data and verifying
    that it gets deleted.
    """
    # 1. Setup: Create an admin user
    admin_email = "admin_cleaner@test.com"
    admin_pass = "password"
    create_user_in_emulator(uid="admin_cleaner_001", email=admin_email, password=admin_pass, level=2)

    # 2. Get admin's token
    admin_token = get_firebase_id_token(admin_email, admin_pass)
    headers = {"Authorization": f"Bearer {admin_token}"}

    # 3. Call the function
    url = f"{BASE_URL}/clean_scans"
    # The function might take parameters like `days_old`, sending an empty
    # payload to use the function's default behavior.
    response = requests.post(url, json={}, headers=headers)

    # 4. Assert
    assert response.status_code == 200
    # The response text should indicate success, e.g., "Scan cleanup started."
    # This depends on the actual implementation of the function.
    assert "Pulizia completata con successo!" in response.text.lower()
