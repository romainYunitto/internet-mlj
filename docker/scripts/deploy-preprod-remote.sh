#!/bin/bash

# Script de déploiement pour préprod sur serveur distant
set -e

SERVER_HOST="votre-serveur-preprod.com"
SERVER_USER="votre-utilisateur"
REMOTE_PATH="/home/votre-utilisateur/drupal"

echo "🚀 Déploiement de l'environnement préprod sur serveur distant..."

# Création du répertoire temporaire pour les fichiers à transférer
TEMP_DIR=$(mktemp -d)
echo "📁 Création du répertoire temporaire: $TEMP_DIR"

# Copie des fichiers nécessaires
mkdir -p "$TEMP_DIR/docker/preprod"
cp docker/docker-compose.base.yml "$TEMP_DIR/docker/"
cp docker/preprod/docker-compose.yml "$TEMP_DIR/docker/preprod/"
cp docker/preprod/.env "$TEMP_DIR/docker/preprod/"

# Copie du code source (sans vendor et autres dossiers inutiles)
rsync -av --exclude='vendor/' --exclude='web/sites/default/files/' --exclude='.git/' . "$TEMP_DIR/"

# Transfert vers le serveur
echo "📤 Transfert des fichiers vers le serveur..."
rsync -avz --delete "$TEMP_DIR/" "$SERVER_USER@$SERVER_HOST:$REMOTE_PATH/"

# Commandes à exécuter sur le serveur distant
echo "🔧 Exécution des commandes sur le serveur distant..."
ssh "$SERVER_USER@$SERVER_HOST" << 'ENDSSH'
cd /home/votre-utilisateur/drupal

# Arrêt des conteneurs existants
sudo docker compose -f docker/preprod/docker-compose.yml --env-file docker/preprod/.env down || true

# Pull des images
sudo docker compose -f docker/preprod/docker-compose.yml --env-file docker/preprod/.env pull

# Démarrage des conteneurs
sudo docker compose -f docker/preprod/docker-compose.yml --env-file docker/preprod/.env up -d

# Vérification
sudo docker compose -f docker/preprod/docker-compose.yml --env-file docker/preprod/.env ps
ENDSSH

# Nettoyage
rm -rf "$TEMP_DIR"

echo "✅ Déploiement terminé !"
echo "🌐 Application accessible sur: http://$SERVER_HOST:8002"