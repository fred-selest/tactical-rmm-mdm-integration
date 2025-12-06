# Guide de Configuration Serveur MDM

## Spécifications serveur recommandées

### Configuration minimale
- **CPU**: 4 cores (Intel Xeon ou équivalent AMD)
- **RAM**: 8 GB
- **Stockage**: 50 GB SSD
- **Réseau**: 100 Mbps, IP publique fixe
- **OS**: Ubuntu Server 22.04 LTS (recommandé) ou Debian 11+

### Configuration recommandée (production)
- **CPU**: 8 cores
- **RAM**: 16 GB
- **Stockage**: 200 GB SSD NVMe
- **Réseau**: 1 Gbps, IP publique fixe
- **OS**: Ubuntu Server 22.04 LTS

### Estimation de charge
- **50 appareils**: Configuration minimale suffit
- **100-500 appareils**: Configuration recommandée
- **500+ appareils**: Envisager un cluster ou scaling horizontal

## Configuration système de base

### 1. Mise à jour du système

```bash
# Mise à jour complète
apt update && apt upgrade -y

# Installation des outils de base
apt install -y curl wget git vim htop net-tools ufw fail2ban
```

### 2. Configuration du réseau

```bash
# Vérifier l'IP publique
curl ifconfig.me

# Configuration DNS (exemple avec Cloudflare)
echo "nameserver 1.1.1.1" > /etc/resolv.conf
echo "nameserver 1.0.0.1" >> /etc/resolv.conf
```

### 3. Sécurité SSH

```bash
# Désactiver l'authentification par mot de passe (après avoir configuré les clés SSH)
nano /etc/ssh/sshd_config
# Modifier:
# PasswordAuthentication no
# PermitRootLogin no
# Port 2222  # Changer le port par défaut

# Redémarrer SSH
systemctl restart sshd
```

### 4. Configuration du pare-feu (UFW)

```bash
# Autoriser SSH (adapter au port configuré)
ufw allow 2222/tcp

# Autoriser HTTP/HTTPS
ufw allow 80/tcp
ufw allow 443/tcp

# Activer le pare-feu
ufw enable

# Vérifier le statut
ufw status verbose
```

### 5. Installation de Fail2Ban

```bash
# Installation
apt install fail2ban -y

# Configuration
cat > /etc/fail2ban/jail.local <<EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true
port = 2222
EOF

# Démarrer
systemctl enable fail2ban
systemctl start fail2ban
```

## Optimisation système

### 1. Limites de fichiers ouverts

```bash
# Augmenter les limites
cat >> /etc/security/limits.conf <<EOF
* soft nofile 65535
* hard nofile 65535
root soft nofile 65535
root hard nofile 65535
EOF

# Vérifier après reboot
ulimit -n
```

### 2. Optimisation réseau

```bash
cat >> /etc/sysctl.conf <<EOF
# Optimisations réseau pour MDM
net.core.somaxconn = 1024
net.ipv4.tcp_max_syn_backlog = 2048
net.ipv4.tcp_tw_reuse = 1
net.ipv4.ip_local_port_range = 10000 65535
EOF

# Appliquer
sysctl -p
```

### 3. Swap (si RAM < 16GB)

```bash
# Créer un fichier swap de 4GB
fallocate -l 4G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile

# Rendre permanent
echo '/swapfile none swap sw 0 0' >> /etc/fstab

# Vérifier
free -h
```

## Configuration DNS et certificats SSL

### Option 1: DNS géré (Cloudflare recommandé)

1. **Créer un compte Cloudflare** (gratuit)
2. **Ajouter votre domaine**
3. **Créer les enregistrements A**:
   ```
   android-mdm  →  IP_SERVEUR  (Proxy: Désactivé)
   ios-mdm      →  IP_SERVEUR  (Proxy: Désactivé)
   ```

### Option 2: DNS traditionnel

Chez votre registrar, créer les enregistrements:
```
android-mdm.votre-domaine.com  →  IP_SERVEUR
ios-mdm.votre-domaine.com      →  IP_SERVEUR
```

### Certificats SSL avec Let's Encrypt

```bash
# Installation Certbot
apt install certbot python3-certbot-nginx -y

# Arrêter temporairement les services pour libérer les ports
docker-compose down

# Générer les certificats
certbot certonly --standalone -d android-mdm.votre-domaine.com
certbot certonly --standalone -d ios-mdm.votre-domaine.com

# Copier les certificats dans le projet
mkdir -p /opt/mdm-integration/certs
cp /etc/letsencrypt/live/android-mdm.votre-domaine.com/fullchain.pem \
   /opt/mdm-integration/certs/server.crt
cp /etc/letsencrypt/live/android-mdm.votre-domaine.com/privkey.pem \
   /opt/mdm-integration/certs/server.key

# Renouvellement automatique
echo "0 0 * * 0 certbot renew --quiet && cp /etc/letsencrypt/live/android-mdm.votre-domaine.com/fullchain.pem /opt/mdm-integration/certs/server.crt && cp /etc/letsencrypt/live/android-mdm.votre-domaine.com/privkey.pem /opt/mdm-integration/certs/server.key && cd /opt/mdm-integration && docker-compose restart nginx" | crontab -
```

