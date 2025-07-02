from app import create_app
from path import CERT_PATH, KEY_PATH

app = create_app()

if __name__ == '__main__':
        app.run(debug=True, ssl_context=(CERT_PATH, KEY_PATH))