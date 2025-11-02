# 🔗 Guide d'Intégration Backend MeRecharge

## 📋 Vue d'ensemble

Ce guide explique comment connecter l'application **CallBox Flutter** avec votre **Backend MeRecharge** existant.

---

## 🏗️ Architecture de l'Intégration

```
┌────────────────────────────────────────────────────────────────┐
│                     FLUX COMPLET D'INTÉGRATION                 │
└────────────────────────────────────────────────────────────────┘

1. CLIENT fait une demande de recharge
         ↓
2. BACKEND MeRecharge crée la transaction
         ↓
3. BACKEND ajoute à la queue CallBox
         ↓
4. CALLBOX FLUTTER récupère via GET /api/call-box/transactions/pending
         ↓
5. CALLBOX exécute le code USSD sur Android
         ↓
6. CALLBOX envoie résultat via PUT /api/call-box/transactions/{id}/status
         ↓
7. BACKEND met à jour la transaction
         ↓
8. BACKEND notifie le CLIENT
```

---

## ✅ PRÉREQUIS

### Backend MeRecharge (Déjà configuré ✓)

- ✅ Node.js backend sur port 3000
- ✅ Routes CallBox dans `/routes/callbox.js`
- ✅ Service de synchronisation CallBox
- ✅ Authentification par token Bearer
- ✅ Documentation API dans `CALLBOX_INTEGRATION.md`

**Localisation :** `/Users/serge/Desktop/merecharge_backend`

### CallBox Flutter App

**Localisation :** `/Users/serge/Desktop/merecharge_ussd_gateway`

---

## 🔧 ÉTAPE 1 : Configuration du Backend

### 1.1 Démarrer le Backend

```bash
cd /Users/serge/Desktop/merecharge_backend
npm start
```

**Vérification :**
```bash
curl http://localhost:3000/
# Réponse attendue : "Serveur MeRecharge est en ligne !"
```

### 1.2 Vérifier les Routes CallBox

```bash
# Test avec le token d'authentification
curl -H "Authorization: Bearer callbox-secure-token-2024" \
     http://localhost:3000/api/call-box/stats

# Réponse attendue : Statistiques du système CallBox
```

### 1.3 Configuration du Token

**Dans le Backend** (`/Users/serge/Desktop/merecharge_backend/routes/callbox.js`) :

Le token est configuré comme suit :
```javascript
const CALLBOX_TOKEN = 'callbox-secure-token-2024';
```

---

## 🔧 ÉTAPE 2 : Configuration de l'App CallBox Flutter

### 2.1 Mettre à jour la Configuration API

Modifiez le fichier de configuration :

**Fichier :** `lib/config/app_config.dart`

```dart
class AppConfig {
  // ⚠️ IMPORTANT : Mettre à jour ces URLs
  
  // Pour développement local (même réseau WiFi)
  static const String meRechargeApiUrl = 'http://192.168.1.X:3000/api/call-box';
  // Remplacez 192.168.1.X par l'IP de votre Mac
  
  // Pour production
  // static const String meRechargeApiUrl = 'https://api.merecharge.com/api/call-box';
  
  static const String meRechargeAdminUrl = 'http://192.168.1.X:3000';
  
  // Token d'authentification CallBox
  static const String callboxToken = 'callbox-secure-token-2024';
  
  // ID unique de ce CallBox
  static const String callboxId = 'CALLBOX_001';
}
```

### 2.2 Trouver l'IP de votre Mac

```bash
# Exécuter sur votre Mac
ifconfig | grep "inet " | grep -v 127.0.0.1
```

**Exemple de sortie :**
```
inet 192.168.1.105 netmask 0xffffff00 broadcast 192.168.1.255
```

Utilisez cette IP (ex: `192.168.1.105`) dans la configuration.

---

## 🔧 ÉTAPE 3 : Modifier les Services Flutter

### 3.1 Ajouter le Token d'Authentification

**Fichier :** `lib/services/merecharge_api_service.dart`

Cherchez la méthode `_configureDio()` et modifiez :

```dart
void _configureDio() {
  _dio.options.baseUrl = AppConfig.meRechargeApiUrl;
  _dio.options.connectTimeout = AppConfig.apiTimeout;
  _dio.options.receiveTimeout = AppConfig.apiTimeout;

  // Intercepteur pour l'authentification
  _dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        // ✅ AJOUTER LE TOKEN BEARER
        options.headers['Authorization'] = 'Bearer ${AppConfig.callboxToken}';
        options.headers['Content-Type'] = 'application/json';
        options.headers['User-Agent'] = 'MeRecharge-CallBox/1.0.0';
        handler.next(options);
      },
      onError: (error, handler) {
        _logger.e('Erreur API: ${error.response?.statusCode} - ${error.message}');
        handler.next(error);
      },
    ),
  );
}
```

