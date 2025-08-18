# Internet MLJ - Projet Drupal

## Prérequis

- Docker et Docker Compose
- WSL2 (si sur Windows)

## Installation sur un nouveau PC

1. **Cloner le projet**
```bash
git clone <votre-repo-url>
cd internet-mlj
```

2. **Copier le fichier d'environnement**
```bash
cp .env.example .env
```

3. **Ajuster les variables dans .env si nécessaire**
```bash
PROJECT_NAME=internet-mlj
PROJECT_BASE_URL=localhost
PROJECT_PORT=8000

DB_NAME=drupal
DB_USER=drupal
DB_PASSWORD=drupal
DB_ROOT_PASSWORD=password
DB_HOST=mariadb
DB_PORT=3306
DB_DRIVER=mysql
```

4. **Lancer les conteneurs**
```bash
docker-compose up -d
```

5. **Installer les dépendances Composer**
```bash
docker-compose exec php composer install
```

6. **Configurer Drupal**
- Aller sur http://localhost:8000
- Suivre l'installation Drupal
- Utiliser les paramètres de base de données du .env

## Commandes utiles

```bash
# Démarrer les conteneurs
docker-compose up -d

# Arrêter les conteneurs
docker-compose down

# Voir les logs
docker-compose logs

# Accéder au conteneur PHP
docker-compose exec php bash

# Utiliser Drush
docker-compose exec php drush status

# Reconstruire les conteneurs
docker-compose up -d --build
```

## Accès

- **Site web**: http://localhost:8000
- **Mailpit**: http://localhost:8025

## Modules installés

- **pathauto** - Génération automatique d'URL
- **admin_toolbar** - Barre d'administration améliorée
- **views_serialization_pager** - Pagination pour les vues API
- **drush** - Outil en ligne de commande Drupal
- **devel** (dev) - Outils de développement

## Structure du projet

```
web/            # Racine web de Drupal
├── core/       # Coeur Drupal (non versionné)
├── modules/    # Modules Drupal
│   ├── contrib/  # Modules communautaires
│   └── custom/   # Modules personnalisés
├── themes/     # Thèmes Drupal
├── sites/      # Configuration des sites
└── ...

vendor/         # Dépendances Composer (non versionné)
docker-compose.yml  # Configuration Docker
.env            # Variables d'environnement (non versionné)
composer.json   # Dépendances PHP
.gitignore      # Fichiers ignorés par Git
```

## Stack

The Drupal stack consist of the following containers:

| Container             | Versions                | Image                                     | ARM64 support | Enabled by default |
|-----------------------|-------------------------|-------------------------------------------|---------------|--------------------|
| [Nginx]               | 1.29, 1.28              | [wodby/nginx]                             | ✓             | ✓                  |
| [Apache]              | 2.4                     | [wodby/apache]                            | ✓             |                    |
| Drupal CMS            | 1                       | [wodby/drupal-cms]                        | ✓             | ✓                  |
| Vanilla Drupal        | 11, 10                  | [wodby/drupal]                            | ✓             |                    |
| [PHP]                 | 8.4, 8.3, 8.2, 8.1      | [wodby/drupal-php]                        | ✓             |                    |
| Crond                 |                         | [wodby/drupal-php]                        | ✓             | ✓                  |
| [MariaDB]             | 11.4, 10.11, 10.6, 10.5 | [wodby/mariadb]                           | ✓             | ✓                  |
| [PostgreSQL]          | 17, 16, 15, 14, 13      | [wodby/postgres]                          | ✓             |                    |
| [Valkey]              | 8, 7                    | [wodby/valkey]                            | ✓             |                    |
| [Memcached]           | 1                       | [wodby/memcached]                         | ✓             |                    |
| [Varnish]             | 6.0                     | [wodby/varnish]                           | ✓             |                    |
| [Node.js]             | 22, 20, 18              | [wodby/node]                              | ✓             |                    |
| [Solr]                | 9                       | [wodby/solr]                              | ✓             |                    |
| Zookeeper             | 3.8                     | [zookeeper]                               | ✓             |                    |
| OpenSearch            | 2                       | [opensearchproject/opensearch]            | ✓             |                    |
| OpenSearch Dashboards | 2                       | [opensearchproject/opensearch-dashboards] | ✓             |                    |
| [OpenSMTPD]           | 7                       | [wodby/opensmtpd]                         | ✓             |                    |
| Mailpit               | latest                  | [axllent/mailpit]                         | ✓             | ✓                  |
| Gotenberg             | latest                  | [gotenberg/gotenberg]                     | ✓             |                    |
| [Rsyslog]             | latest                  | [wodby/rsyslog]                           | ✓             |                    |
| [Webgrind]            | 1                       | [wodby/webgrind]                          | ✓             |                    |
| [Xhprof viewer]       | latest                  | [wodby/xhprof]                            | ✓             |                    |
| Adminer               | 5                       | [wodby/adminer]                           | ✓             |                    |
| phpMyAdmin            | latest                  | [phpmyadmin/phpmyadmin]                   |               |                    |
| Selenium chrome       | 3.141                   | [selenium/standalone-chrome]              |               |                    |
| Traefik               | latest                  | [_/traefik]                               | ✓             | ✓                  |

## Documentation

Full documentation is available at https://wodby.com/docs/stacks/drupal/local.

