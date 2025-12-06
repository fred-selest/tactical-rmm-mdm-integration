#!/usr/bin/env python3
"""
Script d'intégration MDM -> Tactical RMM
Synchronise les appareils mobiles (iOS/Android) vers Tactical RMM
"""

import os
import sys
import time
import logging
import requests
import schedule
from datetime import datetime
from typing import List, Dict, Optional

# Configuration du logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/var/log/mdm-integration/sync.log'),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)

# Configuration depuis les variables d'environnement
TRMM_URL = os.getenv('TRMM_URL')
TRMM_API_KEY = os.getenv('TRMM_API_KEY')
MICROMDM_URL = os.getenv('MICROMDM_URL')
MICROMDM_API_KEY = os.getenv('MICROMDM_API_KEY')
HEADWIND_URL = os.getenv('HEADWIND_URL')
HEADWIND_USER = os.getenv('HEADWIND_USER')
HEADWIND_PASSWORD = os.getenv('HEADWIND_PASSWORD')
SYNC_INTERVAL = int(os.getenv('SYNC_INTERVAL', 300))  # 5 minutes par défaut


class TacticalRMMClient:
    """Client pour l'API Tactical RMM"""
    
    def __init__(self, url: str, api_key: str):
        self.url = url.rstrip('/')
        self.api_key = api_key
        self.headers = {
            'X-API-KEY': api_key,
            'Content-Type': 'application/json'
        }
    
    def get_custom_fields(self) -> List[Dict]:
        """Récupère la liste des custom fields"""
        try:
            response = requests.get(
                f'{self.url}/api/v3/core/customfields/',
                headers=self.headers,
                timeout=30
            )
            response.raise_for_status()
            return response.json()
        except Exception as e:
            logger.error(f"Erreur lors de la récupération des custom fields: {e}")
            return []
    
    def create_custom_field(self, field_data: Dict) -> bool:
        """Crée un custom field"""
        try:
            response = requests.post(
                f'{self.url}/api/v3/core/customfields/',
                headers=self.headers,
                json=field_data,
                timeout=30
            )
            response.raise_for_status()
            logger.info(f"Custom field créé: {field_data['name']}")
            return True
        except Exception as e:
            logger.error(f"Erreur lors de la création du custom field: {e}")
            return False
    
    def ensure_mdm_custom_fields(self):
        """S'assure que les custom fields MDM existent"""
        required_fields = [
            {
                'name': 'MDM_Device_Type',
                'field_type': 'text',
                'model': 'agent',
                'default_value_string': ''
            },
            {
                'name': 'MDM_Device_Name',
                'field_type': 'text',
                'model': 'agent',
                'default_value_string': ''
            },
            {
                'name': 'MDM_OS_Version',
                'field_type': 'text',
                'model': 'agent',
                'default_value_string': ''
            },
            {
                'name': 'MDM_Serial_Number',
                'field_type': 'text',
                'model': 'agent',
                'default_value_string': ''
            },
            {
                'name': 'MDM_Last_Seen',
                'field_type': 'text',
                'model': 'agent',
                'default_value_string': ''
            },
            {
                'name': 'MDM_Battery_Level',
                'field_type': 'text',
                'model': 'agent',
                'default_value_string': ''
            },
            {
                'name': 'MDM_Managed',
                'field_type': 'checkbox',
                'model': 'agent',
                'default_value_bool': False
            },
            {
                'name': 'MDM_Platform',
                'field_type': 'text',
                'model': 'agent',
                'default_value_string': ''
            }
        ]
        
        existing_fields = self.get_custom_fields()
        existing_names = [f['name'] for f in existing_fields]
        
        for field in required_fields:
            if field['name'] not in existing_names:
                self.create_custom_field(field)
    
    def update_agent_custom_field(self, agent_id: str, field_name: str, value: any) -> bool:
        """Met à jour un custom field pour un agent"""
        try:
            response = requests.patch(
                f'{self.url}/api/v3/agents/{agent_id}/',
                headers=self.headers,
                json={
                    'custom_fields': {
                        field_name: value
                    }
                },
                timeout=30
            )
            response.raise_for_status()
            return True
        except Exception as e:
            logger.error(f"Erreur lors de la mise à jour de l'agent {agent_id}: {e}")
            return False
    
    def get_agents(self) -> List[Dict]:
        """Récupère la liste des agents"""
        try:
            response = requests.get(
                f'{self.url}/api/v3/agents/',
                headers=self.headers,
                timeout=30
            )
            response.raise_for_status()
            return response.json()
        except Exception as e:
            logger.error(f"Erreur lors de la récupération des agents: {e}")
            return []


