import requests
import json
import pytest
import os

# Assuming these fixtures are provided by your test environment (e.g., conftest.py)
# from tests.conftest import create_user_in_emulator, get_firebase_id_token, get_base_url

def test_bulk_create_users_success(create_user_in_emulator, get_firebase_id_token, get_base_url):
    """
    Tests successful bulk user creation from a CSV file, asserting on the new
    standardized JSON response format.
    """
    admin_email = "admin-bulk-1@test.com"
    admin_pass = "password"
    create_user_in_emulator(uid="admin_bulk_001", email=admin_email, password=admin_pass, level=1)
    
    admin_token = get_firebase_id_token(admin_email, admin_pass)
    headers = {"Authorization": f"Bearer {admin_token}"}

    url = f"{get_base_url}/bulk_create_users"
    
    # Create a CSV in memory with valid user data
    csv_content = "email,password,level,name,surname\n"
    csv_content += "user1@test.com,password1,1,Name1,Surname1\n"
    csv_content += "user2@test.com,password2,1,Name2,Surname2\n"

    files = {'file': ('users.csv', csv_content.encode('utf-8'), 'text/csv')}
    
    response = requests.post(url, files=files, headers=headers)
    
    assert response.status_code == 200
    response_data = response.json()
    
    # Assert on the new JSON structure and data
    assert response_data['status'] == 'success'
    assert 'User creation process completed.' in response_data['message']
    
    data = response_data['data']
    assert data['success_count'] == 2
    assert data['failure_count'] == 0
    assert len(data['created_users']) == 2
    assert data['created_users'][0]['email'] == 'user1@test.com'
    assert len(data['failed_users']) == 0

def test_bulk_create_users_no_file(create_user_in_emulator, get_firebase_id_token, get_base_url):
    """
    Tests a request without a file, asserting on the 400 Bad Request status
    and the new JSON error format.
    """
    admin_email = "admin-bulk-2@test.com"
    admin_pass = "password"
    create_user_in_emulator(uid="admin_bulk_002", email=admin_email, password=admin_pass, level=1)

    admin_token = get_firebase_id_token(admin_email, admin_pass)
    headers = {"Authorization": f"Bearer {admin_token}"}

    url = f"{get_base_url}/bulk_create_users"
    
    response = requests.post(url, headers=headers)
    
    assert response.status_code == 400
    response_data = response.json()
    
    # Assert on the new JSON error structure
    assert response_data['status'] == 'error'
    assert "CSV file not found in the request." in response_data['message']

def test_bulk_create_users_malformed_csv(create_user_in_emulator, get_firebase_id_token, get_base_url):
    """
    Tests a request with a malformed CSV file, asserting on the new JSON
    structure for partial success/failure.
    """
    admin_email = "admin-bulk-3@test.com"
    admin_pass = "password"
    create_user_in_emulator(uid="admin_bulk_003", email=admin_email, password=admin_pass, level=1)

    admin_token = get_firebase_id_token(admin_email, admin_pass)
    headers = {"Authorization": f"Bearer {admin_token}"}

    url = f"{get_base_url}/bulk_create_users"
    
    # CSV with a missing 'surname' column
    csv_content = "email,password,level,name\n"
    csv_content += "user3@test.com,pass3,1,Name3\n"
    
    files = {'file': ('users.csv', csv_content.encode('utf-8'), 'text/csv')}
    
    response = requests.post(url, files=files, headers=headers)
    
    assert response.status_code == 200
    response_data = response.json()
    
    # Assert on the new JSON structure for partial failure
    assert response_data['status'] == 'success'
    assert 'User creation process completed.' in response_data['message']
    
    data = response_data['data']
    assert data['success_count'] == 0
    assert data['failure_count'] == 1
    assert len(data['failed_users']) == 1

    failed_user = data['failed_users'][0]
    assert failed_user['email'] == 'user3@test.com'
    assert "Missing value: 'surname'" in failed_user['error']