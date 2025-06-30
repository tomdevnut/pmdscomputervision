from flask import Flask, request, render_template, jsonify
from flask_jwt_extended import create_access_token, jwt_required, get_jwt_identity
from app import app, bcrypt

@app.route('/')
def index():
    return render_template('')

@app.post('/create_user')
@jwt_required()
def create_user():
    data = request.get_json()
    username = data.get('username')
    password = data.get('password')

    if not username or not password:
        return jsonify({"msg": "Username and password are required"}), 400
    
    # Controllo se l'utente esiste già
    # @TODO: chiedere a Sola classe User

@app.post('/login')
def login():
    data = request.get_json()
    username = data.get('username')
    password = data.get('password')

    if not username or not password:
        return jsonify({"msg": "Username and password are required"}), 400
    
    # Hashiamo la password
    pw_hash = bcrypt.generate_password_hash(password)

    # Database query per verificare le credenziali (@TODO: vedere con Sola)
    user = User.query.filter_by(username=username).first()
    if user and user.check_password(password):
        # Le credenziali sono valide, crea un token di accesso
        access_token = create_access_token(identity=user.username)
        return jsonify(access_token=access_token), 200
    else:
        return jsonify({"msg": "Bad username or password"}), 401
    

    # Controlliamo se l'utente esiste nel database


    # Se l'utente esiste, creiamo un JWT e lo restituiamo
    # Se l'utente non esiste, restituiamo un errore
    
    return

@app.post('/logout')
@jwt_required()
def logout():
    # Per il logout, non è necessario fare nulla specifico con JWT
    # Il client può semplicemente eliminare il token
    return jsonify({"msg": "Logout successful"}), 200

@app.get('/api/steps_IDs')
@jwt_required()
def get_steps_IDs():
    current_user = get_jwt_identity()
    # Recupera gli ID dei passi dal database per l'utente corrente

@app.get('/api/processing_state')


@app.get('/api/server_mesh_download')


# Understand how to send BIG DATA
@app.post('/api/client_object_creation')

@app.post('/api/client_scan_upload')

@app.post('/api/client_step_upload')

@app.post('/api/client_scan_delete')

@app.post('/api/client_step_delete')


# class User(db.Model):
#     id = Column(Integer, primary_key=True)
#     username = Column(String(20), unique=True, nullable=False)
#     password = Column(String(60), nullable=False) # La password hashata

#     def __repr__(self):
#         return f"User('{self.username}')"

#     def set_password(self, password):
#         self.password = bcrypt.generate_password_hash(password).decode('utf-8')

#     def check_password(self, password):
#         return bcrypt.check_password_hash(self.password, password)