class MicroMDMClient:
    """Client pour l'API MicroMDM (iOS/macOS)"""
    
    def __init__(self, url: str, api_key: str):
        self.url = url.rstrip('/')
        self.api_key = api_key
        self.headers = {
            'Authorization': f'Bearer {api_key}',
            'Content-Type': 'application/json'
        }
    
    def get_devices(self) -> List[Dict]:
        """Récupère la liste des appareils iOS/macOS"""
        try:
            response = requests.get(
                f'{self.url}/v1/devices',
                headers=self.headers,
                timeout=30
            )
            response.raise_for_status()
            devices = response.json().get('devices', [])
            logger.info(f"Récupéré {len(devices)} appareils iOS/macOS")
            return devices
        except Exception as e:
            logger.error(f"Erreur lors de la récupération des appareils MicroMDM: {e}")
            return []
    
    def format_device_for_trmm(self, device: Dict) -> Dict:
        """Formate un appareil MicroMDM pour Tactical RMM"""
        return {
            'device_type': 'iOS' if device.get('product', '').startswith('iPhone') else 'macOS',
            'device_name': device.get('device_name', 'Unknown'),
            'os_version': device.get('os_version', 'Unknown'),
            'serial_number': device.get('serial_number', ''),
            'last_seen': device.get('last_seen', ''),
            'battery_level': device.get('battery_level', 'N/A'),
            'managed': True,
            'platform': 'Apple',
            'udid': device.get('udid', '')
        }


class HeadwindMDMClient:
    """Client pour l'API Headwind MDM (Android)"""
    
    def __init__(self, url: str, username: str, password: str):
        self.url = url.rstrip('/')
        self.username = username
        self.password = password
        self.session = requests.Session()
        self.login()
    
    def login(self) -> bool:
        """Authentification sur Headwind MDM"""
        try:
            response = self.session.post(
                f'{self.url}/rest/public/auth',
                json={
                    'login': self.username,
                    'password': self.password
                },
                timeout=30
            )
            response.raise_for_status()
            logger.info("Authentification Headwind MDM réussie")
            return True
        except Exception as e:
            logger.error(f"Erreur d'authentification Headwind MDM: {e}")
            return False
    
    def get_devices(self) -> List[Dict]:
        """Récupère la liste des appareils Android"""
        try:
            response = self.session.get(
                f'{self.url}/rest/private/devices',
                timeout=30
            )
            response.raise_for_status()
            devices = response.json().get('data', [])
            logger.info(f"Récupéré {len(devices)} appareils Android")
            return devices
        except Exception as e:
            logger.error(f"Erreur lors de la récupération des appareils Headwind: {e}")
            return []
    
    def format_device_for_trmm(self, device: Dict) -> Dict:
        """Formate un appareil Headwind pour Tactical RMM"""
        return {
            'device_type': 'Android',
            'device_name': device.get('deviceName', 'Unknown'),
            'os_version': f"Android {device.get('androidVersion', 'Unknown')}",
            'serial_number': device.get('serial', ''),
            'last_seen': device.get('lastUpdate', ''),
            'battery_level': f"{device.get('batteryLevel', 'N/A')}%",
            'managed': True,
            'platform': 'Android',
            'imei': device.get('imei', '')
        }


