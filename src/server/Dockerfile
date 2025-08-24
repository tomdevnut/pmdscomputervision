# Usa un'immagine base di Python
FROM python:3.12-slim
RUN apt-get update && apt-get upgrade -y

# Imposta la directory di lavoro all'interno del container
WORKDIR /app

# Copia i requisiti e installali
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copia il resto del codice sorgente nella directory di lavoro
COPY . .

# Espone la porta su cui l'app sarà in ascolto
EXPOSE 5000

# Comando per avviare l'applicazione
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "app:app"]