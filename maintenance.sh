#!/bin/bash
#
# Script de maintenance et backup pour MDM Integration
#

set -e

BACKUP_DIR="/opt/mdm-backups"
DATE=$(date +%Y%m%d_%H%M%S)

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}MDM Integration - Maintenance${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Menu
echo "Sélectionnez une action:"
echo "1. Backup complet"
echo "2. Restaurer un backup"
echo "3. Afficher les logs"
echo "4. Redémarrer les services"
echo "5. Mettre à jour les images Docker"
echo "6. Vérifier l'état des services"
echo "7. Nettoyer les anciens backups (>30 jours)"
echo "8. Tester la connectivité API"
echo "9. Quitter"
echo ""
read -p "Votre choix: " choice

case $choice in
    1)
        echo -e "${YELLOW}Création d'un backup complet...${NC}"
        mkdir -p $BACKUP_DIR
        
        # Backup PostgreSQL
        echo -e "${YELLOW}Backup de la base de données...${NC}"
        docker exec mdm-postgres pg_dump -U hmdm hmdm > "$BACKUP_DIR/postgres_$DATE.sql"
        
        # Backup MicroMDM data
        echo -e "${YELLOW}Backup des données MicroMDM...${NC}"
        docker run --rm -v mdm-integration_micromdm-data:/data -v $BACKUP_DIR:/backup \
            ubuntu tar czf /backup/micromdm_$DATE.tar.gz /data
        
        # Backup Headwind data
        echo -e "${YELLOW}Backup des données Headwind...${NC}"
        docker run --rm -v mdm-integration_headwind-data:/data -v $BACKUP_DIR:/backup \
            ubuntu tar czf /backup/headwind_$DATE.tar.gz /data
        
        # Backup configuration
        echo -e "${YELLOW}Backup de la configuration...${NC}"
        tar czf "$BACKUP_DIR/config_$DATE.tar.gz" .env docker-compose.yml nginx.conf
        
        echo -e "${GREEN}✓ Backup terminé: $BACKUP_DIR${NC}"
        ls -lh $BACKUP_DIR/*$DATE*
        ;;
    
    2)
        echo -e "${YELLOW}Backups disponibles:${NC}"
        ls -lh $BACKUP_DIR/
        echo ""
        read -p "Date du backup à restaurer (YYYYMMDD_HHMMSS): " restore_date
        
        if [ -f "$BACKUP_DIR/postgres_$restore_date.sql" ]; then
            echo -e "${YELLOW}Restauration de la base de données...${NC}"
            docker exec -i mdm-postgres psql -U hmdm hmdm < "$BACKUP_DIR/postgres_$restore_date.sql"
            echo -e "${GREEN}✓ Base de données restaurée${NC}"
        else
            echo -e "${RED}Backup non trouvé${NC}"
        fi
        ;;
    
    3)
        echo -e "${YELLOW}Affichage des logs...${NC}"
        echo "1. Tous les services"
        echo "2. MDM Integration"
        echo "3. Headwind MDM"
        echo "4. MicroMDM"
        echo "5. Nginx"
        read -p "Votre choix: " log_choice
        
        case $log_choice in
            1) docker-compose logs -f ;;
            2) docker-compose logs -f mdm-integration ;;
            3) docker-compose logs -f headwind-mdm ;;
            4) docker-compose logs -f micromdm ;;
            5) docker-compose logs -f nginx ;;
        esac
        ;;
    
    4)
        echo -e "${YELLOW}Redémarrage des services...${NC}"
        docker-compose restart
        echo -e "${GREEN}✓ Services redémarrés${NC}"
        docker-compose ps
        ;;
    
    5)
        echo -e "${YELLOW}Mise à jour des images Docker...${NC}"
        docker-compose pull
        echo -e "${YELLOW}Redémarrage avec les nouvelles images...${NC}"
        docker-compose up -d
        echo -e "${GREEN}✓ Mise à jour terminée${NC}"
        ;;
    
    6)
        echo -e "${YELLOW}État des services:${NC}"
        docker-compose ps
        echo ""
        echo -e "${YELLOW}Utilisation des ressources:${NC}"
        docker stats --no-stream
        ;;
    
    7)
        echo -e "${YELLOW}Nettoyage des backups de plus de 30 jours...${NC}"
        find $BACKUP_DIR -type f -mtime +30 -delete
        echo -e "${GREEN}✓ Nettoyage terminé${NC}"
        ;;
    
    8)
        echo -e "${YELLOW}Test de connectivité API...${NC}"
        
        # Charger les variables
        source .env
        
        # Test Tactical RMM
        echo -e "${YELLOW}Test Tactical RMM API...${NC}"
        curl -s -H "X-API-KEY: $TRMM_API_KEY" "$TRMM_URL/api/v3/agents/" | head -c 100
        echo ""
        
        # Test MicroMDM
        echo -e "${YELLOW}Test MicroMDM API...${NC}"
        curl -s -H "Authorization: Bearer $MICROMDM_API_KEY" "http://localhost:8081/v1/devices" | head -c 100
        echo ""
        
        # Test Headwind
        echo -e "${YELLOW}Test Headwind MDM...${NC}"
        curl -s "http://localhost:8080" | head -c 100
        echo ""
        
        echo -e "${GREEN}✓ Tests terminés${NC}"
        ;;
    
    9)
        echo -e "${GREEN}Au revoir!${NC}"
        exit 0
        ;;
    
    *)
        echo -e "${RED}Choix invalide${NC}"
        ;;
esac