class MDMIntegrationService:
    """Service principal d'intégration"""
    
    def __init__(self):
        self.trmm = TacticalRMMClient(TRMM_URL, TRMM_API_KEY)
        self.micromdm = MicroMDMClient(MICROMDM_URL, MICROMDM_API_KEY)
        self.headwind = HeadwindMDMClient(HEADWIND_URL, HEADWIND_USER, HEADWIND_PASSWORD)
        
        # S'assurer que les custom fields existent
        logger.info("Vérification des custom fields...")
        self.trmm.ensure_mdm_custom_fields()
    
    def sync_devices(self):
        """Synchronise tous les appareils MDM vers Tactical RMM"""
        logger.info("===== Début de la synchronisation MDM =====")
        
        # Récupération des appareils iOS/macOS
        ios_devices = self.micromdm.get_devices()
        for device in ios_devices:
            formatted = self.micromdm.format_device_for_trmm(device)
            self.update_device_in_trmm(formatted)
        
        # Récupération des appareils Android
        android_devices = self.headwind.get_devices()
        for device in android_devices:
            formatted = self.headwind.format_device_for_trmm(device)
            self.update_device_in_trmm(formatted)
        
        logger.info(f"Synchronisation terminée: {len(ios_devices)} iOS/macOS, {len(android_devices)} Android")
    
    def update_device_in_trmm(self, device_data: Dict):
        """Met à jour ou crée un appareil dans Tactical RMM"""
        # Note: Tactical RMM n'a pas d'API directe pour créer des "agents" mobiles
        # Cette approche utilise les custom fields sur des agents existants
        # Vous devrez adapter selon votre structure
        
        logger.info(f"Mise à jour de l'appareil: {device_data['device_name']} ({device_data['device_type']})")
        
        # Chercher un agent correspondant par serial number ou créer une entrée
        agents = self.trmm.get_agents()
        matching_agent = None
        
        for agent in agents:
            if agent.get('MDM_Serial_Number') == device_data['serial_number']:
                matching_agent = agent
                break
        
        if matching_agent:
            # Mise à jour des custom fields
            agent_id = matching_agent['agent_id']
            self.trmm.update_agent_custom_field(agent_id, 'MDM_Device_Type', device_data['device_type'])
            self.trmm.update_agent_custom_field(agent_id, 'MDM_Device_Name', device_data['device_name'])
            self.trmm.update_agent_custom_field(agent_id, 'MDM_OS_Version', device_data['os_version'])
            self.trmm.update_agent_custom_field(agent_id, 'MDM_Last_Seen', device_data['last_seen'])
            self.trmm.update_agent_custom_field(agent_id, 'MDM_Battery_Level', device_data['battery_level'])
            self.trmm.update_agent_custom_field(agent_id, 'MDM_Managed', True)
            self.trmm.update_agent_custom_field(agent_id, 'MDM_Platform', device_data['platform'])
            logger.info(f"Agent mis à jour: {agent_id}")
        else:
            logger.warning(f"Aucun agent correspondant trouvé pour {device_data['serial_number']}")


def main():
    """Fonction principale"""
    logger.info("Démarrage du service d'intégration MDM")
    
    # Vérification de la configuration
    if not all([TRMM_URL, TRMM_API_KEY, MICROMDM_URL, MICROMDM_API_KEY, HEADWIND_URL, HEADWIND_USER, HEADWIND_PASSWORD]):
        logger.error("Configuration incomplète. Vérifiez les variables d'environnement.")
        sys.exit(1)
    
    # Initialisation du service
    service = MDMIntegrationService()
    
    # Synchronisation immédiate au démarrage
    service.sync_devices()
    
    # Planification des synchronisations régulières
    schedule.every(SYNC_INTERVAL).seconds.do(service.sync_devices)
    
    logger.info(f"Service démarré. Synchronisation toutes les {SYNC_INTERVAL} secondes.")
    
    # Boucle principale
    while True:
        try:
            schedule.run_pending()
            time.sleep(1)
        except KeyboardInterrupt:
            logger.info("Arrêt du service...")
            break
        except Exception as e:
            logger.error(f"Erreur dans la boucle principale: {e}")
            time.sleep(60)


if __name__ == '__main__':
    main()
