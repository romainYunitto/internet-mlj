#!/bin/bash

# Script de déploiement SSL Proxy Global pour les 3 applications
set -e

echo "🔐 Déploiement du reverse proxy SSL global..."

# Vérification des certificats SSL
if [[ ! -f "ssl/cert.pem" || ! -f "ssl/key.pem" ]]; then
    echo "⚠️  Certificats SSL manquants ! Génération d'un certificat multi-domaine auto-signé pour les tests..."
    mkdir -p ssl
    openssl req -x509 -newkey rsa:4096 -keyout ssl/key.pem -out ssl/cert.pem -days 365 -nodes \
        -subj "/C=FR/ST=France/L=City/O=Organization/CN=mlj.fr" \
        -addext "subjectAltName=DNS:mlj.fr,DNS:www.mlj.fr,DNS:admin.mlj.fr,DNS:intramlj.fr,DNS:www.intramlj.fr"
    echo "✅ Certificat multi-domaine auto-signé généré"
fi

# Démarrage de Drupal Internet Back-office (sans port exposé)
echo "🚀 Démarrage de Drupal Internet Back-office..."
cd ../..
docker compose up -d

# Attendre que Drupal soit prêt
echo "⏳ Attente du démarrage de Drupal Internet Back-office..."
sleep 10

# Démarrage du reverse proxy SSL global
echo "🔐 Démarrage du reverse proxy SSL global..."
cd ../ssl-proxy
docker compose up -d

echo "✅ Déploiement terminé !"
echo ""
echo "🌐 Applications accessibles via HTTPS :"
echo "   - Front-office NextJS : https://mlj.fr (port 3000)"
echo "   - Admin Drupal Internet : https://admin.mlj.fr (port 8002)" 
echo "   - Intranet Drupal : https://intramlj.fr (port 8000)"
echo ""
echo "🔄 Redirections HTTP→HTTPS automatiques configurées"
echo ""
echo "📋 Vérification des conteneurs :"
docker compose ps

echo ""
echo "⚠️  IMPORTANT : Pour que tout fonctionne, assurez-vous que :"
echo "   - Le Docker Intranet est démarré : cd /home/moebius/infra-mlj && docker compose up -d"
echo "   - L'application NextJS (port 3000) est démarrée"
echo "   - Les DNS pointent vers ce serveur pour tous les domaines"