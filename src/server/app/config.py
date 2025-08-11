import os
from google.cloud import secretmanager

# Inizializzo il client di Secret Manager al di fuori della classe per riutilizzarlo
client = secretmanager.SecretManagerServiceClient()

class Config:
    # ID del progetto GCP
    PROJECT_ID = os.environ.get('GCP_PROJECT_ID')

    # Chiave segreta per Flask
    # Chiave segreta per Flask
    FLASK_SECRET_KEY_NAME = 'flask-secret-key'
    SECRET_KEY = '' # Sarà popolata dal metodo get_secret    

    # Chiave API per la comunicazione sicura con la Cloud Function
    BACKEND_API_KEY_NAME = 'api-key-backend'
    BACKEND_API_KEY = '' # Sarà popolata dal metodo get_secret

    # Chiave di servizio di Firebase
    FIREBASE_SERVICE_ACCOUNT_KEY_NAME = 'backend-service-account-key'
    FIREBASE_SERVICE_ACCOUNT_KEY = '' # Sarà popolata dal metodo get_secret
    
    # Metodo per accedere a un secret da Secret Manager
    def get_secret(self, secret_id):
        try:
            name = f"projects/{self.PROJECT_ID}/secrets/{secret_id}/versions/latest"
            response = client.access_secret_version(request={"name": name})
            return response.payload.data.decode("UTF-8")
        except Exception as e:
            print(f"Errore nel recupero del secret '{secret_id}': {e}")
            return None

# Aggiungi l'inizializzazione al di fuori della classe per renderla accessibile
config = Config() # istanzio la classe una volta
Config.BACKEND_API_KEY = config.get_secret(config.BACKEND_API_KEY_NAME)
Config.FIREBASE_SERVICE_ACCOUNT_KEY = config.get_secret(config.FIREBASE_SERVICE_ACCOUNT_KEY_NAME)
Config.SECRET_KEY = config.get_secret(config.FLASK_SECRET_KEY_NAME)