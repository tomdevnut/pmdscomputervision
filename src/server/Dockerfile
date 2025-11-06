# Usa un'immagine base di Python
FROM python:3.12-slim

# Installa le dipendenze di sistema necessarie per OpenCV, CadQuery e librerie di computer vision
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    libgl1 \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender1 \
    libgomp1 \
    libglu1-mesa \
    libxi6 \
    libxmu6 \
    ffmpeg \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

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
CMD ["gunicorn", "--bind", "0.0.0.0:9999", "app:app"]