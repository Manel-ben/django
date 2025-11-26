# ÉTAPE 1 : BUILDER
# Utilise une image Python complète pour construire l'environnement et installer les dépendances.
FROM python:3.11 AS builder

# Définit la variable d'environnement pour ne pas écrire les fichiers .pyc
ENV PYTHONDONTWRITEBYTECODE 1
# Désactive la mise en mémoire tampon de la sortie standard et d'erreur pour les logs en temps réel
ENV PYTHONUNBUFFERED 1

# Définit le répertoire de travail dans le conteneur.
WORKDIR /usr/src/app

# Copie le fichier requirements.txt pour l'installation des dépendances.
# On copie uniquement ce fichier en premier pour profiter de la mise en cache de Docker.
COPY requirements.txt .

# Installe les dépendances dans le répertoire virtuel caché (__pypackages__).
# L'option --no-cache-dir réduit la taille de la couche.
RUN pip install --no-cache-dir -r requirements.txt

# ÉTAPE 2 : RUNTIME (IMAGE FINALE, LÉGÈRE)
# Utilise une image Python 'slim' qui est beaucoup plus petite pour la production.
FROM python:3.11-slim

# Définit à nouveau le répertoire de travail.
WORKDIR /usr/src/app

# Copie les dépendances installées par l'étape 'builder' vers le répertoire de travail.
# Cela garantit que toutes les bibliothèques sont présentes.
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages

# Copie le reste du code de l'application (le point . représente le dossier où se trouve le Dockerfile).
COPY . .

# Exécute la collecte des fichiers statiques de Django
# NOTE : Remplacez 'votre_projet' par le nom du dossier qui contient settings.py et wsgi.py
RUN python manage.py collectstatic --noinput

# Expose le port par défaut pour Gunicorn. Render utilisera de toute façon $PORT.
EXPOSE 8000

# Commande de démarrage du service Gunicorn.
# Vous DEVEZ remplacer 'votre_projet' par le nom du dossier qui contient votre wsgi.py (e.g., 'mysite').
# L'utilisation de 4 workers est un bon point de départ, ajustez selon la RAM disponible.
# La liaison à 0.0.0.0 permet d'écouter sur toutes les interfaces réseau.
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "4", "votre_projet.wsgi:application"]
