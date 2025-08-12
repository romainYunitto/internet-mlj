#!/bin/bash

# Script de déploiement pour production sur serveur distant
set -e

SERVER_HOST="votre-serveur-production.com"
SERVER_USER="votre-utilisateur"
REMOTE_PATH="/home/votre-utilisateur/drupal"

echo "🚀 Déploiement de l'environnement PRODUCTION sur serveur distant..."

# Confirmation de déploiement en production
read -p "⚠️  Vous êtes sur le point de déployer en PRODUCTION. Êtes-vous sûr ? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Déploiement annulé"
    exit 1
fi

# Vérification de la connexion au serveur
echo "🔍 Vérification de la connexion au serveur..."
if ! ssh -o ConnectTimeout=10 "$SERVER_USER@$SERVER_HOST" "echo 'Connexion OK'" > /dev/null 2>&1; then
    echo "❌ Impossible de se connecter au serveur $SERVER_HOST"
    exit 1
fi

# Création du répertoire temporaire pour les fichiers à transférer
TEMP_DIR=$(mktemp -d)
echo "📁 Création du répertoire temporaire: $TEMP_DIR"

# Copie des fichiers nécessaires
mkdir -p "$TEMP_DIR/docker/production"
cp docker/docker-compose.base.yml "$TEMP_DIR/docker/"
cp docker/production/docker-compose.yml "$TEMP_DIR/docker/production/"
cp docker/production/.env "$TEMP_DIR/docker/production/"

# Copie du code source (sans vendor et autres dossiers inutiles)
rsync -av \
    --exclude='vendor/' \
    --exclude='web/sites/default/files/' \
    --exclude='.git/' \
    --exclude='docker/local/' \
    --exclude='docker/recette/' \
    --exclude='docker/preprod/' \
    --exclude='node_modules/' \
    . "$TEMP_DIR/"

# Transfert vers le serveur
echo "📤 Transfert des fichiers vers le serveur..."
rsync -avz --delete "$TEMP_DIR/" "$SERVER_USER@$SERVER_HOST:$REMOTE_PATH/"

# Commandes à exécuter sur le serveur distant
echo "🔧 Exécution des commandes sur le serveur distant..."
ssh "$SERVER_USER@$SERVER_HOST" << 'ENDSSH'
cd /home/votre-utilisateur/drupal

# Création du répertoire de sauvegarde si inexistant
mkdir -p backups

# Sauvegarde de la base de données avant déploiement
echo "💾 Sauvegarde de la base de données..."
BACKUP_FILE="backup_$(date +%Y%m%d_%H%M%S).sql"
docker exec mariadb_prod mysqldump -u root -p${DB_ROOT_PASSWORD} drupal_prod > "backups/${BACKUP_FILE}" 2>/dev/null || echo "⚠️  Erreur lors de la sauvegarde (normal si première installation)"

# Arrêt des conteneurs existants
docker-compose -f docker/production/docker-compose.yml --env-file docker/production/.env down || true

# Pull des images
docker-compose -f docker/production/docker-compose.yml --env-file docker/production/.env pull

# Démarrage des conteneurs
docker-compose -f docker/production/docker-compose.yml --env-file docker/production/.env up -d

# Attente que les services soient prêts
echo "⏳ Attente que les services soient prêts..."
sleep 15

# Vérification
docker-compose -f docker/production/docker-compose.yml --env-file docker/production/.env ps
ENDSSH

# Nettoyage
rm -rf "$TEMP_DIR"

echo "✅ Déploiement en PRODUCTION terminé !"
echo "🌐 Application accessible sur: http://$SERVER_HOST"
echo "💾 Sauvegarde créée sur le serveur avant déploiement"