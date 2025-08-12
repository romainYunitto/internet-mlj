# Configuration SSL Multi-domaines

## Placement des certificats

Placez vos certificats SSL dans ce dossier :

- `cert.pem` : Certificat SSL wildcard (incluant la chaîne de certification)
- `key.pem` : Clé privée

## Certificat Wildcard pour tous les sous-domaines

### Génération auto-signée (pour les tests)
```bash
# Depuis le dossier ssl/
openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes \
  -subj "/C=FR/ST=France/L=City/O=Organization/CN=mlj.fr" \
  -addext "subjectAltName=DNS:mlj.fr,DNS:www.mlj.fr,DNS:admin.mlj.fr,DNS:intramlj.fr,DNS:www.intramlj.fr"
```

### Certificats Let's Encrypt séparés (production)
```bash
# Installation de certbot
sudo apt-get install certbot

# Génération des certificats pour chaque domaine
sudo certbot certonly --standalone -d mlj.fr -d www.mlj.fr -d admin.mlj.fr
sudo certbot certonly --standalone -d intramlj.fr -d www.intramlj.fr

# Pour simplifier, utiliser le certificat mlj.fr pour tous (ou créer un certificat multi-domaine)
sudo cp /etc/letsencrypt/live/mlj.fr/fullchain.pem ./cert.pem
sudo cp /etc/letsencrypt/live/mlj.fr/privkey.pem ./key.pem
sudo chown $USER:$USER *.pem

# OU certificat multi-domaine
sudo certbot certonly --standalone -d mlj.fr -d www.mlj.fr -d admin.mlj.fr -d intramlj.fr -d www.intramlj.fr
```

## Domaines supportés
- `https://mlj.fr` → NextJS Front-office (port 3000)
- `https://www.mlj.fr` → NextJS Front-office (port 3000)  
- `https://admin.mlj.fr` → Drupal Internet Back-office (port 8002)
- `https://intramlj.fr` → Drupal Intranet (port 8000)
- `https://www.intramlj.fr` → Drupal Intranet (port 8000)

## Renouvellement automatique

Ajoutez dans la crontab :
```bash
0 0 1 * * /usr/bin/certbot renew --quiet && docker compose -f /path/to/ssl-proxy/docker-compose.yml restart ssl-proxy
```