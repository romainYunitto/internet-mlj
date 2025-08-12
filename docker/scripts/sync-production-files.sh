#!/bin/bash

# Script pour synchroniser uniquement les fichiers nécessaires pour production
set -e

if [ $# -eq 0 ]; then
    echo "Usage: $0 <utilisateur@serveur>"
    echo "Exemple: $0 user@production.example.com"
    exit 1
fi

SERVER="$1"
REMOTE_PATH="/home/$(echo $SERVER | cut -d'@' -f1)/drupal-production"

echo "🔄 Synchronisation des fichiers PRODUCTION vers $SERVER..."

# Confirmation pour la production
read -p "⚠️  Vous synchronisez vers la PRODUCTION. Continuer ? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Synchronisation annulée"
    exit 1
fi

# Vérification de la connexion
echo "🔍 Vérification de la connexion..."
if ! ssh -o ConnectTimeout=10 "$SERVER" "echo 'Connexion OK'" > /dev/null 2>&1; then
    echo "❌ Impossible de se connecter au serveur"
    exit 1
fi

# Fichiers Docker spécifiques à production
echo "📁 Synchronisation de la configuration Docker..."
rsync -avz docker/docker-compose.base.yml "$SERVER:$REMOTE_PATH/docker/"
rsync -avz docker/production/ "$SERVER:$REMOTE_PATH/docker/production/"

# Code source (sans les gros dossiers et sans les autres environnements)
echo "📁 Synchronisation du code source..."
rsync -avz \
    --exclude='vendor/' \
    --exclude='web/sites/default/files/' \
    --exclude='.git/' \
    --exclude='docker/local/' \
    --exclude='docker/recette/' \
    --exclude='docker/preprod/' \
    --exclude='node_modules/' \
    --exclude='*.log' \
    --exclude='tmp/' \
    . "$SERVER:$REMOTE_PATH/"

echo "✅ Synchronisation vers PRODUCTION terminée !"
echo "💡 Connectez-vous au serveur et exécutez :"
echo "   cd $REMOTE_PATH"
echo "   # Sauvegarde avant mise à jour :"
echo "   mkdir -p backups && docker exec mariadb_prod mysqldump -u root -p\$DB_ROOT_PASSWORD drupal_prod > backups/backup_\$(date +%Y%m%d_%H%M%S).sql"
echo "   # Déploiement :"
echo "   docker-compose -f docker/production/docker-compose.yml --env-file docker/production/.env up -d"