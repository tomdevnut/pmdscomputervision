from firebase_functions.options import set_global_options
from firebase_admin import initialize_app
import os

set_global_options(max_instances=10, region="europe-west3")

# Initialize the Firebase Admin SDK only if not in a test environment.
# Pytest sets the 'PYTEST_CURRENT_TEST' environment variable.
if "PYTEST_CURRENT_TEST" not in os.environ:
    initialize_app()

# Trigger fatto con Cloud Storage
from upload_step import upload_step
from delete_step import delete_step
from process_user_scan import process_user_scan
from delete_scan import delete_scan

# Trigger fatto con Firestore
from new_stats import new_stats

# Trigger fatto con HTTP
from clean_scans import clean_scans
from new_user import new_user
from enable_user import enable_user
from disable_user import disable_user
from delete_user import delete_user
from save_fcm_token import save_fcm_token
from bulk_create_users import bulk_create_users
from change_password import change_password
from get_all_pending import get_all_pending

# Lista di funzioni che verranno esportate (non necessaria per il funzionamento, ma utile per la documentazione)
__all__ = [
    "upload_step",
    "delete_step",
    "process_user_scan",
    "clean_scans",
    "new_user",
    "enable_user",
    "disable_user",
    "delete_user",
    "new_stats",
    "save_fcm_token",
    "delete_scan",
    "bulk_create_users",
    "change_password",
    "get_all_pending"
]