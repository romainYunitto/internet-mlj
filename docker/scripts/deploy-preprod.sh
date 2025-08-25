#!/bin/bash

# Script de déploiement pour l'environnement PREPROD
set -e

ENVIRONMENT="preprod"
DOCKER_DIR="docker/${ENVIRONMENT}"

echo "🚀 Déploiement de l'environnement ${ENVIRONMENT}..."

# Vérification que nous sommes dans le bon répertoire
if [ ! -f "${DOCKER_DIR}/docker-compose.yml" ]; then
    echo "❌ Erreur: fichier docker-compose.yml non trouvé dans ${DOCKER_DIR}"
    exit 1
fi

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
sleep 10

# Vérification de l'état des conteneurs
echo "🔍 Vérification de l'état des conteneurs..."
docker-compose -f "${DOCKER_DIR}/docker-compose.yml" --env-file "${DOCKER_DIR}/.env" ps

echo "✅ Déploiement de l'environnement ${ENVIRONMENT} terminé !"
echo "🌐 L'application est accessible sur le port 8002"