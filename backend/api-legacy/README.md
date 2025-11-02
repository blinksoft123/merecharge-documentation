# MeRecharge Backend - Intégration API Maviance

Ce backend Node.js sert d'intermédiaire entre l'application Flutter MeRecharge et l'API Maviance (S3P) pour traiter les paiements mobiles au Cameroun.

## 🚀 Fonctionnalités

### Services Maviance Intégrés
- ✅ **Recharge de crédit** (TOPUP) - Orange, MTN, Camtel
- ✅ **Achat de forfaits** (VOUCHER) - Data et SMS
- ✅ **Dépôt d'argent** (CASHIN) - Vers wallet interne
- ✅ **Retrait d'argent** (CASHOUT) - Depuis wallet vers opérateurs
- ✅ **Vérification de transactions**
- ✅ **Récupération des services disponibles**

### Services Séparés
- 🚧 **Achat de Float Camtel** - Via passerelle USSD dédiée

## 📋 Prérequis

- Node.js >= 14.x
- npm >= 6.x
- Clés d'API Maviance valides

## 🛠️ Installation

1. **Cloner ou naviguer vers le dossier backend :**
```bash
cd merecharge_backend
```

2. **Installer les dépendances :**
```bash
npm install
```

3. **Configurer les variables d'environnement :**
Le fichier `.env` est déjà créé avec vos clés d'API :
```
S3P_URL=https://s3pv2cm.smobilpay.com/v2
S3P_KEY=ef63c4bf-3651-49da-870f-60332ac14796
S3P_SECRET=65c4ed25-07bc-4e49-beb3-34a1be8567be
```

## 🔧 Utilisation

### Démarrer le serveur
```bash
npm start
```
Le serveur sera accessible sur `http://localhost:3000`

### Tester l'intégration Maviance
```bash
npm test
```
Cette commande lance une série de tests pour vérifier la connexion avec l'API Maviance.

## 📚 Endpoints API

### Test et Configuration
- `GET /` - Statut du serveur
- `GET /api/ping` - Test de connexion avec Maviance
- `GET /api/services` - Liste des services Maviance disponibles

### Transactions
- `POST /api/recharge` - Recharge de crédit
- `POST /api/voucher` - Achat de forfait
- `POST /api/deposit` - Dépôt sur wallet
- `POST /api/withdraw` - Retrait du wallet
- `GET /api/verify/:transactionId` - Vérifier une transaction

### Produits
- `GET /api/topup/:serviceId` - Produits de recharge pour un service
- `GET /api/voucher/:serviceId` - Forfaits pour un service

### Services Spéciaux
- `POST /api/float/purchase` - Achat de float Camtel (passerelle USSD)

## 🔐 Authentification

Toutes les requêtes nécessitent un header d'authentification :
```
x-api-key: votre_cle_api_secrete
```

## 📖 Exemples d'utilisation

### Recharge de crédit Orange
```javascript
POST /api/recharge
Content-Type: application/json
x-api-key: votre_cle_api_secrete

{
  "phoneNumber": "699123456",
  "amount": 1000,
  "payItemId": "S-112-951-CMORANGE-20062-CM_ORANGE_VTU_CUSTOM-1",
  "customerInfo": {
    "phone": "699123456",
    "email": "client@example.com",
    "name": "John Doe",
    "address": "Yaoundé, Cameroun"
  }
}
```

### Achat de forfait
```javascript
POST /api/voucher
Content-Type: application/json
x-api-key: votre_cle_api_secrete

{
  "phoneNumber": "699123456",
  "payItemId": "S-112-974-CMENEOPREPAID-2000-10010-1",
  "customerInfo": {
    "phone": "699123456",
    "email": "client@example.com",
    "name": "John Doe",
    "address": "Yaoundé, Cameroun"
  }
}
```

## 🔍 PayItemIds Disponibles

### Recharge de Crédit (TOPUP)
- **Orange :** `S-112-951-CMORANGE-20062-CM_ORANGE_VTU_CUSTOM-1`

### Retraits (CASHOUT)
- **MTN :** `S-112-949-MTNMOMO-20053-200050001-1`

### Dépôts (CASHIN)
- **Orange :** `S-112-948-CMORANGEOM-30052-2006125104-1`

### Forfaits (VOUCHER)
- **Camtel :** `S-112-974-CMENEOPREPAID-2000-10010-1`

> **Note :** Cette liste est incomplète. Vous devez obtenir de Maviance la liste complète des payItemIds pour tous les opérateurs et services.

## 🏗️ Architecture

```
Application Flutter (Client)
    ↓ HTTP Requests
Backend Node.js (merecharge_backend)
    ↓ HTTPS + Auth HMAC-SHA1
API Maviance (S3P)
    ↓ Transactions
Opérateurs (Orange, MTN, Camtel)
```

## 🧪 Tests et Débogage

### Script de débogage de l'authentification
```bash
node debug_auth.js
```

### Logs
Le serveur affiche des logs détaillés pour chaque requête et réponse de l'API Maviance.

## 🚨 Problèmes Connus

1. **Erreur "Access token invalid" :** 
   - Vérifiez que vos clés S3P_KEY et S3P_SECRET sont correctes
   - Assurez-vous que votre compte Maviance est actif en production

2. **Timeout de connexion :**
   - L'API Maviance peut parfois être lente, augmentez le timeout si nécessaire

## 🔄 Intégration avec Flutter

Le service Flutter `MavianceService` est configuré pour communiquer avec ce backend :
- Localisation : `lib/services/maviance_service.dart`
- URL par défaut : `http://localhost:3000/api`

## 📞 Support

Pour les problèmes liés à l'API Maviance, consultez :
- Documentation : http://support.maviance.com/
- Code d'erreur 4009 : Problème d'authentification

## 📝 TODO

- [ ] Obtenir les payItemIds complets pour tous les opérateurs
- [ ] Implémenter la gestion des erreurs plus fine
- [ ] Ajouter la validation des numéros de téléphone
- [ ] Créer des tests unitaires complets
- [ ] Déployer le backend sur un serveur de production
- [ ] Finaliser l'intégration de la passerelle USSD pour le float Camtel