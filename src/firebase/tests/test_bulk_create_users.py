import requests

def test_bulk_create_users_success(create_user_in_emulator, get_firebase_id_token, get_base_url):
    """Tests successful bulk user creation from a CSV file."""
    admin_email = "admin-bulk@test.com"
    admin_pass = "password"
    create_user_in_emulator(uid="admin_bulk_001", email=admin_email, password=admin_pass, level=1)
    
    admin_token = get_firebase_id_token(admin_email, admin_pass)
    headers = {"Authorization": f"Bearer {admin_token}"}

    url = f"{get_base_url}/bulk_create_users"
    
    # Create a CSV in memory
    csv_content = "email,password,level,name,surname\n"
    csv_content += "user1@test.com,password1,1,Name1,Surname1\n"
    csv_content += "user2@test.com,password2,1,Name2,Surname2\n"

    # Usa bytes per allinearti a file.read().decode('utf-8') lato server
    files = {'file': ('users.csv', csv_content.encode('utf-8'), 'text/csv')}
    
    response = requests.post(url, files=files, headers=headers)
    
    assert response.status_code == 200
    response_data = response.json()
    assert response_data['success_count'] == 2
    assert response_data['failure_count'] == 0
    assert len(response_data['created']) == 2
    assert response_data['created'][0]['email'] == 'user1@test.com'

def test_bulk_create_users_no_file(create_user_in_emulator, get_firebase_id_token, get_base_url):
    """Tests request without a file."""
    admin_email = "admin-bulk-2@test.com"
    admin_pass = "password"
    create_user_in_emulator(uid="admin_bulk_002", email=admin_email, password=admin_pass, level=1)

    admin_token = get_firebase_id_token(admin_email, admin_pass)
    headers = {"Authorization": f"Bearer {admin_token}"}

    url = f"{get_base_url}/bulk_create_users"
    
    response = requests.post(url, headers=headers)
    
    assert response.status_code == 400
    assert "File CSV non trovato" in response.text

def test_bulk_create_users_malformed_csv(create_user_in_emulator, get_firebase_id_token, get_base_url):
    """Tests request with a malformed CSV file."""
    admin_email = "admin-bulk-3@test.com"
    admin_pass = "password"
    create_user_in_emulator(uid="admin_bulk_003", email=admin_email, password=admin_pass, level=1)

    admin_token = get_firebase_id_token(admin_email, admin_pass)
    headers = {"Authorization": f"Bearer {admin_token}"}

    url = f"{get_base_url}/bulk_create_users"
    
    # CSV with a missing column
    csv_content = "email,password,level,name\n"
    csv_content += "user3@test.com,pass3,1,Name3\n"
    
    files = {'file': ('users.csv', csv_content.encode('utf-8'), 'text/csv')}
    
    response = requests.post(url, files=files, headers=headers)
    
    assert response.status_code == 200  # The function returns 200 even with failures
    response_data = response.json()
    assert response_data['success_count'] == 0
    assert response_data['failure_count'] == 1
    assert "surname" in response_data['failed'][0]['error'].lower()