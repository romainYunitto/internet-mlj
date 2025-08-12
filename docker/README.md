# Configuration Docker Multi-Environnements

Cette configuration permet de gérer 4 environnements distincts pour votre application Drupal :

- **Local** : Développement local (port 8000)
- **Recette** : Tests et validation (port 8001)  
- **Préprod** : Tests avant production (port 8002)
- **Production** : Environnement de production (port 80)

## Structure

```
docker/
├── docker-compose.base.yml     # Configuration commune
├── local/
│   ├── docker-compose.yml     # Config spécifique local
│   └── .env                   # Variables d'environnement local
├── recette/
│   ├── docker-compose.yml     # Config spécifique recette
│   └── .env                   # Variables d'environnement recette
├── preprod/
│   ├── docker-compose.yml     # Config spécifique préprod
│   └── .env                   # Variables d'environnement préprod
├── production/
│   ├── docker-compose.yml     # Config spécifique production
│   └── .env                   # Variables d'environnement production
└── scripts/
    ├── deploy-recette.sh      # Script de déploiement recette
    ├── deploy-preprod.sh      # Script de déploiement préprod
    └── deploy-production.sh   # Script de déploiement production
```

## Utilisation

### Environnement Local
```bash
cd docker/local
docker-compose up -d
```

### Environnement Recette
```bash
# Via script automatisé
./docker/scripts/deploy-recette.sh

# Ou manuellement
cd docker/recette
docker-compose up -d
```

### Environnement Préprod
```bash
# Via script automatisé
./docker/scripts/deploy-preprod.sh

# Ou manuellement
cd docker/preprod
docker-compose up -d
```

### Environnement Production
```bash
# Via script automatisé (avec confirmation)
./docker/scripts/deploy-production.sh

# Ou manuellement
cd docker/production
docker-compose up -d
```

## Accès aux environnements

- **Local** : http://localhost:8000
- **Recette** : http://localhost:8001 (ou votre domaine de recette)
- **Préprod** : http://localhost:8002 (ou votre domaine de préprod)
- **Production** : http://localhost (ou votre domaine de production)

## Configuration des mots de passe

⚠️ **IMPORTANT** : Changez tous les mots de passe marqués `CHANGEME` dans les fichiers `.env` avant le déploiement !

## Isolation des environnements

Chaque environnement utilise :
- Des conteneurs avec des noms distincts
- Des bases de données séparées
- Des ports différents
- Des configurations spécifiques

Cela garantit une isolation complète entre les environnements.

## Déploiement sur serveurs distants

### Scripts de déploiement automatisé

**Recette :**
```bash
# Modifiez les variables serveur dans le script puis :
./docker/scripts/deploy-recette-remote.sh
```

**Préprod :**
```bash
./docker/scripts/deploy-preprod-remote.sh
```

**Production :**
```bash
# Confirmation requise + sauvegarde automatique
./docker/scripts/deploy-production-remote.sh
```

### Scripts de synchronisation manuelle

**Recette :**
```bash
./docker/scripts/sync-recette-files.sh user@recette.example.com
```

**Préprod :**
```bash
./docker/scripts/sync-preprod-files.sh user@preprod.example.com
```

**Production :**
```bash
./docker/scripts/sync-production-files.sh user@production.example.com
```

### Fichiers .env.server

Pour chaque environnement distant, utilisez les fichiers `.env.server` qui ont `PROJECT_ROOT=.` (adapté aux serveurs distants) :

- `docker/recette/.env.server`
- `docker/preprod/.env.server` 
- `docker/production/.env.server`

## Sécurité

- ⚠️ Changez tous les mots de passe `CHANGEME` avant déploiement
- 🔐 La production utilise des mots de passe renforcés (`CHANGEME_SECURE`)
- 💾 Sauvegarde automatique avant déploiement production
- 🔍 Confirmation requise pour tous les déploiements production