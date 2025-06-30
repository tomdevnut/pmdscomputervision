from flask import Flask
from flask_bcrypt import Bcrypt
from flask_jwt_extended import JWTManager


def create_app():
    app = Flask(__name__)
    app.config.from_object('config.Config')

    try:
        cred = credentials.Certificate(app.config['FIREBASE_SERVICE_ACCOUNT_KEY_PATH'])
        firebase_admin.initialize_app(cred)
        db_firestore = firestore.client()
        print("Firebase Admin SDK initialized successfully.")
    except Exception as e:
        print(f"Error initializing Firebase Admin SDK: {e}")


    bcrypt = Bcrypt(app)
    jwt = JWTManager(app)


    from app import routes
    return app