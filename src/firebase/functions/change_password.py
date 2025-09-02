import json
from firebase_admin import auth, firestore, messaging
from firebase_functions import https_fn, options
from config import MANAGE_USERS_MIN_LEVEL

@https_fn.on_request(cors_enabled=True)
def change_password(request: https_fn.Request) -> https_fn.Response:
    """
    Changes a user's password, revokes sessions, and sends a notification.
    This is invoked only by administrators to modify the password of other users.
    """
    if request.method == 'OPTIONS':
        return https_fn.Response(status=204)
        
    db = firestore.client()
    USERS_COLLECTION_REF = db.collection('users')

    # Authentication of the caller
    try:
        auth_header = request.headers.get('Authorization')
        if not auth_header or not auth_header.startswith('Bearer '):
            response_data = {'status': 'error', 'message': 'Unauthorized'}
            return https_fn.Response(json.dumps(response_data), status=401, mimetype='application/json')
            
        id_token = auth_header.split('Bearer ')[1]
        decoded_token = auth.verify_id_token(id_token)
        caller_uid = decoded_token['uid']
    except Exception as e:
        response_data = {'status': 'error', 'message': f'Unauthorized: {e}'}
        return https_fn.Response(json.dumps(response_data), status=401, mimetype='application/json')

    # Data parsing
    try:
        data = request.get_json()
        new_password = data.get('new_password')
        target_user_uid = data.get('uid')

        if not new_password or not target_user_uid:
            response_data = {'status': 'error', 'message': 'Bad Request: Missing new_password or uid.'}
            return https_fn.Response(json.dumps(response_data), status=400, mimetype='application/json')
    except Exception as e:
        response_data = {'status': 'error', 'message': f'Bad Request: Invalid JSON. {e}'}
        return https_fn.Response(json.dumps(response_data), status=400, mimetype='application/json')

    # Logic to change the password
    try:
        # Check caller's permission level
        caller_doc = USERS_COLLECTION_REF.document(caller_uid).get()
        if not caller_doc.exists or caller_doc.to_dict().get('level') < MANAGE_USERS_MIN_LEVEL:
            response_data = {'status': 'error', 'message': 'Forbidden: You do not have permission to change other users\' passwords.'}
            return https_fn.Response(json.dumps(response_data), status=403, mimetype='application/json')

        try:
            # Update password in Firebase Auth
            auth.update_user(target_user_uid, password=new_password)
        except auth.UserNotFoundError:
            response_data = {'status': 'error', 'message': f"User with UID '{target_user_uid}' not found."}
            return https_fn.Response(json.dumps(response_data), status=404, mimetype='application/json')

        # Revoke refresh tokens to force logout on all devices
        auth.revoke_refresh_tokens(target_user_uid)

        # Send PUSH notification to the user whose password was changed
        target_doc = USERS_COLLECTION_REF.document(target_user_uid).get()
        if target_doc.exists:
            fcm_token = target_doc.to_dict().get("fcm_token")
            if fcm_token:
                message = messaging.Message(
                    notification=messaging.Notification(
                        title="Session ended",
                        body="Your password has been changed by an administrator. Please log in again."
                    ),
                    token=fcm_token
                )
                try:
                    messaging.send(message)
                except Exception as e:
                    print(f"Error sending FCM notification to {target_user_uid}: {e}")

        response_data = {'status': 'success', 'message': 'Password updated and sessions revoked successfully.'}
        return https_fn.Response(json.dumps(response_data), status=200, mimetype='application/json')

    except Exception as e:
        print(f"Error during password change: {e}")
        response_data = {'status': 'error', 'message': f'Internal Server Error: {e}'}
        return https_fn.Response(json.dumps(response_data), status=500, mimetype='application/json')