import requests

def test_change_password_success_by_admin(create_user_in_emulator, get_firebase_id_token, get_base_url):
    """Tests successful password change by an admin for another user."""
    admin_email = "admin-changepass@test.com"
    admin_pass = "password"
    create_user_in_emulator(uid="admin_cp_001", email=admin_email, password=admin_pass, level=2)
    
    target_email = "target.user@test.com"
    target_uid = "target_cp_001"
    target_pass = "oldpassword"
    create_user_in_emulator(uid=target_uid, email=target_email, password=target_pass, level=1)

    admin_token = get_firebase_id_token(admin_email, admin_pass)
    headers = {"Authorization": f"Bearer {admin_token}"}

    url = f"{get_base_url}/change_password"
    new_password = "newpassword"
    payload = {
        "uid": target_uid,
        "new_password": new_password
    }
    
    response = requests.post(url, json=payload, headers=headers)
    
    assert response.status_code == 200
    assert "Password aggiornata" in response.text

    # Verify old password no longer works
    old_password_works = True
    try:
        get_firebase_id_token(target_email, target_pass)
    except requests.exceptions.HTTPError as e:
        if e.response.status_code == 400:
            old_password_works = False
    
    assert not old_password_works, "Old password should not work anymore"

    # Verify new password works
    try:
        get_firebase_id_token(target_email, new_password)
    except requests.exceptions.HTTPError:
        assert False, "New password should work"


def test_change_password_unauthorized(get_base_url):
    """Tests that the function requires authentication."""
    url = f"{get_base_url}/change_password"
    response = requests.post(url, json={})
    assert response.status_code == 401

def test_change_password_forbidden(create_user_in_emulator, get_firebase_id_token, get_base_url):
    """Tests that a non-admin user cannot change passwords."""
    non_admin_email = "nonadmin@test.com"
    non_admin_pass = "password"
    non_admin_uid = "nonadmin_cp_001"
    create_user_in_emulator(uid=non_admin_uid, email=non_admin_email, password=non_admin_pass, level=1)

    target_email = "another.user@test.com"
    target_pass = "password"
    target_uid = "another_cp_001"
    create_user_in_emulator(uid=target_uid, email=target_email, password=target_pass, level=1)

    non_admin_token = get_firebase_id_token(non_admin_email, non_admin_pass)
    headers = {"Authorization": f"Bearer {non_admin_token}"}

    url = f"{get_base_url}/change_password"
    payload = {
        "uid": target_uid,
        "new_password": "newpassword"
    }
    
    response = requests.post(url, json=payload, headers=headers)
    
    assert response.status_code == 403

def test_change_password_user_not_found(create_user_in_emulator, get_firebase_id_token, get_base_url):
    """Tests changing password for a non-existent user."""
    admin_email = "admin-changepass-2@test.com"
    admin_pass = "password"
    create_user_in_emulator(uid="admin_cp_002", email=admin_email, password=admin_pass, level=2)
    
    admin_token = get_firebase_id_token(admin_email, admin_pass)
    headers = {"Authorization": f"Bearer {admin_token}"}

    url = f"{get_base_url}/change_password"
    payload = {
        "uid": "nonexistent_uid",
        "new_password": "newpassword"
    }
    
    response = requests.post(url, json=payload, headers=headers)
    
    assert response.status_code == 404
