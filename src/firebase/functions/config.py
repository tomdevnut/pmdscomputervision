import os

# Storage
BUCKET_NAME: str = os.getenv("FIREBASE_STORAGE_BUCKET", "pmds-project.firebasestorage.app")

# BACKEND
BACKEND_API_KEY_SECRET_NAME = "api-key-backend"
# TODO: Definire l'URL del server di backend
BACKEND_SERVER_URL = "https://server.com/api/scans"

# Ruoli / Autorizzazioni
# TODO: Definire il ruolo minimo richiesto per eseguire la pulizia (0 è l'utente normale, 1 è l'ingegnere, 2 è l'amministratore)
SUPERUSER_ROLE_LEVEL: int = 1
MANAGE_USERS_MIN_LEVEL: int = 2 

# TODO: aggiungere altre configurazioni? Magari i prefissi dei percorsi dei file?