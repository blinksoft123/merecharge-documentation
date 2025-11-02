# 🚀 DÉMARRAGE RAPIDE - Intégration CallBox Backend

## ✅ Configuration Terminée !

L'intégration entre l'application CallBox Flutter et le Backend MeRecharge a été configurée.

---

## 📍 Informations de Configuration

### Backend MeRecharge
- **Emplacement :** `/Users/serge/Desktop/merecharge_backend`
- **Port :** `3000`
- **Token API :** `callbox-secure-token-2024`

### CallBox Flutter App
- **Emplacement :** `/Users/serge/Desktop/merecharge_ussd_gateway`
- **Port Serveur :** `8080`
- **IP Mac (réseau local) :** `192.168.1.26`
- **CallBox ID :** `CALLBOX_001`

---

## 🎯 DÉMARRAGE EN 3 ÉTAPES

### **ÉTAPE 1 : Démarrer le Backend** (Terminal 1)

```bash
cd /Users/serge/Desktop/merecharge_backend
npm start
```

**Vous devriez voir :**
```
Serveur MeRecharge démarré sur le port 3000
Service de synchronisation CallBox démarré
```

### **ÉTAPE 2 : Tester le Backend** (Terminal 2)

```bash
cd /Users/serge/Desktop/merecharge_ussd_gateway
./test_integration.sh
```

**Résultat attendu :**
```
🧪 TEST D'INTÉGRATION CALLBOX
======================================

📡 Test 1: Vérification du Backend
Testing: Backend Health... ✅ OK (HTTP 200)

📝 Test 2: Enregistrement CallBox
Testing: Register CallBox... ✅ OK (HTTP 200)

💓 Test 3: Heartbeat
Testing: Heartbeat... ✅ OK (HTTP 200)

... etc
```

### **ÉTAPE 3 : Démarrer l'App CallBox** (Terminal 3)

```bash
cd /Users/serge/Desktop/merecharge_ussd_gateway

# Installer les dépendances (première fois seulement)
flutter pub get

# Lancer l'application
flutter run
```

**Logs attendus dans l'app :**
```
🚀 Serveur CallBox démarré sur 0.0.0.0:8080
📊 Dashboard disponible dans l'application
✅ CallBox enregistré avec succès
📥 Récupération des transactions en attente...
💓 Heartbeat envoyé
```

---

## 🧪 TESTER L'INTÉGRATION COMPLÈTE

### Test 1 : Créer une Transaction de Test

```bash
curl -X POST http://localhost:3000/api/call-box/transactions/submit \
  -H "Authorization: Bearer callbox-secure-token-2024" \
  -H "Content-Type: application/json" \
  -d '{
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
```

### Test 2 : Vérifier que CallBox l'a récupérée

**Dans l'app Flutter, vous devriez voir :**
```
📥 Transaction reçue : tx_xxxxx
📱 Opérateur : MTN
💰 Montant : 1,000 FCFA
🔄 Traitement en cours...
```

### Test 3 : Vérifier dans le Backend

```bash
curl -H "Authorization: Bearer callbox-secure-token-2024" \
     "http://localhost:3000/api/call-box/transactions/pending?callboxId=CALLBOX_001&limit=5"
```

---

## 📊 MONITORING

### Vérifier le Statut du CallBox

```bash
# Statistiques générales
curl -H "Authorization: Bearer callbox-secure-token-2024" \
     http://localhost:3000/api/call-box/stats

# Statut de synchronisation
curl -H "x-api-key: votre_cle_api_secrete" \
     http://localhost:3000/api/sync/status
```

### Logs de l'App Flutter

Dans le terminal où `flutter run` est actif :
- Les logs s'affichent en temps réel
- Recherchez `[API]` pour voir les appels API
- Recherchez `CallBox` pour voir les événements d'intégration

---

## 🔄 FLUX DE TRANSACTION COMPLET

```
1. Backend crée une transaction
       ↓
2. CallBox la récupère (polling 2s)
       ↓
3. CallBox génère le code USSD
       ↓
4. CallBox exécute sur Android
       ↓
5. CallBox capture la réponse
       ↓
6. CallBox met à jour le backend
       ↓
7. Transaction marquée "completed"
```

