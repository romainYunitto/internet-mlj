#!/bin/bash

# Script pour synchroniser uniquement les fichiers nécessaires pour recette
set -e

if [ $# -eq 0 ]; then
    echo "Usage: $0 <utilisateur@serveur>"
    echo "Exemple: $0 user@recette.example.com"
    exit 1
fi

SERVER="$1"
REMOTE_PATH="/home/$(echo $SERVER | cut -d'@' -f1)/drupal-recette"

echo "🔄 Synchronisation des fichiers recette vers $SERVER..."

# Fichiers Docker spécifiques à recette
echo "📁 Synchronisation de la configuration Docker..."
rsync -avz docker/docker-compose.base.yml "$SERVER:$REMOTE_PATH/docker/"
rsync -avz docker/recette/ "$SERVER:$REMOTE_PATH/docker/recette/"

# Code source (sans les gros dossiers)
echo "📁 Synchronisation du code source..."
rsync -avz \
    --exclude='vendor/' \
    --exclude='web/sites/default/files/' \
    --exclude='.git/' \
    --exclude='docker/local/' \
    --exclude='docker/preprod/' \
    --exclude='docker/production/' \
    --exclude='node_modules/' \
    . "$SERVER:$REMOTE_PATH/"

echo "✅ Synchronisation terminée !"
echo "💡 Connectez-vous au serveur et exécutez :"
echo "   cd $REMOTE_PATH"
echo "   docker-compose -f docker/recette/docker-compose.yml --env-file docker/recette/.env up -d"