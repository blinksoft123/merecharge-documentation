# Documentation d'Intégration CallBox - Backend MeRecharge

## Vue d'ensemble

Cette documentation décrit l'intégration complète entre les dispositifs CallBox et le backend MeRecharge. L'intégration permet une communication bidirectionnelle pour la gestion des transactions de recharge, dépôts, retraits et achats de forfaits.

## Architecture

```
┌─────────────────┐    HTTP/HTTPS     ┌─────────────────────┐
│                 │ ◄──────────────── │                     │
│    CallBox      │                   │   Backend           │
│   Dispositif    │ ──────────────────► │   MeRecharge        │
│                 │    API Calls      │                     │
└─────────────────┘                   └─────────────────────┘
        │                                       │
        │                                       │
        ▼                                       ▼
┌─────────────────┐                   ┌─────────────────────┐
│ Queue Locale    │                   │ Service de          │
│ Transactions    │                   │ Synchronisation     │
└─────────────────┘                   └─────────────────────┘
```

## Endpoints API CallBox

Tous les endpoints CallBox sont accessibles sous le préfixe `/api/call-box/` et nécessitent l'authentification par token Bearer.

### Authentification

**Header requis :**
```
Authorization: Bearer callbox-secure-token-2024
```

### 1. Enregistrement d'une instance CallBox

**POST** `/api/call-box/register`

Enregistre une nouvelle instance CallBox auprès du backend.

**Payload :**
```json
{
  "callboxId": "callbox_001",
  "capabilities": {
    "maxConcurrentTransactions": 5,
    "supportedTypes": ["recharge", "voucher", "deposit", "withdraw"]
  },
  "version": "1.0.0",
  "location": "Douala Centre"
}
```

**Réponse :**
```json
{
  "success": true,
  "message": "CallBox enregistré avec succès",
  "config": {
    "maxRetries": 3,
    "timeoutMs": 30000,
    "batchSize": 5,
    "pollIntervalMs": 5000
  },
  "instance": {
    "id": "callbox_001",
    "status": "active",
    "lastHeartbeat": "2024-10-07T15:30:00Z"
  }
}
```

### 2. Heartbeat

**POST** `/api/call-box/heartbeat`

Maintient la connexion active et synchronise le statut de l'instance.

**Payload :**
```json
{
  "callboxId": "callbox_001",
  "status": "active",
  "queueSize": 3,
  "metrics": {
    "uptime": 86400,
    "memoryUsage": 45.2,
    "processedTransactions": 152
  }
}
```

**Réponse :**
```json
{
  "success": true,
  "message": "Heartbeat reçu",
  "pendingTransactions": 5,
  "config": {
    "maxRetries": 3,
    "timeoutMs": 30000
  }
}
```

### 3. Récupération des transactions en attente

**GET** `/api/call-box/transactions/pending?callboxId=callbox_001&limit=5`

Récupère les transactions en attente pour traitement par le CallBox.

**Réponse :**
```json
{
  "success": true,
  "transactions": [
    {
      "id": "tx_1728307200_abc123",
      "type": "recharge",
      "phoneNumber": "+237677123456",
      "amount": 1000,
      "payItemId": "MTN_RECHARGE_1000",
      "customerInfo": {
        "name": "Jean Dupont",
        "operator": "MTN"
      },
      "priority": "normal",
      "status": "assigned",
      "createdAt": "2024-10-07T15:00:00Z",
      "assignedTo": "callbox_001",
      "retryCount": 0,
      "maxRetries": 3
    }
  ],
  "count": 1,
  "totalPending": 5
}
```

### 4. Soumission de nouvelle transaction

**POST** `/api/call-box/transactions/submit`

Ajoute une nouvelle transaction à la queue.

**Payload :**
```json
{
  "type": "recharge",
  "phoneNumber": "+237677123456",
  "amount": 1000,
  "payItemId": "MTN_RECHARGE_1000",
  "customerInfo": {
    "name": "Jean Dupont",
    "operator": "MTN"
  },
  "priority": "normal"
}
```

### 5. Mise à jour du statut de transaction

**PUT** `/api/call-box/transactions/{transactionId}/status`

Met à jour le statut d'une transaction en cours de traitement.

**Payload :**
```json
{
  "status": "completed",
  "callboxId": "callbox_001",
  "result": {
    "success": true,
    "transactionRef": "MTN123456789",
    "balance": 2500,
    "message": "Recharge effectuée avec succès"
  }
}
```

**Statuts possibles :**
- `pending` : En attente
- `assigned` : Assignée à un CallBox
- `processing` : En cours de traitement
- `completed` : Terminée avec succès
- `failed` : Échouée
- `retry` : En attente de nouvelle tentative

### 6. Configuration

**GET** `/api/call-box/config?callboxId=callbox_001`

Récupère la configuration actuelle pour un CallBox.

**PUT** `/api/call-box/config`

Met à jour la configuration globale.

### 7. Statistiques

**GET** `/api/call-box/stats`

Récupère les statistiques globales du système CallBox.

**Réponse :**
```json
{
  "success": true,
  "stats": {
    "connectedInstances": 3,
    "queueLength": 12,
    "pendingTransactions": 8,
    "assignedTransactions": 4,
    "processingTransactions": 2,
    "completedTransactions": 1543,
    "failedTransactions": 23,
    "instances": [
      {
        "id": "callbox_001",
        "status": "active",
        "lastHeartbeat": "2024-10-07T15:30:00Z",
        "queueSize": 3,
        "processedTransactions": 245
      }
    ]
  }
}
```

