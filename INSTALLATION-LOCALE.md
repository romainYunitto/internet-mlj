# Installation Locale - Architecture MLJ

Ce guide détaille l'installation complète de l'architecture MLJ en environnement local avec SSL centralisé.

## Architecture Déployée

```
Internet → SSL Proxy (ports 80/443) → Routage par domaine :
├── mlj.fr → NextJS Front-office (port 3000)
├── admin.mlj.fr → Drupal Internet Back-office (nginx_local:80)
└── intramlj.fr → Drupal Intranet (intra-intramlj_nginx:80)
```

## Prérequis

- Docker et Docker Compose installés
- WSL2 (si Windows)
- Accès administrateur pour modifier le fichier hosts

## Structure des Projets

```
/home/moebius/
├── drupal/internet-mlj/          # Drupal Internet Back-office
│   └── docker/ssl-proxy/         # Reverse proxy SSL centralisé
└── infra-mlj/                    # Drupal Intranet
```

## 1. Configuration DNS Locale

### Linux/WSL
```bash
sudo nano /etc/hosts
```

Ajouter ces lignes :
```
# MLJ Local Development Domains
127.0.0.1     mlj.fr
127.0.0.1     www.mlj.fr
127.0.0.1     admin.mlj.fr
127.0.0.1     intramlj.fr
127.0.0.1     www.intramlj.fr
```

### Windows (si test depuis Windows sur WSL)
**En PowerShell administrateur :**
```powershell
notepad C:\Windows\System32\drivers\etc\hosts
```

Ajouter (remplacer 172.29.52.143 par l'IP de votre WSL) :
```
# MLJ Local Development Domains (WSL)
172.29.52.143     mlj.fr
172.29.52.143     www.mlj.fr
172.29.52.143     admin.mlj.fr
172.29.52.143     intramlj.fr
172.29.52.143     www.intramlj.fr
```

**Trouver l'IP WSL :**
```bash
hostname -I | awk '{print $1}'
```

## 2. Installation Drupal Internet Back-office

```bash
cd /home/moebius/drupal/internet-mlj

# Démarrer les conteneurs
docker compose up -d

# Vérifier le statut
docker compose ps
```

**Conteneurs attendus :**
- `nginx_local` (Nginx)
- `php` (PHP-FPM)
- `mariadb` (Base de données)
- `mailpit` (Mail de test)

## 3. Installation Drupal Intranet

```bash
cd /home/moebius/infra-mlj

# Démarrer les conteneurs  
docker compose up -d

# Vérifier le statut
docker compose ps
```

**Conteneurs attendus :**
- `intra-intramlj_nginx` (Nginx)
- `intra-intramlj_php` (PHP-FPM)
- `intra-intramlj_mariadb` (Base de données)
- `intra-intramlj_mailhog` (Mail de test)
- `intra-intramlj_redis` (Cache)
- `intra-intramlj_solr` (Recherche)

## 4. Déploiement du Reverse Proxy SSL

```bash
cd /home/moebius/drupal/internet-mlj/docker/ssl-proxy

# Démarrer le proxy SSL (génère automatiquement les certificats de test)
./deploy.sh
```

**Le script :**
- Génère un certificat SSL multi-domaine auto-signé
- Démarre le reverse proxy SSL
- Connecte tous les réseaux Docker

## 5. Vérification de l'Installation

### Test des conteneurs
```bash
# SSL Proxy
cd /home/moebius/drupal/internet-mlj/docker/ssl-proxy
docker compose ps

# Internet Back-office
cd /home/moebius/drupal/internet-mlj
docker compose ps

# Intranet
cd /home/moebius/infra-mlj
docker compose ps
```

### Test DNS
```bash
ping admin.mlj.fr    # Doit répondre 127.0.0.1
ping intramlj.fr      # Doit répondre 127.0.0.1
```

### Test des applications
- **https://admin.mlj.fr** → Drupal Internet Back-office
- **https://intramlj.fr** → Drupal Intranet
- **http://localhost:8025** → Mailpit (emails de test Internet)

## 6. NextJS Front-office (Optionnel)

Si vous avez une application NextJS :
```bash
# Démarrer NextJS sur le port 3000
npm run dev
# OU
yarn dev
```

Accessible via : **https://mlj.fr**

## Dépannage

### Erreur "The provided host name is not valid"
- Vérifier que les conteneurs sont démarrés
- Redémarrer le reverse proxy SSL

### Certificat SSL non reconnu
Normal en développement (certificat auto-signé). Accepter l'exception dans le navigateur.

### Problème de connectivité réseau
```bash
# Redémarrer tous les services
cd /home/moebius/infra-mlj && docker compose restart
cd /home/moebius/drupal/internet-mlj && docker compose restart
cd /home/moebius/drupal/internet-mlj/docker/ssl-proxy && docker compose restart
```

### IP WSL qui change
L'IP WSL peut changer au redémarrage. Mettre à jour le fichier hosts Windows si nécessaire.

## Arrêt des Services

```bash
# Arrêter le reverse proxy SSL
cd /home/moebius/drupal/internet-mlj/docker/ssl-proxy
docker compose down

# Arrêter Drupal Internet
cd /home/moebius/drupal/internet-mlj
docker compose down

# Arrêter Drupal Intranet
cd /home/moebius/infra-mlj
docker compose down
```

## Structure SSL

- **Certificats** : `/home/moebius/drupal/internet-mlj/docker/ssl-proxy/ssl/`
- **Configuration Nginx** : `/home/moebius/drupal/internet-mlj/docker/ssl-proxy/nginx.conf`
- **Rollback Apache** : `/home/moebius/infra-mlj/ROLLBACK-INSTRUCTIONS.md`

## Support

- **Logs SSL Proxy** : `docker compose logs ssl-proxy`
- **Logs Internet** : `docker compose logs nginx`
- **Logs Intranet** : `docker compose logs nginx`

L'architecture est maintenant opérationnelle en local avec SSL centralisé !