#!/bin/bash

# Script de déploiement préprod complet pour ce soir
# Déploie les 3 applications : Internet-MLJ, MLJ-web, Infra-MLJ + SSL-proxy

set -e

echo "🚀 Démarrage du déploiement préprod complet..."

# Variables
INTERNET_MLJ_PATH="/data/docker/internetmantes/internet-mlj"
MLJ_WEB_PATH="/data/docker/internetmantes/MLJ-web"
INFRA_MLJ_PATH="/data/docker/internetmantes/intra-mlj"

# Couleurs pour les logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Fonction pour arrêter tous les services
stop_all_services() {
    log_info "Arrêt de tous les services existants..."
    
    # Arrêt SSL-proxy
    cd "$INTERNET_MLJ_PATH/docker/ssl-proxy/preprod"
    if [ -f "docker-compose.yml" ]; then
        sudo docker compose down --remove-orphans || true
    fi
    
    # Arrêt Internet-MLJ
    cd "$INTERNET_MLJ_PATH"
    sudo docker compose -f docker/preprod/docker-compose.yml down --remove-orphans || true
    
    # Arrêt MLJ-web
    cd "$MLJ_WEB_PATH"
    sudo docker compose -f docker/stagging/compose.yml down --remove-orphans || true
    
    # Arrêt Infra-MLJ
    cd "$INFRA_MLJ_PATH"
    sudo docker compose -f docker/preprod/docker-compose.yml down --remove-orphans || true
    
    log_success "Services arrêtés"
}

# Fonction pour démarrer les services
start_all_services() {
    log_info "Démarrage des services préprod..."
    
    # 1. Démarrage Internet-MLJ (Drupal back-office)
    log_info "📝 Démarrage Internet-MLJ (Drupal back-office)..."
    cd "$INTERNET_MLJ_PATH"
    sudo docker compose -f docker/preprod/docker-compose.yml up -d
    sleep 10
    
    # 2. Démarrage Infra-MLJ (Intranet)
    log_info "🏢 Démarrage Infra-MLJ (Intranet)..."
    cd "$INFRA_MLJ_PATH"
    sudo docker compose -f docker/preprod/docker-compose.yml up -d
    sleep 10
    
    # 3. Démarrage MLJ-web (NextJS front-office en mode staging)
    log_info "🌐 Démarrage MLJ-web (NextJS front-office)..."
    cd "$MLJ_WEB_PATH"
    sudo docker compose -f docker/stagging/compose.yml up -d
    sleep 15
    
    # 4. Démarrage SSL-proxy
    log_info "🔒 Démarrage SSL-proxy..."
    cd "$INTERNET_MLJ_PATH/docker/ssl-proxy/preprod"
    sudo docker compose up -d
    
    log_success "Tous les services sont démarrés !"
}

# Fonction pour vérifier l'état des services
check_services() {
    log_info "Vérification de l'état des services..."
    
    echo -e "\n${BLUE}=== État des containers ===${NC}"
    sudo docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    
    echo -e "\n${BLUE}=== Vérification des endpoints ===${NC}"
    echo "• SSL-proxy : ports 80 et 443 exposés"
    echo "• Internet-MLJ : accessible via pp-admin.manteslajolie.fr"
    echo "• MLJ-web : accessible via pp-site.manteslajolie.fr (port 3002)"
    echo "• Infra-MLJ : accessible via pp-intra.manteslajolie.fr"
    
    echo -e "\n${YELLOW}N'oubliez pas de configurer vos DNS/hosts pour pointer vers ce serveur :${NC}"
    echo "pp-admin.manteslajolie.fr"
    echo "pp-site.manteslajolie.fr"
    echo "pp-intra.manteslajolie.fr"
}

# Fonction principale
main() {
    echo -e "${GREEN}=== DÉPLOIEMENT PRÉPROD COMPLET ===${NC}"
    echo "Déploiement des 3 applications pour les tests de ce soir"
    echo ""
    
    # Vérification des chemins
    for path in "$INTERNET_MLJ_PATH" "$MLJ_WEB_PATH" "$INFRA_MLJ_PATH"; do
        if [ ! -d "$path" ]; then
            log_error "Chemin non trouvé : $path"
            exit 1
        fi
    done
    
    # Menu d'options
    echo "Que souhaitez-vous faire ?"
    echo "1) Déploiement complet (arrêt + redémarrage)"
    echo "2) Démarrage seulement"
    echo "3) Arrêt seulement"
    echo "4) Vérification de l'état"
    echo ""
    read -p "Votre choix (1-4) : " choice
    
    case $choice in
        1)
            stop_all_services
            sleep 5
            start_all_services
            sleep 5
            check_services
            ;;
        2)
            start_all_services
            sleep 5
            check_services
            ;;
        3)
            stop_all_services
            ;;
        4)
            check_services
            ;;
        *)
            log_error "Choix invalide"
            exit 1
            ;;
    esac
    
    log_success "Opération terminée !"
}

# Exécution
main "$@"