## Service de Synchronisation

Le service de synchronisation s'exécute automatiquement en arrière-plan et :

1. **Vérifie les CallBox connectées** toutes les 10 secondes
2. **Récupère les nouvelles transactions** depuis la base de données
3. **Distribue les transactions** aux CallBox disponibles selon un algorithme round-robin
4. **Surveille les heartbeats** pour détecter les CallBox déconnectées

### Endpoints de gestion de la synchronisation

**GET** `/api/sync/status` - Statut du service de synchronisation
**POST** `/api/sync/start` - Démarrer la synchronisation
**POST** `/api/sync/stop` - Arrêter la synchronisation
**POST** `/api/sync/force` - Forcer une synchronisation immédiate

## Intégration avec le Système Principal

**POST** `/api/transaction/to-callbox`

Permet au système principal d'envoyer directement une transaction vers les CallBox.

**Payload :**
```json
{
  "type": "deposit",
  "phoneNumber": "+237699876543",
  "amount": 5000,
  "payItemId": "ORANGE_DEPOSIT_5000",
  "customerInfo": {
    "name": "Marie Foukou",
    "operator": "Orange"
  }
}
```

## Types de Transactions Supportées

### 1. Recharge de Crédit (`recharge`)
```json
{
  "type": "recharge",
  "phoneNumber": "+237677123456",
  "amount": 1000,
  "payItemId": "MTN_RECHARGE_1000",
  "customerInfo": {
    "name": "Client",
    "operator": "MTN"
  }
}
```

### 2. Achat de Forfait (`voucher`)
```json
{
  "type": "voucher",
  "phoneNumber": "+237677123456",
  "payItemId": "ORANGE_DATA_1GB",
  "customerInfo": {
    "name": "Client",
    "operator": "Orange"
  }
}
```

### 3. Dépôt d'Argent (`deposit`)
```json
{
  "type": "deposit",
  "phoneNumber": "+237699123456",
  "amount": 5000,
  "payItemId": "MOOV_DEPOSIT",
  "customerInfo": {
    "name": "Client",
    "operator": "Moov"
  }
}
```

### 4. Retrait d'Argent (`withdraw`)
```json
{
  "type": "withdraw",
  "phoneNumber": "+237677123456",
  "amount": 2000,
  "payItemId": "MTN_WITHDRAW",
  "customerInfo": {
    "name": "Client",
    "operator": "MTN"
  }
}
```

## Gestion des Erreurs

### Codes de Réponse HTTP
- **200** : Succès
- **400** : Données de requête invalides
- **401** : Token d'authentification invalide
- **403** : Permission refusée
- **404** : Ressource non trouvée
- **500** : Erreur interne du serveur

### Format des Erreurs
```json
{
  "success": false,
  "error": "Description de l'erreur",
  "details": "Détails techniques de l'erreur"
}
```

## Système de Retry

- **maxRetries** : Nombre maximum de tentatives (défaut: 3)
- **Retry automatique** : Les transactions échouées sont automatiquement remises en queue
- **Backoff exponentiel** : Délai croissant entre les tentatives
- **Échec définitif** : Après épuisement des tentatives, la transaction est marquée comme échouée

## Sécurité

### Authentification
- Token Bearer obligatoire pour tous les endpoints CallBox
- Token différent pour l'API principale (`x-api-key`)

### Validation
- Validation des données d'entrée sur tous les endpoints
- Vérification de l'ownership des transactions
- Limitation de débit pour éviter les abus

## Monitoring et Logs

### Heartbeat
- Timeout de 30 secondes pour considérer une CallBox comme déconnectée
- Logs automatiques des connexions/déconnexions
- Surveillance de la charge de chaque CallBox

### Métriques
- Nombre de transactions par type
- Taux de succès/échec
- Temps de traitement moyen
- Charge par CallBox

## Tests

Exécuter les tests d'intégration :

```bash
cd /Users/serge/Desktop/merecharge_backend
node tests/callbox-integration.test.js
```

Les tests vérifient :
- ✅ Connexion au serveur
- ✅ Enregistrement CallBox  
- ✅ Système de heartbeat
- ✅ Soumission de transactions
- ✅ Récupération de transactions
- ✅ Mise à jour de statut
- ✅ Configuration dynamique
- ✅ Service de synchronisation
- ✅ Statistiques
- ✅ Intégration système principal

## Démarrage

1. **Démarrer le serveur backend :**
```bash
cd /Users/serge/Desktop/merecharge_backend
npm start
```

2. **Le service de synchronisation démarre automatiquement** après 2 secondes

3. **Vérifier le statut :**
```bash
curl -H "x-api-key: votre_cle_api_secrete" \
     http://localhost:3000/api/sync/status
```

## Configuration Avancée

### Variables d'Environnement
```bash
CALLBOX_TOKEN=your-secure-token-here
SYNC_INTERVAL_MS=10000
MAX_BATCH_SIZE=5
MAX_RETRIES=3
```

### Personnalisation
- Modifier `callboxConfig` dans `/routes/callbox.js`
- Ajuster les paramètres de synchronisation dans `/services/callbox-sync.js`
- Configurer les timeouts et limites selon vos besoins

## Support

Pour toute question ou problème concernant l'intégration CallBox :
1. Vérifiez les logs du serveur
2. Exécutez les tests d'intégration
3. Consultez les statistiques via `/api/call-box/stats`
4. Vérifiez le statut de synchronisation via `/api/sync/status`

---

*Documentation générée le 7 octobre 2024 - Version 1.0.0*