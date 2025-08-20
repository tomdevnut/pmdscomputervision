import requests

def test_delete_user_success(create_user_in_emulator, get_firebase_id_token, get_base_url):
    """Tests that an admin can successfully delete a user."""
    admin_email = "admin@test.com"
    admin_pass = "password"
    target_email = "target@test.com"
    target_pass = "password"
    
    create_user_in_emulator(uid="admin003", email=admin_email, password=admin_pass, level=2)
    target_user = create_user_in_emulator(uid="target003", email=target_email, password=target_pass, level=1)

    admin_token = get_firebase_id_token(admin_email, admin_pass)
    headers = {"Authorization": f"Bearer {admin_token}"}

    url = f"{get_base_url}/delete_user"
    response = requests.post(url, json={"uid": target_user.uid}, headers=headers)

    assert response.status_code == 200

def test_delete_user_unauthorized(get_base_url):
    """Tests that the function requires authentication."""
    url = f"{get_base_url}/delete_user"
    response = requests.post(url, json={"uid": "some-uid"})
    assert response.status_code == 401
