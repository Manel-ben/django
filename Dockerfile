# ÉTAPE 1 : BUILDER (Pour installer les dépendances et réduire la taille de l'image finale)
# Utilise une image Python complète pour construire l'environnement et installer les dépendances.
FROM python:3.11 AS builder

# Configuration de l'environnement Python
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# Définit le répertoire de travail dans le conteneur.
WORKDIR /usr/src/app

# Copie le fichier requirements.txt pour l'installation des dépendances.
# On copie uniquement ce fichier en premier pour profiter de la mise en cache de Docker.
COPY requirements.txt .

# Installe les dépendances. L'option --no-cache-dir réduit la taille de la couche.
RUN pip install --no-cache-dir -r requirements.txt

# ÉTAPE 2 : RUNTIME (IMAGE FINALE, LÉGÈRE ET OPTIMISÉE POUR LA PRODUCTION)
# Utilise une image Python 'slim' qui est beaucoup plus petite pour la production.
FROM python:3.11-slim

# Définit à nouveau le répertoire de travail.
WORKDIR /usr/src/app

# Copie les dépendances installées par l'étape 'builder' vers le répertoire de travail.
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages

# Copie le reste du code de l'application (tous les fichiers du répertoire où se trouve le Dockerfile).
COPY . .

# AJUSTEMENT CRUCIAL POUR L'EXÉCUTION DES COMMANDES DJANGO :
# Le module de settings est maintenant correctement défini :
ENV DJANGO_SETTINGS_MODULE=idlTp3.settings

# Exécute la collecte des fichiers statiques de Django.
# Cette étape ne devrait plus échouer grâce à la variable DJANGO_SETTINGS_MODULE.
RUN python manage.py collectstatic --noinput

# Expose le port par défaut pour Gunicorn (bien que Render utilise la variable $PORT).
EXPOSE 8000

# Commande de démarrage du service Gunicorn.
# Le chemin vers le fichier wsgi est corrigé :
# Utilise la variable d'environnement $PORT fournie par Render (ou par défaut 8000 si non définie)
CMD ["gunicorn", "--bind", "0.0.0.0:${PORT:-8000}", "--workers", "4", "idlTp3.wsgi:application"]
