FROM python:3.11-slim

WORKDIR /app

# Installation des dépendances système
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copie des requirements
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copie du code
COPY . .

# Création du répertoire de logs
RUN mkdir -p /var/log/mdm-integration

# Script de démarrage
CMD ["python", "mdm_sync.py"]
