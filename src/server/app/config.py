import os
import json
from flask import current_app as app

_secret_manager_client = None

def _get_secret_manager_client():
    """Returns the Secret Manager client, initializing it if necessary."""
    global _secret_manager_client
    if _secret_manager_client is None:
        try:
            from google.cloud import secretmanager
            _secret_manager_client = secretmanager.SecretManagerServiceClient()
        except Exception as e:
            app.logger.error(f"Unable to initialize Secret Manager client: {e}")
            return None
    return _secret_manager_client

def _read_secret(secret_id: str) -> str | None:
    """Reads a secret from Secret Manager."""
    use_sm = os.getenv("USE_SECRET_MANAGER", "false").lower() in ("true", "1", "yes")
    if not use_sm:
        return None

    project_id = os.getenv("GCP_PROJECT_ID")
    client = _get_secret_manager_client()
    if not client:
        return None

    try:
        name = f"projects/{project_id}/secrets/{secret_id}/versions/latest"
        response = client.access_secret_version(name=name)
        return response.payload.data.decode("UTF-8")
    except Exception as e:
        app.logger.error(f"Error reading secret '{secret_id}': {e}")
        return None

class Config:
    """Application configuration"""
    SECRET_KEY = (
        os.getenv("SECRET_KEY")
        or _read_secret("flask-secret-key")
        or "valore-segreto-sviluppo" 
    )
    API_KEY_BACKEND = (
        os.getenv("API_KEY_BACKEND")
        or _read_secret("api-key-backend")
        or ""
    )
    FIREBASE_SERVICE_ACCOUNT_KEY = (
        os.getenv("FIREBASE_SERVICE_ACCOUNT_KEY")
        or _read_secret("backend-service-account-key")
        or ""
    )