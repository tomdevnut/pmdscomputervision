import os
import json

_secret_manager_client = None

def _get_secret_manager_client():
    """Restituisce il Secret Manager"""
    global _secret_manager_client
    if _secret_manager_client is None:
        try:
            from google.cloud import secretmanager
            _secret_manager_client = secretmanager.SecretManagerServiceClient()
        except Exception as e:
            print(f"Impossibile inizializzare il client di Secret Manager: {e}")
            return None
    return _secret_manager_client

def _read_secret(secret_id: str) -> str | None:
    """Legge un secret da Secret Manager."""
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
        print(f"Errore nel leggere il segreto '{secret_id}': {e}")
        return None

class Config:
    """Configurazione dell'applicazione"""
    # TODO: controllo
    SECRET_KEY = (
        os.getenv("SECRET_KEY")
        or _read_secret("flask-secret-key")
        or "valore-segreto-sviluppo" 
    )
    API_KEY_BACKEND = (
        os.getenv("API_KEY_BACKEND")
        or _read_secret("api-key-backend")
        or "" # In sviluppo ci potrebbe interessare avere la chiave vuota per fase di testig
    )
    FIREBASE_SERVICE_ACCOUNT_KEY = (
        os.getenv("FIREBASE_SERVICE_ACCOUNT_KEY")
        or _read_secret("backend-service-account-key")
        or ""
    )