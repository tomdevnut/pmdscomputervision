import os

class Config:
    # Configurazione per il database SQL di Flask (per username/password)
    SQLALCHEMY_DATABASE_URI = 'sqlite:///site.db'
    SQLALCHEMY_TRACK_MODIFICATIONS = False

    # Chiave segreta per Flask
    SECRET_KEY = os.environ.get('SECRET_KEY') or 'un_segreto_molto_segreto_e_lungo_e_complesso_per_flask'
    # Chiave segreta per i JWT
    JWT_SECRET_KEY = os.environ.get('JWT_SECRET_KEY') or 'un_altro_segreto_jwt_molto_segreto_e_lungo_e_complesso'