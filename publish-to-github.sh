#!/bin/bash
#
# Script pour publier automatiquement sur GitHub
# Usage: ./publish-to-github.sh [nom-du-repo]
#

set -e

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Publication sur GitHub${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Vérifier si Git est installé
if ! command -v git &> /dev/null; then
    echo -e "${RED}Git n'est pas installé. Installation...${NC}"
    sudo apt update && sudo apt install git -y
fi

# Demander le nom du dépôt
if [ -z "$1" ]; then
    read -p "Nom du dépôt GitHub (ex: tactical-rmm-mdm-integration): " REPO_NAME
else
    REPO_NAME="$1"
fi

# Demander le username GitHub
read -p "Votre username GitHub (défaut: fred-selest): " GITHUB_USER
GITHUB_USER=${GITHUB_USER:-fred-selest}

# URL du dépôt
REPO_URL="https://github.com/$GITHUB_USER/$REPO_NAME.git"

echo ""
echo -e "${YELLOW}Configuration:${NC}"
echo -e "  Dépôt: ${GREEN}$REPO_NAME${NC}"
echo -e "  User: ${GREEN}$GITHUB_USER${NC}"
echo -e "  URL: ${GREEN}$REPO_URL${NC}"
echo ""

read -p "Continuer ? (o/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Oo]$ ]]; then
    echo -e "${RED}Annulé.${NC}"
    exit 1
fi

# Configurer Git (si pas déjà fait)
if [ -z "$(git config --global user.name)" ]; then
    read -p "Votre nom pour Git: " GIT_NAME
    git config --global user.name "$GIT_NAME"
fi

if [ -z "$(git config --global user.email)" ]; then
    read -p "Votre email pour Git: " GIT_EMAIL
    git config --global user.email "$GIT_EMAIL"
fi

# Initialiser Git si nécessaire
if [ ! -d .git ]; then
    echo -e "${YELLOW}Initialisation du dépôt Git...${NC}"
    git init
    echo -e "${GREEN}✓ Dépôt Git initialisé${NC}"
fi

# Copier le README optimisé pour GitHub
if [ -f README_GITHUB.md ]; then
    cp README_GITHUB.md README.md
    echo -e "${GREEN}✓ README.md optimisé pour GitHub${NC}"
fi

# Créer le .gitignore s'il n'existe pas
if [ ! -f .gitignore ]; then
    echo -e "${YELLOW}Création du .gitignore...${NC}"
    cat > .gitignore <<'EOF'
# Fichiers sensibles
.env
*.env
!.env.example
certs/*.key
certs/*.pem

# Logs et données
*.log
logs/
**/data/
volumes/
backups/

# Python
__pycache__/
*.pyc
.venv/
venv/

# OS
.DS_Store
Thumbs.db
EOF
    echo -e "${GREEN}✓ .gitignore créé${NC}"
fi

# Vérifier que les fichiers sensibles ne sont pas inclus
echo -e "${YELLOW}Vérification des fichiers sensibles...${NC}"
if [ -f .env ] && ! grep -q "^\.env$" .gitignore; then
    echo -e "${RED}ATTENTION: .env n'est pas dans .gitignore !${NC}"
    exit 1
fi

# Ajouter tous les fichiers
echo -e "${YELLOW}Ajout des fichiers...${NC}"
git add .

# Créer le commit initial
echo -e "${YELLOW}Création du commit...${NC}"
git commit -m "Initial commit - MDM Integration pour Tactical RMM

Solution complète pour gérer les appareils mobiles (iOS/Android)
et les intégrer automatiquement à Tactical RMM.

Fonctionnalités:
- MicroMDM pour iOS/macOS
- Headwind MDM pour Android
- Script Python de synchronisation automatique
- Configuration Docker Compose complète
- Scripts de déploiement et maintenance
- Documentation complète en français

Licence: MIT
" || echo -e "${YELLOW}Commit déjà existant, on continue...${NC}"

# Créer la branche main
git branch -M main

# Ajouter le remote
echo -e "${YELLOW}Configuration du remote GitHub...${NC}"
if git remote | grep -q origin; then
    git remote remove origin
fi
git remote add origin "$REPO_URL"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Prêt à pousser sur GitHub !${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}Étapes restantes:${NC}"
echo ""
echo "1. Créer le dépôt sur GitHub:"
echo -e "   ${GREEN}https://github.com/new${NC}"
echo -e "   Nom: ${GREEN}$REPO_NAME${NC}"
echo "   (NE PAS initialiser avec README/LICENSE)"
echo ""
echo "2. Puis exécuter:"
echo -e "   ${GREEN}git push -u origin main${NC}"
echo ""
echo "3. Si vous avez l'authentification 2FA, utilisez un token:"
echo "   https://github.com/settings/tokens"
echo ""

read -p "Voulez-vous pousser maintenant ? (o/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Oo]$ ]]; then
    echo -e "${YELLOW}Push vers GitHub...${NC}"
    git push -u origin main
    
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}✓ Publié avec succès !${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "Votre dépôt: ${GREEN}https://github.com/$GITHUB_USER/$REPO_NAME${NC}"
    echo ""
else
    echo ""
    echo -e "${YELLOW}Pour pousser plus tard:${NC}"
    echo -e "  ${GREEN}git push -u origin main${NC}"
    echo ""
fi

# Créer un tag
read -p "Voulez-vous créer un tag v1.0.0 ? (o/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Oo]$ ]]; then
    git tag -a v1.0.0 -m "Release v1.0.0 - MDM Integration

Solution complète pour Tactical RMM:
- MicroMDM (iOS/macOS)
- Headwind MDM (Android)
- Synchronisation automatique
- Documentation complète
"
    git push origin v1.0.0
    echo -e "${GREEN}✓ Tag v1.0.0 créé et poussé${NC}"
fi

echo ""
echo -e "${GREEN}Terminé ! 🚀${NC}"
