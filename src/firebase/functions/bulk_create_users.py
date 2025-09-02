import json
from firebase_admin import auth, firestore
from firebase_functions import https_fn, options
from config import SUPERUSER_ROLE_LEVEL
from _user_utils import create_user_in_firebase
import csv
import io

@https_fn.on_request(
    cors=options.CorsOptions(
        cors_origins=[r"firebase\.com$", r"https://flutter\.com"],
        cors_methods=["get", "post"],
    )
)
def bulk_create_users(req: https_fn.Request) -> https_fn.Response:
    """
    Creates users in bulk from a CSV file uploaded via an HTTP request.
    The CSV must contain the columns: email, password, level, name, surname.
    """
    db = firestore.client()

    # Authentication and Authorization Check
    try:
        auth_header = req.headers.get('Authorization')
        if not auth_header or not auth_header.startswith('Bearer '):
            response_data = {'status': 'error', 'message': 'Unauthorized'}
            return https_fn.Response(json.dumps(response_data), status=401, mimetype='application/json')
        
        id_token = auth_header.split('Bearer ')[1]
        decoded_token = auth.verify_id_token(id_token)
        caller_uid = decoded_token['uid']
        
        caller_doc = db.collection('users').document(caller_uid).get()
        if not caller_doc.exists or caller_doc.to_dict().get('level', 0) < SUPERUSER_ROLE_LEVEL:
            response_data = {'status': 'error', 'message': 'Forbidden: Insufficient privileges.'}
            return https_fn.Response(json.dumps(response_data), status=403, mimetype='application/json')
    except Exception as e:
        response_data = {'status': 'error', 'message': f'Unauthorized: Invalid token or expired token. Error: {e}'}
        return https_fn.Response(json.dumps(response_data), status=401, mimetype='application/json')

    # File Validation
    if 'file' not in req.files:
        response_data = {'status': 'error', 'message': 'CSV file not found in the request.'}
        return https_fn.Response(json.dumps(response_data), status=400, mimetype='application/json')

    file = req.files['file']
    
    # Read CSV content
    try:
        csv_content = file.read().decode('utf-8')
        csv_file = io.StringIO(csv_content)
        reader = csv.DictReader(csv_file)
    except Exception as e:
        response_data = {'status': 'error', 'message': f'Error reading CSV file: {e}'}
        return https_fn.Response(json.dumps(response_data), status=400, mimetype='application/json')

    created_users = []
    failed_users = []
    
    # Process each row in the CSV
    for row in reader:
        try:
            email = row['email']
            password = row['password']
            # Convert level to integer with error handling
            level_str = row.get('level', '0')
            if not level_str.isdigit():
                raise ValueError("Level must be an integer.")
            level = int(level_str)
            name = row['name']
            surname = row['surname']
            
            user_record = create_user_in_firebase(db, email, password, level, name, surname)
            created_users.append({'email': email, 'uid': user_record.uid})
        except KeyError as ke:
            failed_users.append({'email': row.get('email', 'N/A'), 'error': f'Missing value: {ke}'})
        except Exception as e:
            failed_users.append({'email': row.get('email', 'N/A'), 'error': f'{e}'})

    # Final response
    response_data = {
        'status': 'success',
        'message': 'User creation process completed.',
        'data': {
            'success_count': len(created_users),
            'failure_count': len(failed_users),
            'created_users': created_users,
            'failed_users': failed_users
        }
    }
    
    # Return 200 OK even if some users failed, as the overall process was successful.
    return https_fn.Response(
        json.dumps(response_data),
        status=200,
        mimetype="application/json"
    )