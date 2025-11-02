#!/bin/bash

# 🚀 Script de Démarrage du Système MeRecharge CallBox
# Ce script démarre le backend et guide pour démarrer l'app Flutter

clear
echo "╔════════════════════════════════════════════════════════════╗"
echo "║   🚀 DÉMARRAGE SYSTÈME MERECHARGE CALLBOX                 ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Couleurs
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Vérifier que nous sommes dans le bon répertoire
if [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}❌ Erreur: Exécutez ce script depuis le répertoire merecharge_ussd_gateway${NC}"
    exit 1
fi

echo -e "${BLUE}📍 Configuration actuelle:${NC}"
echo "   Backend: /Users/serge/Desktop/merecharge_backend (Port 3000)"
echo "   CallBox: /Users/serge/Desktop/merecharge_ussd_gateway (Port 8080)"
echo "   IP Mac: 192.168.1.26"
echo ""

# Étape 1: Vérifier si le backend tourne déjà
echo -e "${YELLOW}🔍 Étape 1/4: Vérification du backend...${NC}"
if lsof -i :3000 > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Backend déjà en cours d'exécution sur le port 3000${NC}"
    curl -s http://localhost:3000/ > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Backend répond correctement${NC}"
    else
        echo -e "${RED}⚠️  Backend tourne mais ne répond pas${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Backend non démarré${NC}"
    echo ""
    echo -e "${BLUE}Pour démarrer le backend, ouvrez un NOUVEAU TERMINAL et exécutez:${NC}"
    echo ""
    echo -e "${GREEN}cd /Users/serge/Desktop/merecharge_backend${NC}"
    echo -e "${GREEN}npm start${NC}"
    echo ""
    echo -e "${YELLOW}Appuyez sur ENTRÉE une fois le backend démarré...${NC}"
    read -r
    
    # Vérifier à nouveau
    if lsof -i :3000 > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Backend détecté !${NC}"
    else
        echo -e "${RED}❌ Backend toujours non détecté. Assurez-vous qu'il tourne.${NC}"
        echo "   Continuons quand même..."
    fi
fi
echo ""

# Étape 2: Tester l'intégration
echo -e "${YELLOW}🧪 Étape 2/4: Test de l'intégration...${NC}"
if [ -f "./test_integration.sh" ]; then
    echo "Lancement des tests..."
    ./test_integration.sh
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Tests d'intégration réussis${NC}"
    else
        echo -e "${YELLOW}⚠️  Certains tests ont échoué (peut-être normal si c'est le premier démarrage)${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Script de test non trouvé, on continue...${NC}"
fi
echo ""

# Étape 3: Vérifier les dépendances Flutter
echo -e "${YELLOW}📦 Étape 3/4: Vérification des dépendances Flutter...${NC}"
if [ -d "build" ]; then
    echo -e "${GREEN}✅ Projet Flutter déjà configuré${NC}"
else
    echo "Installation des dépendances..."
    flutter pub get
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Dépendances installées${NC}"
    else
        echo -e "${RED}❌ Erreur lors de l'installation des dépendances${NC}"
        exit 1
    fi
fi
echo ""

# Étape 4: Vérifier les appareils disponibles
echo -e "${YELLOW}📱 Étape 4/4: Vérification des appareils...${NC}"
flutter devices
echo ""

# Instructions finales
echo "╔════════════════════════════════════════════════════════════╗"
echo "║   ✅ SYSTÈME PRÊT À DÉMARRER                              ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo -e "${BLUE}🎯 Pour démarrer l'application CallBox:${NC}"
echo ""
echo -e "${GREEN}flutter run${NC}"
echo ""
echo "Ou pour un appareil spécifique:"
echo -e "${GREEN}flutter run -d <device_id>${NC}"
echo ""
echo -e "${BLUE}📊 Surveillance:${NC}"
echo "- Backend logs: Terminal où 'npm start' tourne"
echo "- CallBox logs: Terminal où 'flutter run' tourne"
echo "- Statistiques: http://localhost:3000/api/call-box/stats"
echo ""
echo -e "${BLUE}🧪 Créer une transaction de test:${NC}"
echo "curl -X POST http://localhost:3000/api/call-box/transactions/submit \\"
echo "  -H \"Authorization: Bearer callbox-secure-token-2024\" \\"
echo "  -H \"Content-Type: application/json\" \\"
echo "  -d '{\"type\":\"recharge\",\"phoneNumber\":\"+237677123456\",\"amount\":1000,\"payItemId\":\"MTN_RECHARGE_1000\",\"customerInfo\":{\"name\":\"Test\",\"operator\":\"MTN\"},\"priority\":\"normal\"}'"
echo ""
echo -e "${YELLOW}💡 Astuce: Gardez 2 terminaux ouverts:${NC}"
echo "   Terminal 1: Backend (npm start)"
echo "   Terminal 2: CallBox (flutter run)"
echo ""
