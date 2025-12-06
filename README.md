# Intégration MDM avec Tactical RMM

Solution complète pour gérer des appareils mobiles (iOS/Android) et les intégrer à Tactical RMM.

## Architecture

- **MicroMDM** : Gestion des appareils iOS et macOS
- **Headwind MDM** : Gestion des appareils Android
- **Script d'intégration Python** : Synchronisation automatique vers Tactical RMM
- **Nginx** : Reverse proxy avec SSL/TLS
- **PostgreSQL** : Base de données pour Headwind MDM

## Prérequis

### Matériel recommandé

- **Serveur** : 
  - CPU : 4 cores minimum
  - RAM : 8 GB minimum (16 GB recommandé)
  - Stockage : 50 GB minimum (SSD recommandé)
  - Réseau : Connexion stable avec IP publique

### Logiciels

- Docker & Docker Compose installés
- Nom de domaine avec accès DNS
- Certificat SSL/TLS valide (Let's Encrypt recommandé)

### Pour iOS/macOS (MicroMDM)

- **Compte Apple Developer** (99$/an)
- **Apple Push Notification Certificate (APNs)**
- **Apple Business Manager** ou **Apple School Manager** (pour DEP)

## Installation rapide

### 1. Cloner et configurer

```bash
# Créer le répertoire
mkdir -p /opt/mdm-integration
cd /opt/mdm-integration

# Copier les fichiers de configuration
cp .env.example .env

# Éditer la configuration
nano .env
```

### 2. Générer les certificats SSL

#### Option A : Let's Encrypt (Recommandé pour production)

```bash
# Installer certbot
apt-get update
apt-get install certbot

# Générer les certificats
certbot certonly --standalone -d android-mdm.votre-domaine.com
certbot certonly --standalone -d ios-mdm.votre-domaine.com

# Copier les certificats
mkdir -p certs
cp /etc/letsencrypt/live/android-mdm.votre-domaine.com/fullchain.pem certs/server.crt
cp /etc/letsencrypt/live/android-mdm.votre-domaine.com/privkey.pem certs/server.key
```

#### Option B : Certificats auto-signés (Test uniquement)

```bash
mkdir -p certs
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout certs/server.key \
  -out certs/server.crt \
  -subj "/C=FR/ST=IDF/L=Paris/O=VotreEntreprise/CN=mdm.votre-domaine.com"
```

### 3. Configurer DNS

Créer les enregistrements A suivants :

```
android-mdm.votre-domaine.com  →  IP_SERVEUR
ios-mdm.votre-domaine.com      →  IP_SERVEUR
```

### 4. Démarrer les services

```bash
# Démarrer tous les services
docker-compose up -d

# Vérifier les logs
docker-compose logs -f

# Vérifier le statut
docker-compose ps
```

### 5. Configuration initiale

#### Headwind MDM (Android)

1. Accéder à `https://android-mdm.votre-domaine.com`
2. Connexion par défaut : `admin` / `admin`
3. **IMPORTANT** : Changer le mot de passe immédiatement
4. Configurer votre organisation
5. Télécharger l'APK du launcher Headwind MDM
6. Déployer sur vos appareils Android

#### MicroMDM (iOS/macOS)

1. **Obtenir le certificat APNs d'Apple** :
   - Aller sur https://identity.apple.com/pushcert/
   - Se connecter avec votre Apple ID développeur
   - Créer un nouveau certificat MDM
   - Télécharger le fichier `.pem`

2. **Configurer MicroMDM** :
```bash
# Se connecter au container
docker exec -it micromdm /bin/sh

# Importer le certificat APNs
mdmctl apply push-certificate -f /path/to/apns.pem
```

3. **Créer un profil d'enrollment** :
```bash
mdmctl apply enrollment-profile -name "Mon Entreprise"
```

### 6. Configuration Tactical RMM

1. Générer une API Key dans Tactical RMM :
   - Settings → Global Settings → API Keys
   - Créer une nouvelle clé avec permissions complètes

2. Mettre à jour le fichier `.env` :
```bash
TRMM_URL=https://votre-tactical-rmm.com
TRMM_API_KEY=votre-nouvelle-api-key
```

3. Redémarrer le service d'intégration :
```bash
docker-compose restart mdm-integration
```

## Configuration avancée

### Personnalisation de l'intervalle de synchronisation

Modifier dans `.env` :
```bash
# Synchronisation toutes les 5 minutes (300 secondes)
SYNC_INTERVAL=300
```

### Ajout de custom fields supplémentaires

Éditer `integration/mdm_sync.py` et ajouter vos champs dans la fonction `ensure_mdm_custom_fields()`.

### Configuration du pare-feu

```bash
# UFW (Ubuntu)
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 8080/tcp  # Headwind (si accès direct nécessaire)
ufw allow 8081/tcp  # MicroMDM (si accès direct nécessaire)
ufw enable
```

## Enrollment des appareils

### Android (Headwind MDM)

1. **Mode QR Code** (recommandé) :
   - Générer un QR code dans Headwind MDM
   - Lors du setup initial : Scanner le QR code pendant la configuration Android
   
2. **Installation manuelle** :
   - Télécharger l'APK Headwind Launcher
   - Installer sur l'appareil
   - Entrer l'URL du serveur et les credentials

### iOS/macOS (MicroMDM)

1. **Via Apple Business Manager** (recommandé) :
   - Configurer MicroMDM comme serveur MDM dans ABM
   - Assigner les appareils
   - Les appareils s'enrôlent automatiquement lors du setup

2. **Enrollment manuel** :
   - Télécharger le profil d'enrollment depuis MicroMDM
   - Installer le profil sur l'appareil iOS/macOS
   - Accepter l'installation du profil MDM

## Monitoring et maintenance

### Vérifier les logs

```bash
# Tous les services
docker-compose logs -f

# Service spécifique
docker-compose logs -f mdm-integration
docker-compose logs -f headwind-mdm
docker-compose logs -f micromdm

# Logs d'intégration
docker exec mdm-integration cat /var/log/mdm-integration/sync.log
```

### Backup

```bash
# Backup de la base de données
docker exec mdm-postgres pg_dump -U hmdm hmdm > backup_hmdm_$(date +%Y%m%d).sql

# Backup des données MicroMDM
docker run --rm -v mdm-integration_micromdm-data:/data -v $(pwd):/backup \
  ubuntu tar czf /backup/micromdm_backup_$(date +%Y%m%d).tar.gz /data

# Backup Headwind
docker run --rm -v mdm-integration_headwind-data:/data -v $(pwd):/backup \
  ubuntu tar czf /backup/headwind_backup_$(date +%Y%m%d).tar.gz /data
```

### Mise à jour

```bash
# Arrêter les services
docker-compose down

# Mettre à jour les images
docker-compose pull

# Redémarrer
docker-compose up -d
```

## Dépannage

### Les appareils n'apparaissent pas dans Tactical RMM

1. Vérifier que le service d'intégration tourne :
```bash
docker-compose ps mdm-integration
docker-compose logs mdm-integration
```

2. Vérifier la connectivité API :
```bash
# Depuis le container
docker exec -it mdm-integration python
>>> import requests
>>> requests.get('http://micromdm:8080/v1/devices', headers={'Authorization': 'Bearer YOUR_KEY'})
```

3. Vérifier les custom fields dans Tactical RMM :
   - Settings → Custom Fields
   - Chercher les champs commençant par `MDM_`

### Problèmes de connexion iOS

1. Vérifier le certificat APNs :
```bash
docker exec -it micromdm mdmctl get push-certificate
```

2. Vérifier les logs APNs :
```bash
docker-compose logs micromdm | grep -i apns
```

3. S'assurer que le port 443 est accessible depuis Internet

### Problèmes de connexion Android

1. Vérifier que Headwind MDM est accessible :
```bash
curl -k https://android-mdm.votre-domaine.com
```

2. Vérifier les logs :
```bash
docker-compose logs headwind-mdm
```

## Sécurité

### Recommandations

1. **Changer tous les mots de passe par défaut**
2. **Utiliser des certificats SSL valides** (Let's Encrypt)
3. **Configurer un pare-feu** (UFW/iptables)
4. **Mettre en place un VPN** pour l'accès admin (optionnel)
5. **Activer l'authentification 2FA** dans Tactical RMM
6. **Sauvegardes régulières** (automatisées avec cron)

### Rotation des API Keys

```bash
# Générer une nouvelle clé dans Tactical RMM
# Mettre à jour .env
nano .env

# Redémarrer
docker-compose restart mdm-integration
```

## Support et contribution

Pour toute question ou amélioration, ouvrir une issue sur le dépôt GitHub.

## Licence

Ce projet utilise des composants open-source :
- MicroMDM : Apache 2.0
- Headwind MDM : GPL v3
- Scripts d'intégration : MIT
