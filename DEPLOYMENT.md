# Guide de Déploiement MLJ

## Architecture

### Environnements
- **local** : Développement avec SSL proxy et mailpit
- **recette** : Tests internes
- **preprod** : Tests chez le prestataire 
- **production** : Environnement de production

### Applications
1. **Internet-MLJ** : Drupal 11.2 back-office admin
2. **MLJ-web** : NextJS front-office  
3. **Intra-MLJ** : Drupal 11.2 intranet
4. **SSL-proxy** : Reverse proxy HTTPS avec certificats wildcard

### URLs par environnement

**Préprod :**
- Back-office : https://pp-admin.manteslajolie.fr/
- Front-office : https://pp-site.manteslajolie.fr/
- Intranet : https://pp-intra.manteslajolie.fr/

**Production :**
- Back-office : https://admin.manteslajolie.fr/
- Front-office : https://www.manteslajolie.fr/
- Intranet : https://intra.manteslajolie.fr/

## Persistance des Données

### Volumes Docker par environnement

**Local :**
- `db_local` : Base de données MariaDB
- `files_local` : Fichiers publics Drupal

**Recette :**
- `db_recette` : Base de données MariaDB  
- `files_recette` : Fichiers publics Drupal

**Préprod :**
- `db_preprod` : Base de données MariaDB
- `files_preprod` : Fichiers publics Drupal  

**Production :**
- `db_prod` : Base de données MariaDB
- `files_prod` : Fichiers publics Drupal

Les fichiers publics incluent images, documents et autres médias uploadés par les utilisateurs.

## Prérequis Serveur

### Chez le prestataire
- Docker et Docker Compose installés
- **IMPORTANT** : Toutes les commandes docker doivent être exécutées avec `sudo`
- Certificats SSL wildcard disponibles :
  - **Préprod** : `/data/docker/internetmantes/certs/`
  - **Production** : `/data/docker/internetmantes/certs/`

### Chemins sur le serveur préprod
```
/data/docker/internetmantes/
├── internet-mlj/     # Drupal Internet back-office
├── MLJ-web/         # NextJS front-office  
├── intra-mlj/       # Drupal Intranet
└── certs/           # Certificats SSL
    ├── wildcard.manteslajolie.fr.crt
    └── wildcard.manteslajolie.fr.key
```

## Déploiement Automatisé

### Script de déploiement complet
```bash
./deploy-preprod-complete.sh
```

**Options disponibles :**
1. Déploiement complet (arrêt + redémarrage)
2. Démarrage seulement  
3. Arrêt seulement
4. Vérification de l'état

### Services déployés dans l'ordre
1. **Internet-MLJ** (Drupal back-office) - Port interne 80
2. **Intra-MLJ** (Drupal intranet) - Port interne 80  
3. **MLJ-web** (NextJS front-office) - Port interne 3000
4. **SSL-proxy** (Reverse proxy) - Ports externes 80/443

## Déploiement Manuel

### 1. Internet-MLJ (Drupal back-office)
```bash
cd /data/docker/internetmantes/internet-mlj
sudo docker compose -f docker/preprod/docker-compose.yml up -d

# Post-installation Drupal
sudo docker exec -u root preprod-internet-mlj_php composer install --no-dev --optimize-autoloader
sudo docker exec -u root preprod-internet-mlj_php chown -R wodby:wodby /var/www/html/vendor
sudo docker exec -u root preprod-internet-mlj_php chown -R wodby:wodby /var/www/html/web/sites/default/files
```

### 2. Intra-MLJ (Drupal intranet) 
```bash
cd /data/docker/internetmantes/intra-mlj
sudo docker compose -f docker/preprod/docker-compose.yml up -d

# Post-installation Drupal
sudo docker exec -u root preprod-intranet-preprod_php_v2 composer install --no-dev --optimize-autoloader
sudo docker exec -u root preprod-intranet-preprod_php_v2 chown -R wodby:wodby /var/www/html/vendor
sudo docker exec -u root preprod-intranet-preprod_php_v2 chown -R wodby:wodby /var/www/html/web/sites/default/files
```

### 3. MLJ-web (NextJS front-office)
```bash
cd /data/docker/internetmantes/MLJ-web  
sudo docker compose -f docker/stagging/compose.yml up -d
```

### 4. SSL-proxy (Reverse proxy)
```bash
cd /data/docker/internetmantes/internet-mlj/docker/ssl-proxy/preprod
sudo docker compose up -d
```

## Vérifications Post-Déploiement

### État des containers
```bash
sudo docker ps --format "table {{.Names}}\\t{{.Status}}\\t{{.Ports}}"
```

### Logs des services
```bash
# Drupal Internet
sudo docker logs preprod-internet-mlj_php --tail=20
sudo docker logs preprod-internet-mlj_nginx --tail=20

# SSL Proxy  
sudo docker logs ssl_proxy_preprod --tail=20

# NextJS
sudo docker logs next-app-stagging --tail=20
```

