#!/bin/bash
#
# Script de déploiement automatisé pour l'intégration MDM
#

set -e

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Installation MDM Integration${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Vérification des prérequis
echo -e "${YELLOW}Vérification des prérequis...${NC}"

if ! command -v docker &> /dev/null; then
    echo -e "${RED}Docker n'est pas installé. Installation...${NC}"
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
fi

if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}Docker Compose n'est pas installé. Installation...${NC}"
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
fi

echo -e "${GREEN}✓ Prérequis vérifiés${NC}"
echo ""

# Configuration
echo -e "${YELLOW}Configuration...${NC}"

if [ ! -f .env ]; then
    cp .env.example .env
    echo -e "${YELLOW}Fichier .env créé. Veuillez le configurer avant de continuer.${NC}"
    echo -e "${YELLOW}Éditez le fichier avec: nano .env${NC}"
    echo -e "${RED}Arrêt du script. Relancez après configuration.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Configuration trouvée${NC}"
echo ""

# Création des répertoires
echo -e "${YELLOW}Création des répertoires...${NC}"
mkdir -p certs
mkdir -p integration/logs

echo -e "${GREEN}✓ Répertoires créés${NC}"
echo ""

# Génération de certificats SSL auto-signés si nécessaire
if [ ! -f certs/server.crt ] || [ ! -f certs/server.key ]; then
    echo -e "${YELLOW}Génération de certificats SSL auto-signés...${NC}"
    echo -e "${RED}ATTENTION: Utilisez Let's Encrypt en production!${NC}"
    
    read -p "Nom de domaine (ex: mdm.example.com): " DOMAIN
    
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout certs/server.key \
        -out certs/server.crt \
        -subj "/C=FR/ST=IDF/L=Paris/O=Organisation/CN=$DOMAIN"
    
    echo -e "${GREEN}✓ Certificats générés${NC}"
else
    echo -e "${GREEN}✓ Certificats SSL existants${NC}"
fi
echo ""

# Configuration du pare-feu
echo -e "${YELLOW}Configuration du pare-feu...${NC}"
if command -v ufw &> /dev/null; then
    echo -e "${YELLOW}UFW détecté. Configuration...${NC}"
    ufw allow 80/tcp
    ufw allow 443/tcp
    ufw --force enable
    echo -e "${GREEN}✓ Pare-feu configuré${NC}"
else
    echo -e "${YELLOW}UFW non installé. Configuration manuelle requise.${NC}"
fi
echo ""

# Mise à jour de nginx.conf avec le domaine
echo -e "${YELLOW}Configuration Nginx...${NC}"
if [ -n "$DOMAIN" ]; then
    sed -i "s/mdm.votre-domaine.com/$DOMAIN/g" nginx.conf
    sed -i "s/android-mdm.votre-domaine.com/android-$DOMAIN/g" nginx.conf
    sed -i "s/ios-mdm.votre-domaine.com/ios-$DOMAIN/g" nginx.conf
    echo -e "${GREEN}✓ Nginx configuré pour $DOMAIN${NC}"
fi
echo ""

# Démarrage des services
echo -e "${YELLOW}Démarrage des services Docker...${NC}"
docker-compose pull
docker-compose up -d

echo ""
echo -e "${GREEN}✓ Services démarrés${NC}"
echo ""

# Attendre que les services soient prêts
echo -e "${YELLOW}Attente du démarrage des services (30s)...${NC}"
sleep 30

# Vérification du statut
echo -e "${YELLOW}Vérification du statut...${NC}"
docker-compose ps

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Installation terminée!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}Prochaines étapes:${NC}"
echo ""
echo "1. Accédez à Headwind MDM (Android):"
echo -e "   ${GREEN}https://android-$DOMAIN${NC}"
echo -e "   Login par défaut: ${YELLOW}admin / admin${NC}"
echo ""
echo "2. Accédez à MicroMDM (iOS/macOS):"
echo -e "   ${GREEN}https://ios-$DOMAIN${NC}"
echo ""
echo "3. Configurez votre API Key Tactical RMM dans .env"
echo ""
echo "4. Consultez les logs:"
echo -e "   ${GREEN}docker-compose logs -f${NC}"
echo ""
echo -e "${RED}IMPORTANT: Changez tous les mots de passe par défaut!${NC}"
echo ""

# Afficher les logs en temps réel
echo -e "${YELLOW}Affichage des logs (Ctrl+C pour quitter)...${NC}"
docker-compose logs -f
