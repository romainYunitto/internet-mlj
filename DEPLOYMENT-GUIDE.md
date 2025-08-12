# Guide de Déploiement Multi-Environnements - Architecture MLJ

Ce guide détaille le déploiement de l'architecture MLJ sur tous les environnements avec SSL centralisé.

## Architecture Globale

```
Internet → SSL Proxy (80/443) → Routage par domaine :
├── mlj.fr → NextJS Front-office (port 3000)
├── admin.mlj.fr → Drupal Internet Back-office
└── intramlj.fr → Drupal Intranet
```

## Structure des Projets

```
/home/moebius/
├── drupal/internet-mlj/              # Drupal Internet Back-office
│   └── docker/
│       ├── local/                    # Environnement local
│       ├── recette/                  # Environnement recette
│       ├── preprod/                  # Environnement préprod
│       ├── production/               # Environnement production
│       └── ssl-proxy/
│           ├── local/                # SSL proxy local
│           ├── recette/              # SSL proxy recette
│           ├── preprod/              # SSL proxy préprod
│           └── production/           # SSL proxy production
└── infra-mlj/                        # Drupal Intranet
    └── docker/
        ├── local/                    # Environnement local
        ├── recette/                  # Environnement recette
        ├── preprod/                  # Environnement préprod
        └── production/               # Environnement production
```

## Environnements et Domaines

| Environnement | Front NextJS | Internet Back-office | Intranet | Ports |
|---------------|--------------|---------------------|----------|-------|
| **Local** | https://mlj.fr | https://admin.mlj.fr | https://intramlj.fr | 80/443 |
| **Recette** | https://recette.mlj.fr | https://recette-admin.mlj.fr | https://recette-intramlj.fr | 80/443 |
| **Préprod** | https://preprod.mlj.fr | https://preprod-admin.mlj.fr | https://preprod-intramlj.fr | 80/443 |
| **Production** | https://mlj.fr | https://admin.mlj.fr | https://intramlj.fr | 80/443 |

## Déploiement par Environnement

### 🏠 Environnement LOCAL (Windows + WSL/Linux)

#### Prérequis
- Docker et Docker Compose installés
- Fichier hosts configuré (voir HOSTS-SETUP.md)

#### Déploiement
```bash
# 1. Démarrer Drupal Internet Back-office
cd /home/moebius/drupal/internet-mlj/docker/local
docker compose --env-file .env up -d

# 2. Démarrer Drupal Intranet
cd /home/moebius/infra-mlj/docker/local
docker compose --env-file .env up -d

# 3. Démarrer le reverse proxy SSL
cd /home/moebius/drupal/internet-mlj/docker/ssl-proxy/local
./deploy.sh

# 4. Optionnel: Démarrer NextJS (si disponible)
# npm run dev (port 3000)
```

#### URLs d'accès
- **https://admin.mlj.fr** → Drupal Internet Back-office
- **https://intramlj.fr** → Drupal Intranet
- **https://mlj.fr** → NextJS Front-office (si démarré)

---

### 🧪 Environnement RECETTE

#### Déploiement
```bash
# 1. Démarrer Drupal Internet Back-office
cd /home/moebius/drupal/internet-mlj/docker/recette
docker compose --env-file .env up -d

# 2. Démarrer Drupal Intranet
cd /home/moebius/infra-mlj/docker/recette
docker compose --env-file .env up -d

# 3. Démarrer le reverse proxy SSL
cd /home/moebius/drupal/internet-mlj/docker/ssl-proxy/recette
docker compose up -d
```

#### URLs d'accès
- **https://recette-admin.mlj.fr** → Drupal Internet Back-office
- **https://recette-intramlj.fr** → Drupal Intranet

---

### 🚀 Environnement PREPROD

#### Déploiement
```bash
# 1. Démarrer Drupal Internet Back-office
cd /home/moebius/drupal/internet-mlj/docker/preprod
docker compose --env-file .env up -d

# 2. Démarrer Drupal Intranet
cd /home/moebius/infra-mlj/docker/preprod
docker compose --env-file .env up -d

# 3. Démarrer le reverse proxy SSL
cd /home/moebius/drupal/internet-mlj/docker/ssl-proxy/preprod
docker compose up -d
```

