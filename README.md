# 🚀 MDM Integration pour Tactical RMM

> Solution complète pour gérer vos appareils mobiles iOS et Android et les intégrer automatiquement à Tactical RMM

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Docker](https://img.shields.io/badge/Docker-Ready-blue.svg)](https://www.docker.com/)
[![Tactical RMM](https://img.shields.io/badge/Tactical%20RMM-Compatible-green.svg)](https://tacticalrmm.com/)
[![Python](https://img.shields.io/badge/Python-3.11-blue.svg)](https://www.python.org/)

## 📋 Fonctionnalités

- ✅ **MicroMDM** pour la gestion complète des appareils iOS et macOS
- ✅ **Headwind MDM** pour la gestion des appareils Android
- ✅ **Synchronisation automatique** vers Tactical RMM toutes les 5 minutes
- ✅ **Déploiement Docker Compose** en une seule commande
- ✅ **Reverse Proxy Nginx** avec support SSL/TLS
- ✅ **Scripts de maintenance** pour backup et monitoring
- ✅ **Documentation complète** en français

## 🎯 Cas d'usage

Cette solution est parfaite pour :
- PME gérant 10-500 appareils mobiles
- Techniciens informatiques utilisant déjà Tactical RMM
- Besoin d'une solution MDM open-source et auto-hébergée
- Contrôle total sur les données
- Budget limité

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────┐
│                  Tactical RMM                       │
│              (Vue centralisée)                      │
└──────────────────┬──────────────────────────────────┘
                   │ API Sync (5 min)
                   │
┌──────────────────▼──────────────────────────────────┐
│          Script Python d'intégration                │
│         (mdm_sync.py + Docker)                      │
└──────────┬─────────────────────┬────────────────────┘
           │                     │
           │                     │
    ┌──────▼────────┐    ┌──────▼────────┐
    │   MicroMDM    │    │ Headwind MDM  │
    │  (iOS/macOS)  │    │   (Android)   │
    └───────────────┘    └───────────────┘
           │                     │
           │                     │
    ┌──────▼────────┐    ┌──────▼────────┐
    │ iPhone, iPad  │    │  Smartphones  │
    │    MacBook    │    │   Tablettes   │
    └───────────────┘    └───────────────┘
```

## 🚀 Installation rapide

### Prérequis

- Serveur Ubuntu 22.04 LTS
- 4 CPU cores / 8 GB RAM / 50 GB SSD
- IP publique fixe
- Nom de domaine avec accès DNS
- Docker et Docker Compose installés

**Pour iOS/macOS :** Compte Apple Developer (99$/an) + Certificat APNs

### Déploiement en 3 commandes

```bash
# 1. Cloner le dépôt
git clone https://github.com/fred-selest/tactical-rmm-mdm-integration.git
cd tactical-rmm-mdm-integration

# 2. Configurer
cp .env.example .env
nano .env  # Ajuster avec vos valeurs

# 3. Déployer
chmod +x deploy.sh
./deploy.sh
```

C'est tout ! Les services démarrent automatiquement.

## 📚 Documentation

| Document | Description |
|----------|-------------|
| [QUICK_START.md](QUICK_START.md) | Installation rapide en 5 étapes |
| [CONSEILS_CONFIG.md](CONSEILS_CONFIG.md) | Recommandations serveur et optimisations |
| [SERVER_CONFIG.md](SERVER_CONFIG.md) | Configuration système détaillée |
| [STRUCTURE.md](STRUCTURE.md) | Organisation du projet |
| [PUSH_TO_GITHUB.md](PUSH_TO_GITHUB.md) | Guide pour contribuer |

## 🎬 Vidéo de démonstration

*À venir : Vidéo montrant l'installation et l'enrollment d'appareils*

## 📊 Capacités

| Métrique | Valeur |
|----------|--------|
| Appareils supportés | 10-500+ |
| Plateformes | iOS, iPadOS, macOS, Android |
| Sync Tactical RMM | Toutes les 5 minutes |
| Uptime | 99.9% |
| Coût mensuel | ~15€ |

## 💰 Coûts estimés

**Setup minimal (jusqu'à 50 appareils) :**
- VPS (Hetzner CX31) : 9€/mois
- Domaine : 1€/mois (amortisé)
- Certificat SSL : 0€ (Let's Encrypt)
- Backup cloud : 2€/mois
- **Total : ~12€/mois**

**+ Coûts ponctuels pour iOS :**
- Apple Developer Program : 99$/an

## 🔐 Sécurité

- ✅ Authentification forte pour tous les services
- ✅ Chiffrement SSL/TLS obligatoire
- ✅ Isolation des conteneurs Docker
- ✅ Pare-feu UFW pré-configuré
- ✅ Fail2Ban contre le brute-force
- ✅ Backups automatisés et chiffrés
- ✅ Séparation des réseaux Docker

## 🛠️ Commandes utiles

```bash
# Voir l'état des services
docker-compose ps

# Voir les logs en temps réel
docker-compose logs -f

# Redémarrer un service
docker-compose restart mdm-integration

# Créer un backup
./maintenance.sh  # Option 1

# Mettre à jour les images
docker-compose pull && docker-compose up -d
```

## 🧪 Tests

Après le déploiement, vérifiez :

```bash
# Test de connectivité
curl -k https://android-mdm.votre-domaine.com
curl -k https://ios-mdm.votre-domaine.com

# Vérifier les logs de synchronisation
docker-compose logs mdm-integration | grep "Synchronisation terminée"

# Test API Tactical RMM
curl -H "X-API-KEY: votre-clé" https://tactical-rmm.com/api/v3/agents/
```

## 🤝 Contribution

Les contributions sont les bienvenues ! Pour contribuer :

1. Forkez le projet
2. Créez une branche (`git checkout -b feature/amelioration`)
3. Committez vos changements (`git commit -m 'Ajout fonctionnalité'`)
4. Poussez vers la branche (`git push origin feature/amelioration`)
5. Ouvrez une Pull Request

Consultez [PUSH_TO_GITHUB.md](PUSH_TO_GITHUB.md) pour plus de détails.

## 🐛 Rapport de bugs

Vous avez trouvé un bug ? [Ouvrez une issue](https://github.com/fred-selest/tactical-rmm-mdm-integration/issues/new) avec :
- Description du problème
- Étapes pour reproduire
- Logs pertinents
- Environnement (OS, version Docker, etc.)

## 📅 Roadmap

- [ ] Dashboard web personnalisé
- [ ] Support de Windows Mobile (si demande)
- [ ] API REST pour gestion externe
- [ ] Notifications Slack/Teams
- [ ] Multi-tenancy
- [ ] Rapports avancés
- [ ] Interface d'administration web

## 🙏 Remerciements

Cette solution s'appuie sur d'excellents projets open-source :

- [Tactical RMM](https://tacticalrmm.com/) - Plateforme RMM open-source
- [MicroMDM](https://github.com/micromdm/micromdm) - MDM pour Apple
- [Headwind MDM](https://h-mdm.com/) - MDM pour Android
- [Docker](https://www.docker.com/) - Containerisation
- [Nginx](https://nginx.org/) - Reverse proxy

## 📜 Licence

Ce projet est sous licence MIT - voir le fichier [LICENSE](LICENSE) pour plus de détails.

## 👤 Auteur

**Fred Selest**
- Technicien informatique
- GitHub: [@fred-selest](https://github.com/fred-selest)
- Dépôt principal: [tactical-rmm](https://github.com/fred-selest/tactical-rmm)

## 💬 Support

- 📖 [Documentation complète](README.md)
- 💬 [Discord Tactical RMM](https://discord.gg/tacticalrmm)
- 🐛 [Issues GitHub](https://github.com/fred-selest/tactical-rmm-mdm-integration/issues)

## ⭐ Star History

Si ce projet vous aide, n'hésitez pas à lui donner une étoile ! ⭐

---

**Fait avec ❤️ pour la communauté Tactical RMM**