### 3.2 Mettre à jour les Endpoints

**Fichier :** `lib/services/merecharge_api_service.dart`

Modifier les endpoints pour correspondre à votre backend :

```dart
// Récupérer les transactions en attente depuis MeRecharge
Future<List<TransactionModel>> fetchPendingTransactions() async {
  try {
    _logger.i('Récupération des transactions en attente...');
    
    // ✅ Endpoint correct avec callboxId
    final response = await _dio.get(
      '/transactions/pending',
      queryParameters: {
        'callboxId': AppConfig.callboxId,
        'limit': AppConfig.batchSize,
      },
    );
    
    if (response.statusCode == 200) {
      final data = response.data as Map<String, dynamic>;
      final transactionsJson = data['transactions'] as List;
      
      final transactions = transactionsJson
          .map((json) => _mapMeRechargeToTransaction(json))
          .toList();
          
      _logger.i('${transactions.length} transactions récupérées');
      return transactions;
      
    } else {
      throw Exception('Erreur HTTP: ${response.statusCode}');
    }
    
  } catch (e) {
    _logger.e('Erreur lors de la récupération des transactions: $e');
    
    if (e is DioException && e.type == DioExceptionType.connectionTimeout) {
      _logger.w('Timeout de connexion - Mode hors ligne');
      return [];
    }
    
    throw Exception('Impossible de récupérer les transactions: $e');
  }
}

// Mettre à jour le statut d'une transaction
Future<void> updateTransactionStatus(
  String meRechargeId,
  String status, {
  String? response,
  String? errorMessage,
}) async {
  try {
    _logger.i('Mise à jour du statut de la transaction $meRechargeId: $status');
    
    final payload = {
      'status': status,
      'callboxId': AppConfig.callboxId,
      'result': {
        'success': status == 'completed',
        'transactionRef': response,
        'message': response ?? errorMessage,
      },
    };

    // ✅ Endpoint correct
    final apiResponse = await _dio.put(
      '/transactions/$meRechargeId/status',
      data: payload,
    );

    if (apiResponse.statusCode == 200) {
      _logger.i('Statut mis à jour avec succès pour: $meRechargeId');
    } else {
      throw Exception('Erreur HTTP: ${apiResponse.statusCode}');
    }
    
  } catch (e) {
    _logger.e('Erreur lors de la mise à jour du statut: $e');
    _logger.w('Mise à jour différée pour: $meRechargeId');
  }
}

// Enregistrer ce CallBox auprès du backend
Future<void> registerCallBox() async {
  try {
    _logger.i('Enregistrement du CallBox...');
    
    final payload = {
      'callboxId': AppConfig.callboxId,
      'version': AppConfig.appVersion,
      'capabilities': {
        'maxConcurrentTransactions': AppConfig.maxConcurrentTransactions,
        'supportedTypes': ['recharge', 'voucher', 'deposit', 'withdraw'],
      },
      'location': 'Local Test', // ✅ À personnaliser
    };

    // ✅ Endpoint correct
    final response = await _dio.post('/register', data: payload);
    
    if (response.statusCode == 200) {
      _logger.i('CallBox enregistré avec succès');
      final config = response.data['config'];
      _logger.d('Configuration reçue: $config');
    }
    
  } catch (e) {
    _logger.w('Impossible d\'enregistrer le CallBox: $e');
  }
}

// Signaler que ce CallBox est en vie (Heartbeat)
Future<void> sendHeartbeat() async {
  try {
    final payload = {
      'callboxId': AppConfig.callboxId,
      'status': 'active',
      'queueSize': 0, // ✅ À mettre à jour dynamiquement
      'metrics': {
        'uptime': DateTime.now().millisecondsSinceEpoch,
        'memoryUsage': 0.0,
        'processedTransactions': 0,
      },
    };

    // ✅ Endpoint correct
    await _dio.post('/heartbeat', data: payload);
    
  } catch (e) {
    _logger.w('Heartbeat échoué: $e');
  }
}
```

---

## 🔧 ÉTAPE 4 : Ajouter le Token dans AppConfig

**Fichier :** `lib/config/app_config.dart`

Ajoutez ces nouvelles constantes :

```dart
class AppConfig {
  // Configuration du serveur
  static const String serverHost = '0.0.0.0';
  static const int serverPort = 8080;
  
  // ✅ NOUVELLES CONFIGURATIONS
  // Configuration MeRecharge Backend
  static const String meRechargeApiUrl = 'http://192.168.1.105:3000/api/call-box';
  static const String meRechargeAdminUrl = 'http://192.168.1.105:3000';
  
  // Authentification
  static const String callboxToken = 'callbox-secure-token-2024';
  static const String callboxId = 'CALLBOX_001';
  
  // Configuration des opérateurs (déjà existant)
  // ... reste du code
}
```

