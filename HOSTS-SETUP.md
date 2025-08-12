# Configuration du fichier hosts pour les domaines MLJ

## Linux/WSL (votre cas)

Exécutez cette commande :

```bash
sudo nano /etc/hosts
```

Ajoutez ces lignes à la fin du fichier :

```
# MLJ Local Development Domains
127.0.0.1	mlj.fr
127.0.0.1	www.mlj.fr
127.0.0.1	admin.mlj.fr
127.0.0.1	intramlj.fr
127.0.0.1	www.intramlj.fr
```

**OU directement avec cette commande :**

```bash
sudo bash -c "cat >> /etc/hosts << 'EOF'

# MLJ Local Development Domains
127.0.0.1	mlj.fr
127.0.0.1	www.mlj.fr
127.0.0.1	admin.mlj.fr
127.0.0.1	intramlj.fr
127.0.0.1	www.intramlj.fr
EOF"
```

## Windows (si vous testez depuis Windows)

1. Ouvrir **Notepad en tant qu'administrateur**
2. Ouvrir le fichier : `C:\Windows\System32\drivers\etc\hosts`
3. Ajouter les mêmes lignes à la fin

## Après modification

Testez avec :
```bash
ping admin.mlj.fr
# Doit répondre depuis 127.0.0.1
```

Ensuite vous pourrez démarrer le reverse proxy SSL !