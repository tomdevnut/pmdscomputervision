import requests
import firebase_admin.firestore as firestore

def test_new_user_success(create_user_in_emulator, get_firebase_id_token, get_base_url):
    """Tests successful creation of a new user by an admin."""
    admin_email = "admin@test.com"
    admin_pass = "password"
    create_user_in_emulator(uid="admin004", email=admin_email, password=admin_pass, level=2)
    
    admin_token = get_firebase_id_token(admin_email, admin_pass)
    headers = {"Authorization": f"Bearer {admin_token}"}

    url = f"{get_base_url}/new_user"
    payload = {
        "email": "new.user@test.com",
        "password": "newpassword",
        "level": 1,
        "name": "New",
        "surname": "User"
    }
    response = requests.post(url, json=payload, headers=headers)

    assert response.status_code == 200

def test_new_user_unauthorized(get_base_url):
    """Tests that the function requires authentication."""
    url = f"{get_base_url}/new_user"
    response = requests.post(url, json={})
    assert response.status_code == 401
