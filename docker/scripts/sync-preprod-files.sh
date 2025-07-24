#!/bin/bash

# Script pour synchroniser uniquement les fichiers nécessaires pour préprod
set -e

if [ $# -eq 0 ]; then
    echo "Usage: $0 <utilisateur@serveur>"
    echo "Exemple: $0 user@preprod.example.com"
    exit 1
fi

SERVER="$1"
REMOTE_PATH="/home/$(echo $SERVER | cut -d'@' -f1)/drupal-preprod"

echo "🔄 Synchronisation des fichiers préprod vers $SERVER..."

# Fichiers Docker spécifiques à préprod
echo "📁 Synchronisation de la configuration Docker..."
rsync -avz docker/docker-compose.base.yml "$SERVER:$REMOTE_PATH/docker/"
rsync -avz docker/preprod/ "$SERVER:$REMOTE_PATH/docker/preprod/"

# Code source (sans les gros dossiers)
echo "📁 Synchronisation du code source..."
rsync -avz \
    --exclude='vendor/' \
    --exclude='web/sites/default/files/' \
    --exclude='.git/' \
    --exclude='docker/local/' \
    --exclude='docker/recette/' \
    --exclude='docker/production/' \
    --exclude='node_modules/' \
    . "$SERVER:$REMOTE_PATH/"

echo "✅ Synchronisation terminée !"
echo "💡 Connectez-vous au serveur et exécutez :"
echo "   cd $REMOTE_PATH"
echo "   docker-compose -f docker/preprod/docker-compose.yml --env-file docker/preprod/.env up -d"