## Monitoring système

### Installation de monitoring de base

```bash
# Installation de htop et iotop
apt install htop iotop -y

# Installation de netdata (monitoring web)
bash <(curl -Ss https://my-netdata.io/kickstart.sh)

# Accès: http://IP_SERVEUR:19999
```

### Logs système

```bash
# Voir les logs système
journalctl -xe

# Logs Docker
docker-compose logs -f

# Logs spécifiques MDM
tail -f /opt/mdm-integration/integration/logs/*.log
```

## Backup automatisé

### Configuration de sauvegardes quotidiennes

```bash
# Créer un script de backup
cat > /usr/local/bin/mdm-backup.sh <<'EOF'
#!/bin/bash
cd /opt/mdm-integration
./maintenance.sh <<< "1"
EOF

chmod +x /usr/local/bin/mdm-backup.sh

# Ajouter au cron (tous les jours à 2h du matin)
echo "0 2 * * * /usr/local/bin/mdm-backup.sh" | crontab -

# Vérifier
crontab -l
```

### Stockage distant des backups

```bash
# Installation de rclone pour backup cloud
curl https://rclone.org/install.sh | bash

# Configuration (exemple avec AWS S3)
rclone config

# Script de synchronisation
cat > /usr/local/bin/mdm-backup-sync.sh <<'EOF'
#!/bin/bash
rclone sync /opt/mdm-backups remote:mdm-backups --transfers 4 --checkers 8
EOF

chmod +x /usr/local/bin/mdm-backup-sync.sh

# Ajouter au cron (après le backup quotidien)
echo "30 2 * * * /usr/local/bin/mdm-backup-sync.sh" | crontab -
```

## Haute disponibilité (optionnel)

### Configuration avec plusieurs serveurs

Pour une solution HA complète:

1. **Load Balancer** (HAProxy ou Nginx)
2. **PostgreSQL en cluster** (Patroni + etcd)
3. **Stockage partagé** (NFS ou GlusterFS)
4. **Réplication des données MDM**

Configuration complexe - consulter la documentation spécifique de chaque composant.

## Checklist de déploiement

- [ ] Serveur provisionné avec les specs recommandées
- [ ] Ubuntu Server 22.04 LTS installé et à jour
- [ ] SSH sécurisé (clés uniquement, port modifié)
- [ ] Pare-feu UFW configuré
- [ ] Fail2Ban actif
- [ ] DNS configuré correctement
- [ ] Certificats SSL obtenus et installés
- [ ] Docker et Docker Compose installés
- [ ] Projet MDM Integration déployé
- [ ] Fichier .env configuré avec les bonnes valeurs
- [ ] Services démarrés et fonctionnels
- [ ] Backups automatisés configurés
- [ ] Monitoring en place
- [ ] Tests de connectivité réussis
- [ ] Documentation d'accès sauvegardée

## Commandes utiles

```bash
# État des services Docker
docker-compose ps

# Utilisation des ressources
docker stats

# Logs en temps réel
docker-compose logs -f

# Redémarrer un service spécifique
docker-compose restart micromdm

# Voir l'espace disque
df -h

# Voir la RAM
free -h

# Processus les plus gourmands
htop

# Connexions réseau
netstat -tulpn

# Test de connectivité externe
curl -I https://android-mdm.votre-domaine.com
```

## Dépannage courant

### Problème: Services ne démarrent pas

```bash
# Vérifier les logs
docker-compose logs

# Vérifier l'espace disque
df -h

# Vérifier la RAM
free -h

# Redémarrer Docker
systemctl restart docker
```

### Problème: Certificats SSL expirés

```bash
# Renouveler manuellement
certbot renew

# Copier les nouveaux certificats
cp /etc/letsencrypt/live/*/fullchain.pem /opt/mdm-integration/certs/server.crt
cp /etc/letsencrypt/live/*/privkey.pem /opt/mdm-integration/certs/server.key

# Redémarrer Nginx
docker-compose restart nginx
```

### Problème: Base de données corrompue

```bash
# Arrêter les services
docker-compose down

# Restaurer depuis un backup
docker-compose up -d postgres
docker exec -i mdm-postgres psql -U hmdm hmdm < /opt/mdm-backups/postgres_YYYYMMDD.sql

# Redémarrer tous les services
docker-compose up -d
```

## Support

Pour toute question sur la configuration serveur, consulter:
- Documentation Ubuntu: https://help.ubuntu.com/
- Documentation Docker: https://docs.docker.com/
- Forum Tactical RMM: https://discord.gg/tacticalrmm
