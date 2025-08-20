import requests

def test_clean_scans_unauthorized(get_base_url):
    """Tests that the function requires authentication."""
    url = f"{get_base_url}/clean_scans"
    response = requests.post(url, json={})
    assert response.status_code == 401

def test_clean_scans_success_as_admin(create_user_in_emulator, get_firebase_id_token, get_base_url):
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
    url = f"{get_base_url}/clean_scans"
    response = requests.post(url, json={}, headers=headers)

    # 4. Assert
    assert response.status_code == 200
