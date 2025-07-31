#!/bin/bash

# Script de déploiement SSL Proxy Local pour les 3 applications
set -e

echo "🔐 Déploiement du reverse proxy SSL LOCAL..."

# Vérification des certificats SSL
if [[ ! -f "ssl/cert.pem" || ! -f "ssl/key.pem" ]]; then
    echo "⚠️  Certificats SSL manquants ! Génération d'un certificat multi-domaine auto-signé pour les tests..."
    mkdir -p ssl
    openssl req -x509 -newkey rsa:4096 -keyout ssl/key.pem -out ssl/cert.pem -days 365 -nodes \
        -subj "/C=FR/ST=France/L=City/O=MLJ-Local/CN=mlj.fr" \
        -addext "subjectAltName=DNS:mlj.fr,DNS:www.mlj.fr,DNS:admin.mlj.fr,DNS:intramlj.fr,DNS:www.intramlj.fr"
    echo "✅ Certificat multi-domaine auto-signé généré"
fi

# Démarrage de Drupal Internet Back-office LOCAL
echo "🚀 Démarrage de Drupal Internet Back-office LOCAL..."
cd ../../local
docker compose --env-file .env up -d
cd ../ssl-proxy/local

# Démarrage de Drupal Intranet LOCAL
echo "🚀 Démarrage de Drupal Intranet LOCAL..."
cd /home/moebius/infra-mlj/docker/local
docker compose --env-file .env up -d
cd /home/moebius/drupal/internet-mlj/docker/ssl-proxy/local

# Attendre que les applications soient prêtes
echo "⏳ Attente du démarrage des applications..."
sleep 15

# Démarrage du reverse proxy SSL local
echo "🔐 Démarrage du reverse proxy SSL LOCAL..."
docker compose up -d

echo "✅ Déploiement LOCAL terminé !"
echo ""
echo "🌐 Applications accessibles via HTTPS :"
echo "   - Front-office NextJS : https://mlj.fr (port 3000)"
echo "   - Admin Drupal Internet : https://admin.mlj.fr (local)" 
echo "   - Intranet Drupal : https://intramlj.fr (local)"
echo ""
echo "🔄 Redirections HTTP→HTTPS automatiques configurées"
echo ""
echo "📋 Vérification des conteneurs :"
docker compose ps

echo ""
echo "⚠️  IMPORTANT : Pour que tout fonctionne, assurez-vous que :"
echo "   - Le fichier hosts est configuré (voir HOSTS-SETUP.md)"
echo "   - L'application NextJS (port 3000) est démarrée si nécessaire"
echo "   - Les DNS pointent vers 127.0.0.1 pour tous les domaines"