# 🚀 MeRecharge Admin Dashboard

Dashboard d'administration web moderne pour l'application mobile MeRecharge, développé avec HTML, CSS, JavaScript vanilla et Firebase.

## 🏗️ Architecture

```
merecharge-admin-web/
├── index.html                  # Page principale
├── assets/
│   ├── css/
│   │   └── admin.css          # Styles modernes avec variables CSS
│   ├── js/
│   │   ├── firebase-config.js # Configuration et services Firebase
│   │   └── admin.js           # Logique de l'interface admin
│   └── img/                   # Images et icônes
├── README.md                  # Documentation
└── .gitignore                 # Fichiers à ignorer
```

## 🔥 Configuration Firebase

### 1. Créer un projet Firebase

1. Aller sur [Firebase Console](https://console.firebase.google.com/)
2. Créer un nouveau projet ou utiliser un existant
3. Activer les services suivants :
   - **Authentication** (Email/Password)
   - **Cloud Firestore** (Base de données)
   - **Cloud Functions** (Notifications)
   - **Cloud Messaging** (Push notifications)
   - **Storage** (Fichiers)

### 2. Configurer Authentication

Dans Firebase Console > Authentication :
- Activer la méthode **Email/Password**
- Créer des comptes admin manuellement
- Ajouter les emails admin à la collection `admins` dans Firestore

### 3. Configurer Firestore

Structure des collections recommandée :

```javascript
// Collection: admins
{
  uid: "admin-uid",
  name: "Nom Admin",
  email: "admin@merecharge.com",
  role: "super_admin",
  permissions: ["users", "transactions", "reports"],
  createdAt: timestamp,
  lastLogin: timestamp
}

// Collection: users
{
  id: "user-id",
  name: "Nom Utilisateur",
  email: "user@example.com",
  phone: "+237698123456",
  status: "active", // active | inactive | blocked
  balance: 25000,
  photoURL: "url-vers-photo",
  createdAt: timestamp,
  lastActivity: timestamp
}

// Collection: transactions
{
  id: "transaction-id",
  userId: "user-id",
  userName: "Nom Utilisateur",
  userEmail: "user@example.com",
  type: "recharge", // recharge | bundle | deposit | withdraw
  amount: 5000,
  status: "completed", // pending | completed | failed | cancelled
  operator: "MTN", // Pour les recharges
  phoneNumber: "+237698123456",
  reference: "REF123456",
  createdAt: timestamp,
  updatedAt: timestamp
}

// Collection: recharges
{
  id: "recharge-id",
  userId: "user-id",
  operator: "MTN", // MTN | Orange | Camtel
  phoneNumber: "+237698123456",
  amount: 1000,
  status: "completed",
  reference: "MTN123456",
  createdAt: timestamp
}

// Collection: orders
{
  id: "order-id",
  userId: "user-id",
  items: [
    {
      productId: "product-id",
      name: "Nom produit",
      quantity: 1,
      price: 2500
    }
  ],
  total: 2500,
  status: "pending",
  createdAt: timestamp
}

// Collection: products
{
  id: "product-id",
  name: "Forfait MTN 1GB",
  description: "Forfait internet 1GB valable 30 jours",
  price: 2500,
  category: "forfaits",
  operator: "MTN",
  isActive: true,
  createdAt: timestamp
}

// Collection: activity_logs
{
  id: "activity-id",
  type: "user_registered", // user_registered | transaction_completed | etc.
  message: "Nouvel utilisateur inscrit",
  userId: "user-id",
  userName: "Nom Utilisateur",
  timestamp: timestamp,
  metadata: {}
}
```

### 4. Règles de sécurité Firestore

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Seuls les admins peuvent lire/écrire
    match /{document=**} {
      allow read, write: if request.auth != null && 
        exists(/databases/$(database)/documents/admins/$(request.auth.uid));
    }
    
    // Les utilisateurs peuvent seulement lire leurs propres données
    match /users/{userId} {
      allow read: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### 5. Configuration du projet

1. Copier les clés de configuration Firebase depuis Project Settings > General > Your apps
2. Remplacer la configuration dans `assets/js/firebase-config.js` :

```javascript
const firebaseConfig = {
    apiKey: "votre-api-key",
    authDomain: "votre-projet.firebaseapp.com",
    projectId: "votre-project-id",
    storageBucket: "votre-projet.appspot.com",
    messagingSenderId: "123456789012",
    appId: "1:123456789012:web:abcdefghijklmnop"
};
```

## 🎯 Fonctionnalités

### ✅ Implémentées
- **Dashboard** avec statistiques en temps réel
- **Gestion des utilisateurs** (CRUD, blocage, recherche)
- **Gestion des transactions** (visualisation, filtres, approbation)
- **Authentification admin** sécurisée
- **Interface responsive** mobile/desktop
- **Graphiques interactifs** (Chart.js)
- **Notifications toast** pour feedback utilisateur
- **Recherche et filtrage** des données

### 🚧 En développement
- **Gestion des recharges** CallBox
- **Gestion des commandes** et produits
- **Système de notifications push**
- **Rapports avancés** et analytics
- **Paramètres système** et configuration

### 📱 Intégrations
- **Firebase Auth** pour l'authentification
- **Cloud Firestore** pour la base de données
- **Cloud Functions** pour la logique métier
- **Firebase Storage** pour les fichiers
- **Cloud Messaging** pour les notifications push

## 🚀 Installation et utilisation

### 1. Cloner le projet
```bash
git clone <url-du-repo>
cd merecharge-admin-web
```

### 2. Configurer Firebase
- Suivre les étapes de configuration Firebase ci-dessus
- Mettre à jour `firebase-config.js` avec vos clés

### 3. Créer un admin
Dans Firebase Console > Firestore, créer un document dans la collection `admins` :
```javascript
{
  name: "Super Admin",
  email: "admin@merecharge.com",
  role: "super_admin",
  permissions: ["all"],
  createdAt: new Date()
}
```

### 4. Lancer l'application
```bash
# Servir les fichiers statiques (recommandé)
npx http-server
# ou
python -m http.server 8000
# ou
php -S localhost:8000

# Puis ouvrir http://localhost:8000
```

## 🔐 Sécurité

### Authentification
- Connexion obligatoire via Firebase Auth
- Vérification du rôle admin dans Firestore
- Session sécurisée avec tokens JWT

### Données
- Règles Firestore restrictives
- Validation côté client et serveur
- Logs d'activité pour audit

### Interface
- Protection contre les injections XSS
- Sanitisation des inputs utilisateur
- HTTPS obligatoire en production

## 🎨 Personnalisation

### Thème
Les couleurs et styles sont définis dans `assets/css/admin.css` via des variables CSS :
```css
:root {
    --primary-color: #4f46e5;
    --success-color: #10b981;
    --warning-color: #f59e0b;
    --danger-color: #ef4444;
}
```

### Fonctionnalités
Ajouter de nouvelles sections en :
1. Créant la section HTML dans `index.html`
2. Ajoutant la logique dans `admin.js`
3. Créant les services Firebase dans `firebase-config.js`

## 📊 Structure des données

Le dashboard utilise les collections Firestore suivantes :
- `users` : Utilisateurs de l'app mobile
- `transactions` : Toutes les transactions
- `recharges` : Recharges CallBox spécifiquement
- `orders` : Commandes de produits/services
- `products` : Catalogue de produits
- `admins` : Comptes administrateurs
- `activity_logs` : Logs d'activité système

## 🛠️ Technologies utilisées

- **Frontend** : HTML5, CSS3, JavaScript ES6+
- **Backend** : Firebase (Auth, Firestore, Functions, Storage)
- **Charts** : Chart.js pour les graphiques
- **Icons** : Font Awesome
- **Fonts** : Google Fonts (Inter)
- **Responsive** : CSS Grid & Flexbox

## 📱 Compatibilité

- ✅ Chrome 80+
- ✅ Firefox 75+
- ✅ Safari 13+
- ✅ Edge 80+
- ✅ Mobile (iOS Safari, Chrome Mobile)

## 📞 Support

Pour toute question ou problème :
- 📧 Email : support@merecharge.com
- 💬 Discord : MeRecharge Community
- 📱 WhatsApp : +237 6XX XXX XXX

---

**🔥 Développé avec Firebase & ❤️ pour MeRecharge**