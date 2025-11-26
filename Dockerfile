# ÉTAPE 1 : BUILDER (Préparation des dépendances binaires pour psycopg2)
# Utilise une image Python slim comme base de construction pour une taille optimisée.
FROM python:3.11-slim AS build

# Installation des outils de compilation et des headers PostgreSQL
# build-essential et libpq-dev sont nécessaires pour compiler psycopg2
WORKDIR /app
RUN apt-get update && \
    apt-get install -y build-essential libpq-dev gcc && \
    rm -rf /var/lib/apt/lists/*

# Copie et création des roues (wheels)
COPY requirements.txt .
RUN pip install --upgrade pip
# La commande 'pip wheel' pré-compile les paquets (comme psycopg2) dans le répertoire /wheels
RUN pip wheel --no-cache-dir -r requirements.txt -w /wheels


# ÉTAPE 2 : RUNTIME (Image finale légère et sécurisée)
# Utilise l'image slim pour une taille réduite en production.
FROM python:3.11-slim

# Configuration de l'environnement Python
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

WORKDIR /usr/src/app

# Installation des bibliothèques clientes PostgreSQL (libpq5 est nécessaire à l'exécution)
RUN apt-get update && \
    apt-get install -y libpq5 && \
    rm -rf /var/lib/apt/lists/*

# Copie des fichiers de l'étape de construction :
# 1. Copie des roues (wheels) pré-compilées
COPY --from=build /wheels /wheels
# 2. Copie du fichier requirements.txt
COPY requirements.txt . 

# Installation des paquets depuis les roues locales
# --no-index et --find-links garantissent l'utilisation des roues pré-compilées (FIX de l'erreur précédente)
RUN pip install --no-cache-dir --no-index --find-links=/wheels -r requirements.txt 

# Copie du code source de l'application
COPY . .

# Configuration de l'environnement Django
# Définit le module de settings (idlTp3)
ENV DJANGO_SETTINGS_MODULE=idlTp3.settings
# Variable pour ignorer les erreurs de connexion DB pendant collectstatic (Nécessite la logique dans settings.py)
ENV COLLECTSTATIC_IGNORE_DB=True

# Collecte des fichiers statiques (doit se faire avant le lancement du serveur)
RUN python manage.py collectstatic --noinput

EXPOSE 8000

# Commande de démarrage Gunicorn
# Utilise la variable d'environnement $PORT fournie par Render ou par défaut 8000
CMD ["gunicorn", "--bind", "0.0.0.0:${PORT:-8000}", "--workers", "4", "idlTp3.wsgi:application"]