### Tests d'accès

**Préprod :**
- **Back-office** : https://pp-admin.manteslajolie.fr/
- **Front-office** : https://pp-site.manteslajolie.fr/
- **Intranet** : https://pp-intra.manteslajolie.fr/

**Production :**
- **Back-office** : https://admin.manteslajolie.fr/
- **Front-office** : https://www.manteslajolie.fr/
- **Intranet** : https://intra.manteslajolie.fr/

## Configuration DNS

**Préprod :**
- pp-admin.manteslajolie.fr
- pp-site.manteslajolie.fr  
- pp-intra.manteslajolie.fr

**Production :**
- admin.manteslajolie.fr
- www.manteslajolie.fr
- intra.manteslajolie.fr

## Mise en Route Initiale Drupal

### Premier déploiement d'un site Drupal

Après le démarrage des containers, plusieurs étapes sont nécessaires :

#### 1. Installation des dépendances
```bash
# Internet-MLJ
sudo docker exec -u root preprod-internet-mlj_php composer install --no-dev --optimize-autoloader

# Intra-MLJ  
sudo docker exec -u root preprod-intranet-preprod_php_v2 composer install --no-dev --optimize-autoloader
```

#### 2. Configuration des permissions
```bash
# Internet-MLJ
sudo docker exec -u root preprod-internet-mlj_php chown -R wodby:wodby /var/www/html/vendor
sudo docker exec -u root preprod-internet-mlj_php chown -R wodby:wodby /var/www/html/web/sites/default/files
sudo docker exec -u root preprod-internet-mlj_php chmod -R 755 /var/www/html/web/sites/default/files

# Intra-MLJ
sudo docker exec -u root preprod-intranet-preprod_php_v2 chown -R wodby:wodby /var/www/html/vendor
sudo docker exec -u root preprod-intranet-preprod_php_v2 chown -R wodby:wodby /var/www/html/web/sites/default/files
sudo docker exec -u root preprod-intranet-preprod_php_v2 chmod -R 755 /var/www/html/web/sites/default/files
```

#### 3. Vérification des fichiers de configuration
```bash
# Vérifier settings.php
sudo docker exec preprod-internet-mlj_php ls -la /var/www/html/web/sites/default/settings.php

# Vérifier autoload.php  
sudo docker exec preprod-internet-mlj_php ls -la /var/www/html/web/autoload.php
sudo docker exec preprod-internet-mlj_php ls -la /var/www/html/vendor/autoload.php
```

#### 4. Installation Drupal (si base vide)
```bash
# Si c'est une nouvelle installation
sudo docker exec preprod-internet-mlj_php ./vendor/bin/drush site-install -y

# Si c'est une importation de base
sudo docker exec -i preprod-internet-mlj_mariadb mysql -u drupal -p drupal < backup.sql
sudo docker exec preprod-internet-mlj_php ./vendor/bin/drush cache:rebuild
sudo docker exec preprod-internet-mlj_php ./vendor/bin/drush updatedb -y
```

#### 5. Configuration finale
```bash
# Nettoyer les caches
sudo docker exec preprod-internet-mlj_php ./vendor/bin/drush cache:rebuild

# Mettre à jour la configuration
sudo docker exec preprod-internet-mlj_php ./vendor/bin/drush config:import -y

# Vérifier l'état
sudo docker exec preprod-internet-mlj_php ./vendor/bin/drush status
```

## Résolution de Problèmes

### Drupal ne se charge pas
1. Vérifier les logs PHP : `sudo docker logs preprod-internet-mlj_php`
2. Vérifier la base de données : `sudo docker exec preprod-internet-mlj_php env | grep DB_`
3. Vérifier settings.php : `sudo docker exec preprod-internet-mlj_php tail /var/www/html/web/sites/default/settings.php`

### Certificats SSL
1. Vérifier la présence : `ls -la /data/docker/internetmantes/certs/`
2. Vérifier la configuration nginx : `docker/ssl-proxy/preprod/nginx.conf`
3. Redémarrer le proxy : `sudo docker compose restart`

### Composer/Dépendances
```bash
sudo docker exec -u root preprod-internet-mlj_php composer install --no-dev --optimize-autoloader
```

## Maintenance

### Sauvegarde des données
```bash
# Base de données
sudo docker exec preprod-internet-mlj_mariadb mysqldump -u drupal -p drupal > backup.sql

# Fichiers publics  
sudo docker run --rm -v files_preprod:/data -v $(pwd):/backup alpine tar czf /backup/files_preprod.tar.gz /data
```

### Restauration
```bash
# Base de données
sudo docker exec -i preprod-internet-mlj_mariadb mysql -u drupal -p drupal < backup.sql

# Fichiers publics
sudo docker run --rm -v files_preprod:/data -v $(pwd):/backup alpine tar xzf /backup/files_preprod.tar.gz -C /
```