## Image's tags

Images' tags format is `[VERSION]-[STABILITY_TAG]` where:

`[VERSION]` is the _version of an application_ (without patch version) running in a container, e.g.
`wodby/nginx:1.15-x.x.x` where Nginx version is `1.15` and
`x.x.x` is a stability tag. For some images we include both major and minor version like PHP
`7.2`, for others we include only major like Valkey `7`.

`[STABILITY_TAG]` is the _version of an image_ that corresponds to a git tag of the image repository, e.g.
`wodby/mariadb:10.2-3.3.8` has MariaDB `10.2` and stability tag [
`3.3.8`](https://github.com/wodby/mariadb/releases/tag/3.3.8). New stability tags include patch updates for applications and image's fixes/improvements (new env vars, orchestration actions fixes, etc). Stability tag changes described in the corresponding a git tag description. Stability tags follow [semantic versioning](https://semver.org/).

We highly encourage to use images only with stability tags.

## Maintenance

We regularly update images used in this stack and release them together, see [releases page](https://github.com/wodby/docker4drupal/releases) for full changelog and update instructions. Most of routine updates for images and this project performed by [the bot](https://github.com/wodbot) via scripts located at [wodby/images](https://github.com/wodby/images).

## Beyond local environment

Docker4Drupal is a project designed to help you spin up local environment with Docker Compose. If you want to deploy a consistent stack with orchestrations to your own server, check out [Drupal stack](https://wodby.com/stacks/drupal) on Wodby ![](https://www.google.com/s2/favicons?domain=wodby.com).

## Other Docker4x projects

* [docker4php](https://github.com/wodby/docker4php)
* [docker4laravel](https://github.com/wodby/docker4laravel)
* [docker4wordpress](https://github.com/wodby/docker4wordpress)
* [docker4ruby](https://github.com/wodby/docker4ruby)
* [docker4python](https://github.com/wodby/docker4python)

## License

This project is licensed under the MIT open source license.

[Apache]: https://wodby.com/docs/stacks/drupal/containers#apache

[Drupal CMS]: https://wodby.com/docs/stacks/drupal/containers#php

[Vanilla Drupal]: https://wodby.com/docs/stacks/drupal/containers#php

[MariaDB]: https://wodby.com/docs/stacks/drupal/containers#mariadb

[Memcached]: https://wodby.com/docs/stacks/drupal/containers#memcached

[Nginx]: https://wodby.com/docs/stacks/drupal/containers#nginx

[Node.js]: https://wodby.com/docs/stacks/drupal/containers#nodejs

[OpenSMTPD]: https://wodby.com/docs/stacks/drupal/containers#opensmtpd

[PHP]: https://wodby.com/docs/stacks/drupal/containers#php

[PostgreSQL]: https://wodby.com/docs/stacks/drupal/containers#postgresql

[Redis]: https://wodby.com/docs/stacks/drupal/containers#redis

[Valkey]: https://wodby.com/docs/stacks/valkey/containers#valkey

[Rsyslog]: https://wodby.com/docs/stacks/drupal/containers#rsyslog

[Solr]: https://wodby.com/docs/stacks/drupal/containers#solr

[Varnish]: https://wodby.com/docs/stacks/drupal/containers#varnish

[Webgrind]: https://wodby.com/docs/stacks/drupal/containers#webgrind

[XHProf viewer]: https://wodby.com/docs/stacks/php/containers#xhprof-viewer

[_/traefik]: https://hub.docker.com/_/traefik

[gotenberg/gotenberg]: https://hub.docker.com/r/gotenberg/gotenberg

[axllent/mailpit]: https://hub.docker.com/r/axllent/mailpit

[phpmyadmin/phpmyadmin]: https://hub.docker.com/r/phpmyadmin/phpmyadmin

[selenium/standalone-chrome]: https://hub.docker.com/r/selenium/standalone-chrome

[wodby/adminer]: https://hub.docker.com/r/wodby/adminer

[wodby/apache]: https://github.com/wodby/apache

[wodby/drupal-php]: https://github.com/wodby/drupal-php

[wodby/drupal]: https://github.com/wodby/drupal

[wodby/drupal-cms]: https://github.com/wodby/drupal-cms

[wodby/mariadb]: https://github.com/wodby/mariadb

[wodby/memcached]: https://github.com/wodby/memcached

[wodby/nginx]: https://github.com/wodby/nginx

[wodby/node]: https://github.com/wodby/node

[wodby/opensmtpd]: https://github.com/wodby/opensmtpd

[wodby/postgres]: https://github.com/wodby/postgres

[wodby/valkey]: https://github.com/wodby/valkey

[wodby/rsyslog]: https://hub.docker.com/r/wodby/rsyslog

[wodby/solr]: https://github.com/wodby/solr

[wodby/varnish]: https://github.com/wodby/varnish

[wodby/webgrind]: https://hub.docker.com/r/wodby/webgrind

[wodby/xhprof]: https://hub.docker.com/r/wodby/xhprof

[zookeeper]: https://hub.docker.com/_/zookeeper

[opensearchproject/opensearch]: https://hub.docker.com/r/opensearchproject/opensearch

[opensearchproject/opensearch-dashboards]: https://hub.docker.com/r/opensearchproject/opensearch-dashboards
