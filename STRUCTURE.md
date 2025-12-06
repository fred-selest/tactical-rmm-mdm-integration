# Structure du projet MDM Integration

```
mdm-integration/
├── docker-compose.yml          # Configuration Docker Compose principale
├── nginx.conf                  # Configuration du reverse proxy Nginx
├── .env.example               # Variables d'environnement (à copier en .env)
├── README.md                  # Documentation principale
├── SERVER_CONFIG.md           # Guide de configuration serveur
├── deploy.sh                  # Script de déploiement automatisé
├── maintenance.sh             # Script de maintenance et backup
│
├── certs/                     # Certificats SSL (à créer)
│   ├── server.crt
│   └── server.key
│
└── integration/               # Service d'intégration Python
    ├── Dockerfile
    ├── requirements.txt
    └── mdm_sync.py            # Script principal de synchronisation
```

## Démarrage rapide

1. **Copier tous les fichiers sur votre serveur**
   ```bash
   scp -r mdm-integration/ user@votre-serveur:/opt/
   ```

2. **Se connecter au serveur**
   ```bash
   ssh user@votre-serveur
   cd /opt/mdm-integration
   ```

3. **Lancer le déploiement**
   ```bash
   chmod +x deploy.sh maintenance.sh
   ./deploy.sh
   ```

4. **Configurer .env avec vos valeurs**
   ```bash
   nano .env
   ```

5. **Redémarrer pour appliquer la config**
   ```bash
   docker-compose restart
   ```

## Points importants

### Sécurité
- ⚠️ Changez TOUS les mots de passe par défaut
- ⚠️ Utilisez des certificats SSL valides (Let's Encrypt)
- ⚠️ Configurez le pare-feu
- ⚠️ Mettez en place des backups automatiques

### Pour iOS/macOS (MicroMDM)
- Nécessite un compte Apple Developer (99$/an)
- Nécessite un certificat APNs
- Configuration Apple Business Manager requise

### Pour Android (Headwind MDM)
- Fonctionne immédiatement après déploiement
- Login par défaut: admin/admin (À CHANGER!)
- Téléchargez l'APK Launcher depuis l'interface web

### Intégration Tactical RMM
- Générez une API Key dans Tactical RMM
- Ajoutez-la dans le fichier .env
- La synchronisation démarre automatiquement

## Maintenance

Utilisez le script de maintenance pour:
- Créer des backups
- Voir les logs
- Redémarrer les services
- Mettre à jour les images

```bash
./maintenance.sh
```

## Support

- GitHub: https://github.com/fred-selest/tactical-rmm
- Documentation MicroMDM: https://github.com/micromdm/micromdm
- Documentation Headwind: https://h-mdm.com/documentation/
- Tactical RMM Discord: https://discord.gg/tacticalrmm
