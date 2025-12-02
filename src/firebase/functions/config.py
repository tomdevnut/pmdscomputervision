import os

# Storage
BUCKET_NAME: str = os.getenv("FIREBASE_STORAGE_BUCKET", "pmds-project.firebasestorage.app")

# BACKEND
BACKEND_API_KEY_SECRET_NAME = "api-key-backend"

# SERVICE ACCOUNT
SERVICE_ACCOUNT = "backend-service-account-key"

BACKEND_SERVER_URL = "93.66.235.232:9999"

# Ruoli / Autorizzazioni
SUPERUSER_ROLE_LEVEL: int = 1
MANAGE_USERS_MIN_LEVEL: int = 2 

# GCP
PROJECT_ID = "pmds-project"