**Temps total : 5-15 secondes** ⚡

---

## ⚠️ TROUBLESHOOTING RAPIDE

### Problème : CallBox ne se connecte pas

**Solution :**
```bash
# 1. Vérifier que le backend tourne
curl http://localhost:3000/

# 2. Vérifier l'IP dans app_config.dart
# Elle doit être: 192.168.1.26

# 3. Téléphone sur le même WiFi que le Mac?
```

### Problème : Erreur 401 Unauthorized

**Solution :**
```dart
// Dans lib/config/app_config.dart, vérifier :
static const String callboxToken = 'callbox-secure-token-2024';

// Doit correspondre exactement au token du backend
```

### Problème : Pas de transactions récupérées

**Solution :**
```bash
# Créer une transaction de test
./test_integration.sh

# Ou manuellement
curl -X POST http://localhost:3000/api/call-box/transactions/submit \
  -H "Authorization: Bearer callbox-secure-token-2024" \
  -H "Content-Type: application/json" \
  -d '{"type":"recharge","phoneNumber":"+237677123456","amount":1000,"payItemId":"MTN_RECHARGE_1000","customerInfo":{"name":"Test","operator":"MTN"},"priority":"normal"}'
```

---

## 📁 FICHIERS MODIFIÉS

Les fichiers suivants ont été mis à jour pour l'intégration :

1. ✅ `lib/config/app_config.dart` 
   - Ajout de l'IP backend (192.168.1.26)
   - Ajout du token CallBox
   - Ajout du callboxId

2. ✅ `lib/services/merecharge_api_service.dart`
   - Ajout du header `Authorization: Bearer`
   - Mise à jour des endpoints (`/transactions/pending`, etc.)
   - Adaptation du format des payloads

3. ✅ `INTEGRATION_BACKEND.md`
   - Guide complet d'intégration

4. ✅ `test_integration.sh`
   - Script de test automatisé

---

## 🎯 PROCHAINES ÉTAPES

Une fois que tout fonctionne en local :

### 1. Tester sur un Téléphone Android Réel

```bash
# Connecter le téléphone via USB
# Activer le mode développeur
# Autoriser le débogage USB

flutter devices  # Vérifier que le téléphone est détecté
flutter run      # Installer sur le téléphone
```

### 2. Implémenter le Vrai USSD

Actuellement, le système simule les codes USSD. Pour une utilisation réelle :
- Ajouter un plugin USSD natif Android
- Implémenter l'interface Kotlin/Java
- Gérer les permissions Android nécessaires

### 3. Déploiement Production

- Utiliser HTTPS pour le backend
- Configurer un nom de domaine
- Changer les tokens pour des valeurs sécurisées
- Mettre en place un monitoring avancé

---

## 📚 DOCUMENTATION COMPLÈTE

- **Guide Utilisation :** `GUIDE_UTILISATION.md`
- **Intégration Backend :** `INTEGRATION_BACKEND.md`
- **Backend API :** `/Users/serge/Desktop/merecharge_backend/CALLBOX_INTEGRATION.md`

---

## 🆘 SUPPORT

En cas de problème :

1. **Vérifier les logs Flutter** : `flutter logs`
2. **Vérifier les logs Backend** : Dans le terminal où `npm start` tourne
3. **Tester avec curl** : Utiliser `test_integration.sh`
4. **Consulter les docs** : `INTEGRATION_BACKEND.md`

---

## ✅ CHECKLIST DE VÉRIFICATION

Avant de commencer le développement :

- [ ] Backend MeRecharge démarre sans erreur
- [ ] Script `test_integration.sh` passe tous les tests
- [ ] App Flutter compile et se lance
- [ ] CallBox s'enregistre auprès du backend
- [ ] Heartbeat fonctionne (visible dans les logs)
- [ ] Transaction de test créée et récupérée
- [ ] Dashboard affiche les bonnes informations
- [ ] Téléphone sur le même réseau WiFi que le Mac

---

**🎉 Vous êtes prêt à commencer !**

**Version :** 1.0  
**Date :** 12 octobre 2025  
**Configuration :** Development (Local Network)
