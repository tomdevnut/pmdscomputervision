from firebase_admin import auth, firestore
from firebase_functions import https_fn
from config import SUPERUSER_ROLE_LEVEL
from _user_utils import create_user_in_firebase
import csv
import io

@https_fn.on_request(cors=True)
def bulk_create_users(req: https_fn.Request) -> https_fn.Response:
    """
    Crea utenti in blocco da un file CSV caricato.
    Il CSV deve contenere le colonne: email, password, level, name, surname.
    """
    # Autenticazione del chiamante (deve essere un admin)
    try:
        auth_header = req.headers.get('Authorization')
        if not auth_header or not auth_header.startswith('Bearer '):
            return https_fn.Response('Unauthorized', status=401)
        id_token = auth_header.split('Bearer ')[1]
        decoded_token = auth.verify_id_token(id_token)
        caller_uid = decoded_token['uid']
        
        db = firestore.client()
        caller_doc = db.collection('users').document(caller_uid).get()
        if not caller_doc.exists or caller_doc.to_dict().get('level') < SUPERUSER_ROLE_LEVEL:
            return https_fn.Response('Forbidden: Non hai i permessi per eseguire questa operazione.', status=403)

    except Exception as e:
        return https_fn.Response(f'Unauthorized: {e}', status=401)

    if 'file' not in req.files:
        return https_fn.Response("File CSV non trovato nella richiesta.", status=400)

    file = req.files['file']
    
    # Legge il contenuto del file in memoria
    try:
        csv_content = file.read().decode('utf-8')
        csv_file = io.StringIO(csv_content)
        reader = csv.DictReader(csv_file)
    except Exception as e:
        return https_fn.Response(f"Errore nella lettura del file CSV: {e}", status=400)

    created_users = []
    failed_users = []

    for row in reader:
        try:
            email = row['email']
            password = row['password']
            level = int(row['level'])
            name = row['name']
            surname = row['surname']

            # Usa la funzione helper per creare l'utente
            user_record = create_user_in_firebase(db, email, password, level, name, surname)

            created_users.append({'email': email, 'uid': user_record.uid})

        except Exception as e:
            failed_users.append({'email': row.get('email', 'N/A'), 'error': str(e)})

    return https_fn.Response({
        "message": "Processo di creazione utenti completato.",
        "success_count": len(created_users),
        "failure_count": len(failed_users),
        "created": created_users,
        "failed": failed_users
    }, status=200, mimetype="application/json")