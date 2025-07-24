#!/bin/bash

# Script de déploiement pour l'environnement PRODUCTION
set -e

ENVIRONMENT="production"
DOCKER_DIR="docker/${ENVIRONMENT}"

echo "🚀 Déploiement de l'environnement ${ENVIRONMENT}..."

# Confirmation de déploiement en production
read -p "⚠️  Vous êtes sur le point de déployer en PRODUCTION. Êtes-vous sûr ? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Déploiement annulé"
    exit 1
fi

# Vérification que nous sommes dans le bon répertoire
if [ ! -f "${DOCKER_DIR}/docker-compose.yml" ]; then
    echo "❌ Erreur: fichier docker-compose.yml non trouvé dans ${DOCKER_DIR}"
    exit 1
fi

# Sauvegarde de la base de données avant déploiement
echo "💾 Sauvegarde de la base de données..."
BACKUP_FILE="backup_$(date +%Y%m%d_%H%M%S).sql"
docker exec mariadb_prod mysqldump -u root -p${DB_ROOT_PASSWORD} drupal_prod > "backups/${BACKUP_FILE}" || echo "⚠️  Erreur lors de la sauvegarde (normal si première installation)"

# Arrêt des conteneurs existants
echo "⏹️  Arrêt des conteneurs existants..."
docker-compose -f "${DOCKER_DIR}/docker-compose.yml" --env-file "${DOCKER_DIR}/.env" down

# Pull des dernières images
echo "📥 Téléchargement des dernières images..."
docker-compose -f "${DOCKER_DIR}/docker-compose.yml" --env-file "${DOCKER_DIR}/.env" pull

# Démarrage des conteneurs
echo "▶️  Démarrage des conteneurs..."
docker-compose -f "${DOCKER_DIR}/docker-compose.yml" --env-file "${DOCKER_DIR}/.env" up -d

# Attente que les services soient prêts
echo "⏳ Attente que les services soient prêts..."
sleep 15

# Vérification de l'état des conteneurs
echo "🔍 Vérification de l'état des conteneurs..."
docker-compose -f "${DOCKER_DIR}/docker-compose.yml" --env-file "${DOCKER_DIR}/.env" ps

echo "✅ Déploiement de l'environnement ${ENVIRONMENT} terminé !"
echo "🌐 L'application est accessible sur le port 80"