#### URLs d'accès
- **https://preprod-admin.mlj.fr** → Drupal Internet Back-office
- **https://preprod-intramlj.fr** → Drupal Intranet

---

### 🔥 Environnement PRODUCTION

#### Déploiement
```bash
# 1. Démarrer Drupal Internet Back-office
cd /home/moebius/drupal/internet-mlj/docker/production
docker compose --env-file .env up -d

# 2. Démarrer Drupal Intranet
cd /home/moebius/infra-mlj/docker/production
docker compose --env-file .env up -d

# 3. Démarrer le reverse proxy SSL
cd /home/moebius/drupal/internet-mlj/docker/ssl-proxy/production
docker compose up -d
```

#### URLs d'accès
- **https://admin.mlj.fr** → Drupal Internet Back-office
- **https://intramlj.fr** → Drupal Intranet
- **https://mlj.fr** → NextJS Front-office

---

## Configuration SSL par Environnement

### Certificats de développement (Local/Recette)
Les certificats auto-signés sont générés automatiquement lors du premier déploiement.

### Certificats de production (Préprod/Production)
```bash
# Exemple avec Let's Encrypt
sudo certbot certonly --standalone \
  -d mlj.fr -d www.mlj.fr \
  -d admin.mlj.fr \
  -d intramlj.fr -d www.intramlj.fr

# Copier les certificats
sudo cp /etc/letsencrypt/live/mlj.fr/fullchain.pem ssl/cert.pem
sudo cp /etc/letsencrypt/live/mlj.fr/privkey.pem ssl/key.pem
```

## Scripts de Déploiement Disponibles

### Internet Back-office
- `docker/local/docker-compose.yml` + `.env`
- `docker/recette/docker-compose.yml` + `.env`
- `docker/preprod/docker-compose.yml` + `.env`
- `docker/production/docker-compose.yml` + `.env`

### Intranet
- `docker/local/docker-compose.yml` + `.env`
- `docker/recette/docker-compose.yml` + `.env`
- `docker/preprod/docker-compose.yml` + `.env`
- `docker/production/docker-compose.yml` + `.env`

### SSL Proxy
- `ssl-proxy/local/deploy.sh`
- `ssl-proxy/recette/docker-compose.yml`
- `ssl-proxy/preprod/docker-compose.yml`
- `ssl-proxy/production/docker-compose.yml`

## Commandes de Maintenance

### Arrêt des services
```bash
# Arrêter un environnement complet (exemple: local)
cd /home/moebius/drupal/internet-mlj/docker/ssl-proxy/local && docker compose down
cd /home/moebius/drupal/internet-mlj/docker/local && docker compose down
cd /home/moebius/infra-mlj/docker/local && docker compose down
```

### Logs et monitoring
```bash
# Logs SSL Proxy
docker compose logs ssl-proxy

# Logs applications
docker compose logs nginx
docker compose logs php
docker compose logs mariadb
```

### Mise à jour des images
```bash
docker compose pull
docker compose up -d
```

## Variables d'Environnement

Chaque environnement possède son fichier `.env` avec :
- Configurations de base de données spécifiques
- Paramètres PHP optimisés selon l'environnement
- Configuration Nginx adaptée
- Paramètres de debug (local uniquement)

## Sécurité

- **Ports exposés** : Seuls 80/443 sur le reverse proxy SSL
- **Réseaux isolés** : Chaque environnement sur son réseau Docker
- **SSL obligatoire** : Redirection automatique HTTP → HTTPS
- **Headers de sécurité** : HSTS, X-Frame-Options, etc.

## Dépannage

### Problèmes courants
1. **Certificat SSL invalide** : Vérifier le chemin des certificats
2. **Erreur de réseau** : Vérifier que les réseaux Docker existent
3. **Port occupé** : Un seul reverse proxy par serveur
4. **DNS** : Vérifier la résolution des domaines

### Commandes de diagnostic
```bash
# Vérifier les réseaux
docker network ls

# Vérifier les conteneurs
docker ps -a

# Tester la connectivité
curl -k https://admin.mlj.fr
```

L'architecture est maintenant prête pour tous les environnements avec SSL centralisé !