---

## 🔧 ÉTAPE 5 : Mapper les Transactions

### 5.1 Adapter le Modèle de Transaction

**Fichier :** `lib/services/merecharge_api_service.dart`

Modifiez la méthode de mapping :

```dart
// Mapper une transaction MeRecharge vers notre modèle
TransactionModel _mapMeRechargeToTransaction(Map<String, dynamic> json) {
  // Format du backend MeRecharge
  return TransactionModel(
    meRechargeId: json['id'].toString(),
    type: json['type'] ?? 'unknown', // recharge, voucher, deposit, withdraw
    operator: _extractOperator(json), // Extraire de customerInfo
    fromPhone: json['phoneNumber'] ?? '',
    toPhone: json['phoneNumber'] ?? '',
    amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
    fees: 0.0, // Calculer si nécessaire
    ussdCode: _generateUssdCode(json), // Générer le code USSD
    status: 'pending',
    createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    metadata: json,
  );
}

String _extractOperator(Map<String, dynamic> json) {
  final customerInfo = json['customerInfo'] as Map<String, dynamic>?;
  final operator = customerInfo?['operator']?.toString().toLowerCase() ?? 'unknown';
  return operator;
}

String _generateUssdCode(Map<String, dynamic> json) {
  // ⚠️ IMPORTANT : Générer le code USSD basé sur le type et l'opérateur
  final type = json['type'];
  final operator = _extractOperator(json);
  final phoneNumber = json['phoneNumber'];
  final amount = json['amount'];
  
  // Exemple pour MTN
  if (operator == 'mtn') {
    if (type == 'recharge') {
      return '*126*1*$phoneNumber*$amount#';
    } else if (type == 'deposit') {
      return '*126*2*$phoneNumber*$amount#';
    }
  }
  
  // Exemple pour Orange
  if (operator == 'orange') {
    if (type == 'recharge') {
      return '#130*1*$phoneNumber*$amount#';
    }
  }
  
  // Default fallback
  return '#USSD#';
}
```

---

## 🧪 ÉTAPE 6 : Test de l'Intégration

### 6.1 Test Backend

```bash
cd /Users/serge/Desktop/merecharge_backend

# Démarrer le backend
npm start

# Dans un autre terminal, tester les endpoints
curl -H "Authorization: Bearer callbox-secure-token-2024" \
     http://localhost:3000/api/call-box/stats
```

### 6.2 Test CallBox Registration

```bash
# Enregistrer un CallBox
curl -X POST http://localhost:3000/api/call-box/register \
  -H "Authorization: Bearer callbox-secure-token-2024" \
  -H "Content-Type: application/json" \
  -d '{
    "callboxId": "CALLBOX_001",
    "capabilities": {
      "maxConcurrentTransactions": 5,
      "supportedTypes": ["recharge", "voucher", "deposit", "withdraw"]
    },
    "version": "1.0.0",
    "location": "Test Local"
  }'
```

### 6.3 Créer une Transaction de Test

```bash
# Soumettre une transaction via l'API principale
curl -X POST http://localhost:3000/api/transaction/to-callbox \
  -H "x-api-key: votre_cle_api_secrete" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "recharge",
    "phoneNumber": "+237677123456",
    "amount": 1000,
    "payItemId": "MTN_RECHARGE_1000",
    "customerInfo": {
      "name": "Test Client",
      "operator": "MTN"
    }
  }'
```

### 6.4 Vérifier la Transaction en Attente

```bash
curl -H "Authorization: Bearer callbox-secure-token-2024" \
     "http://localhost:3000/api/call-box/transactions/pending?callboxId=CALLBOX_001&limit=5"
```

---

## 🚀 ÉTAPE 7 : Démarrage Complet

### 7.1 Démarrer le Backend

```bash
cd /Users/serge/Desktop/merecharge_backend
npm start
```

**Console devrait afficher :**
```
Serveur MeRecharge démarré sur le port 3000
Service de synchronisation CallBox démarré
```

### 7.2 Démarrer l'App CallBox

```bash
cd /Users/serge/Desktop/merecharge_ussd_gateway

# Installer les dépendances
flutter pub get

# Lancer l'app
flutter run
```

**L'app devrait :**
1. ✅ Démarrer le serveur HTTP sur port 8080
2. ✅ S'enregistrer auprès du backend (POST /register)
3. ✅ Commencer à poll les transactions (GET /transactions/pending)
4. ✅ Envoyer des heartbeats toutes les 30s

---

## 📊 ÉTAPE 8 : Monitoring

### 8.1 Vérifier le Statut du CallBox

