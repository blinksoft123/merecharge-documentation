#!/bin/bash

# 🧪 Script de Test d'Intégration CallBox <-> Backend MeRecharge
# Ce script teste tous les endpoints de l'intégration

echo "======================================"
echo "🧪 TEST D'INTÉGRATION CALLBOX"
echo "======================================"
echo ""

# Configuration
BACKEND_URL="http://localhost:3000"
CALLBOX_TOKEN="callbox-secure-token-2024"
API_KEY="votre_cle_api_secrete"

# Couleurs
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Fonction de test
test_endpoint() {
    local name="$1"
    local method="$2"
    local url="$3"
    local data="$4"
    local headers="$5"
    
    echo -n "Testing: $name... "
    
    if [ "$method" = "GET" ]; then
        response=$(curl -s -w "\n%{http_code}" -H "$headers" "$url")
    elif [ "$method" = "POST" ]; then
        response=$(curl -s -w "\n%{http_code}" -X POST -H "$headers" -H "Content-Type: application/json" -d "$data" "$url")
    elif [ "$method" = "PUT" ]; then
        response=$(curl -s -w "\n%{http_code}" -X PUT -H "$headers" -H "Content-Type: application/json" -d "$data" "$url")
    fi
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "200" ] || [ "$http_code" = "201" ]; then
        echo -e "${GREEN}✅ OK${NC} (HTTP $http_code)"
        # echo "Response: $body" | jq '.' 2>/dev/null || echo "$body"
    else
        echo -e "${RED}❌ FAILED${NC} (HTTP $http_code)"
        echo "Response: $body"
    fi
    echo ""
}

# Test 1: Backend est en ligne
echo -e "${YELLOW}📡 Test 1: Vérification du Backend${NC}"
test_endpoint "Backend Health" "GET" "$BACKEND_URL/" "" ""

# Test 2: Enregistrement CallBox
echo -e "${YELLOW}📝 Test 2: Enregistrement CallBox${NC}"
register_data='{
  "callboxId": "CALLBOX_001",
  "capabilities": {
    "maxConcurrentTransactions": 5,
    "supportedTypes": ["recharge", "voucher", "deposit", "withdraw"]
  },
  "version": "1.0.0",
  "location": "Test Local"
}'
test_endpoint "Register CallBox" "POST" "$BACKEND_URL/api/call-box/register" "$register_data" "Authorization: Bearer $CALLBOX_TOKEN"

# Test 3: Heartbeat
echo -e "${YELLOW}💓 Test 3: Heartbeat${NC}"
heartbeat_data='{
  "callboxId": "CALLBOX_001",
  "status": "active",
  "queueSize": 0,
  "metrics": {
    "uptime": 3600,
    "memoryUsage": 45.2,
    "processedTransactions": 0
  }
}'
test_endpoint "Heartbeat" "POST" "$BACKEND_URL/api/call-box/heartbeat" "$heartbeat_data" "Authorization: Bearer $CALLBOX_TOKEN"

# Test 4: Statistiques CallBox
echo -e "${YELLOW}📊 Test 4: Statistiques${NC}"
test_endpoint "Stats" "GET" "$BACKEND_URL/api/call-box/stats" "" "Authorization: Bearer $CALLBOX_TOKEN"

# Test 5: Soumettre une transaction
echo -e "${YELLOW}📤 Test 5: Soumission de Transaction${NC}"
transaction_data='{
  "type": "recharge",
  "phoneNumber": "+237677123456",
  "amount": 1000,
  "payItemId": "MTN_RECHARGE_1000",
  "customerInfo": {
    "name": "Test Client",
    "operator": "MTN"
  },
  "priority": "normal"
}'
test_endpoint "Submit Transaction" "POST" "$BACKEND_URL/api/call-box/transactions/submit" "$transaction_data" "Authorization: Bearer $CALLBOX_TOKEN"

# Test 6: Récupérer les transactions en attente
echo -e "${YELLOW}📥 Test 6: Récupération Transactions Pending${NC}"
test_endpoint "Fetch Pending" "GET" "$BACKEND_URL/api/call-box/transactions/pending?callboxId=CALLBOX_001&limit=5" "" "Authorization: Bearer $CALLBOX_TOKEN"

# Test 7: Statut de synchronisation
echo -e "${YELLOW}🔄 Test 7: Statut de Synchronisation${NC}"
test_endpoint "Sync Status" "GET" "$BACKEND_URL/api/sync/status" "" "x-api-key: $API_KEY"

echo ""
echo "======================================"
echo -e "${GREEN}✅ Tests terminés !${NC}"
echo "======================================"
echo ""
echo "Pour tester la mise à jour de statut:"
echo "  curl -X PUT http://localhost:3000/api/call-box/transactions/TX_ID/status \\"
echo "    -H 'Authorization: Bearer $CALLBOX_TOKEN' \\"
echo "    -H 'Content-Type: application/json' \\"
echo "    -d '{\"status\": \"completed\", \"callboxId\": \"CALLBOX_001\", \"result\": {\"success\": true, \"message\": \"Test\"}}'"
echo ""