```bash
# Statut de synchronisation
curl -H "x-api-key: votre_cle_api_secrete" \
     http://localhost:3000/api/sync/status

# Statistiques CallBox
curl -H "Authorization: Bearer callbox-secure-token-2024" \
     http://localhost:3000/api/call-box/stats
```

### 8.2 Logs Flutter

```bash
# Dans le terminal où flutter run est actif
# Vous devriez voir :
🚀 Serveur CallBox démarré sur 0.0.0.0:8080
📊 Dashboard disponible dans l'application
✅ CallBox enregistré avec succès
📥 Récupération des transactions en attente...
```

---

## 🔄 FLUX DE TRANSACTION COMPLET

### Scénario : Client demande une recharge MTN de 1000 FCFA

**1. Backend reçoit la demande**
```bash
POST /api/recharge
{
  "phoneNumber": "+237677123456",
  "amount": 1000,
  "payItemId": "MTN_RECHARGE_1000",
  "customerInfo": {
    "name": "Jean",
    "operator": "MTN"
  }
}
```

**2. Backend crée la transaction et l'ajoute à la queue CallBox**

**3. CallBox Flutter récupère la transaction (polling toutes les 2s)**
```
GET /api/call-box/transactions/pending?callboxId=CALLBOX_001
→ Reçoit la transaction
```

**4. CallBox génère et exécute le code USSD**
```
Code USSD: *126*1*677123456*1000#
```

**5. CallBox capture la réponse et met à jour le backend**
```
PUT /api/call-box/transactions/{id}/status
{
  "status": "completed",
  "callboxId": "CALLBOX_001",
  "result": {
    "success": true,
    "transactionRef": "MTN123456789",
    "message": "Recharge effectuée avec succès"
  }
}
```

**6. Backend notifie le client**

---

## ⚠️ TROUBLESHOOTING

### Problème : CallBox ne peut pas se connecter au backend

**Vérifications :**
```bash
# 1. Backend est-il démarré?
curl http://localhost:3000/

# 2. IP correcte dans app_config.dart?
ifconfig | grep "inet "

# 3. Firewall bloque-t-il le port 3000?
# Sur Mac: Système → Sécurité → Pare-feu

# 4. Téléphone sur le même réseau WiFi que le Mac?
```

### Problème : Erreur 401 Unauthorized

**Solution :**
Vérifier que le token dans `app_config.dart` correspond exactement au token du backend :
- Backend: `callbox-secure-token-2024`
- Flutter: `callbox-secure-token-2024`

### Problème : Pas de transactions récupérées

**Vérifications :**
```bash
# 1. Y a-t-il des transactions en attente?
curl -H "Authorization: Bearer callbox-secure-token-2024" \
     "http://localhost:3000/api/call-box/transactions/pending?callboxId=CALLBOX_001"

# 2. Créer une transaction de test
curl -X POST http://localhost:3000/api/call-box/transactions/submit \
  -H "Authorization: Bearer callbox-secure-token-2024" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "recharge",
    "phoneNumber": "+237677123456",
    "amount": 1000,
    "payItemId": "MTN_RECHARGE_1000",
    "customerInfo": {
      "name": "Test",
      "operator": "MTN"
    },
    "priority": "normal"
  }'
```

---

## 📝 CHECKLIST D'INTÉGRATION

- [ ] Backend MeRecharge démarré sur port 3000
- [ ] IP du Mac trouvée et notée
- [ ] `app_config.dart` mis à jour avec l'IP correcte
- [ ] Token d'authentification ajouté dans les headers Dio
- [ ] Endpoints mis à jour dans `merecharge_api_service.dart`
- [ ] Méthode de mapping des transactions adaptée
- [ ] Génération des codes USSD implémentée
- [ ] Tests backend réussis (curl)
- [ ] App Flutter lancée avec succès
- [ ] CallBox enregistré dans le backend
- [ ] Heartbeat fonctionnel
- [ ] Transaction de test créée et récupérée
- [ ] Mise à jour du statut fonctionnelle

---

## 🎯 PROCHAINES ÉTAPES

Une fois l'intégration testée :

1. **Déploiement Production**
   - Utiliser HTTPS pour l'API backend
   - Changer les tokens par des valeurs sécurisées
   - Configurer un nom de domaine

2. **Optimisations**
   - Implémenter le vrai code USSD (pas de simulation)
   - Ajouter la gestion des SIM multiples
   - Améliorer la génération automatique des codes USSD

3. **Monitoring**
   - Mettre en place des alertes
   - Dashboard admin web
   - Logs centralisés

---

**Version : 1.0**  
**Date : 12 octobre 2025**  
**Auteur : Guide d'intégration MeRecharge CallBox**
