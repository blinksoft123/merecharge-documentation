# 📂 INDEX DU PROJET MERECHARGE

## 📁 Structure Complète du Dossier

```
merecharge-documentation/
│
├── README.md                           # Documentation principale
│
├── frontend/                           # Tous les codes frontend
│   ├── web-react/                      # Application web React + TypeScript
│   │   ├── src/                        # Code source React
│   │   ├── public/                     # Assets publics
│   │   ├── package.json                # Dépendances npm
│   │   ├── vite.config.ts              # Config Vite
│   │   └── README.md                   # Doc spécifique
│   │
│   └── site-vitrine/                   # Site vitrine statique
│       ├── index.html                  # Page principale
│       ├── assets/                     # Images et styles
│       └── merecharge.apk              # APK mobile (21 MB)
│
├── mobile/                             # Applications mobiles
│   ├── app-flutter/                    # App mobile principale
│   │   ├── lib/                        # Code source Dart
│   │   │   ├── screens/                # 35+ écrans UI
│   │   │   ├── services/               # 3 services principaux
│   │   │   ├── models/                 # Modèles de données
│   │   │   └── widgets/                # Widgets réutilisables
│   │   ├── android/                    # Config Android
│   │   ├── ios/                        # Config iOS
│   │   ├── pubspec.yaml                # Dépendances Flutter
│   │   ├── RAPPORT_AVANCEMENT.md       # Rapport détaillé 75%
│   │   └── README.md                   # Doc spécifique
│   │
│   └── ussd-gateway/                   # Gateway USSD automatisation
│       ├── lib/                        # Code source Dart
│       ├── android/                    # Config Android
│       ├── INTEGRATION_BACKEND.md      # Guide intégration
│       ├── QUICK_START.md              # Démarrage rapide
│       └── pubspec.yaml                # Dépendances
│
├── backend/                            # Services backend
│   ├── api-moderne/                    # Backend production-ready
│   │   ├── server.js                   # Serveur Express principal
│   │   ├── middleware/                 # Auth, errors, logging
│   │   ├── routes/                     # Endpoints API
│   │   ├── services/                   # Logique métier
│   │   ├── utils/                      # Utilitaires
│   │   ├── logs/                       # Fichiers de logs
│   │   ├── package.json                # Dépendances
│   │   ├── .env.example                # Variables d'environnement
│   │   └── README.md                   # Doc complète backend
│   │
│   └── api-legacy/                     # Backend original Maviance
│       ├── server.js                   # Serveur Express
│       ├── maviance_service.js         # Service Maviance
│       ├── routes/                     # Routes API
│       │   └── callbox.js              # Routes CallBox
│       └── services/                   # Services métier
│           └── callbox-sync.js         # Sync CallBox
│
└── admin/                              # Interfaces administrateur
    ├── dashboard-web/                  # Dashboard web HTML/JS
    │   ├── index.html                  # Interface principale
    │   ├── assets/                     # CSS, JS, images
    │   │   ├── css/
    │   │   │   └── admin.css           # Styles modernes
    │   │   └── js/
    │   │       ├── firebase-config.js  # Config Firebase
    │   │       └── admin.js            # Logique admin
    │   ├── README.md                   # Doc dashboard
    │   └── GUIDE_UTILISATEURS.md       # Guide utilisateurs
    │
    └── dashboard-flutter/              # Dashboard Flutter (alternatif)
        ├── lib/                        # Code source Dart
        └── pubspec.yaml                # Dépendances
```

---

## 📊 Résumé des Composants

| Dossier | Technologie | Lignes de Code | État |
|---------|-------------|----------------|------|
| `frontend/web-react/` | React + TS | ~2,000 | ✅ 100% |
| `frontend/site-vitrine/` | HTML/CSS | ~500 | ✅ 100% |
| `mobile/app-flutter/` | Flutter | 8,679+ | 🟡 75% |
| `mobile/ussd-gateway/` | Flutter | ~3,000 | 🟡 90% |
| `backend/api-moderne/` | Node.js | ~1,500 | 🟡 85% |
| `backend/api-legacy/` | Node.js | ~800 | ✅ 100% |
| `admin/dashboard-web/` | HTML/JS | ~1,200 | 🟡 80% |
| `admin/dashboard-flutter/` | Flutter | ~2,000 | 🟡 70% |

**Total estimé : ~20,000 lignes de code**

---

## 🔑 Fichiers Clés à Lire en Premier

### Pour comprendre le projet global :
1. **`README.md`** (racine) - Vue d'ensemble complète
2. **`mobile/app-flutter/RAPPORT_AVANCEMENT.md`** - État détaillé à 75%

### Pour démarrer le développement :

**Frontend Web :**
- `frontend/web-react/README.md`
- `frontend/web-react/package.json`

**App Mobile :**
- `mobile/app-flutter/README.md`
- `mobile/app-flutter/pubspec.yaml`
- `mobile/app-flutter/lib/main.dart`

**Backend API :**
- `backend/api-moderne/README.md`
- `backend/api-moderne/server.js`
- `backend/api-moderne/.env.example`

**USSD Gateway :**
- `mobile/ussd-gateway/INTEGRATION_BACKEND.md`
- `mobile/ussd-gateway/QUICK_START.md`

**Admin Dashboard :**
- `admin/dashboard-web/README.md`
- `admin/dashboard-web/index.html`

---

## 🚀 Commandes Rapides

### Frontend Web
```bash
cd frontend/web-react
npm install
npm run dev
```

### App Mobile
```bash
cd mobile/app-flutter
flutter pub get
flutter run
```

### Backend API
```bash
cd backend/api-moderne
npm install
npm run dev
```

### Admin Dashboard
```bash
cd admin/dashboard-web
python -m http.server 8000
```

### USSD Gateway
```bash
cd mobile/ussd-gateway
flutter pub get
flutter run
```

---

## 📦 Dépendances Principales

### Frontend Web
- React 18.3.1
- TypeScript 5.5.3
- Vite 5.4.2
- Tailwind CSS 3.4.1

### App Mobile
- Flutter 3.35.1
- Firebase (Auth, Firestore, Messaging)
- Provider 6.1.0
- Google Sign-In 7.2.0

### Backend
- Node.js >= 16.0.0
- Express 4.18.2
- Firebase Admin 13.5.0
- Winston 3.11.0

---

## 🔐 Configuration Requise

### Variables d'Environnement Backend
```env
API_KEY=votre-cle-api
JWT_SECRET=votre-jwt-secret
FIREBASE_PROJECT_ID=votre-project-id
FIREBASE_PRIVATE_KEY=votre-private-key
FIREBASE_CLIENT_EMAIL=votre-client-email
```

### Firebase Configuration
1. Créer projet Firebase Console
2. Activer Authentication (Email, Google, Phone)
3. Créer base Firestore
4. Télécharger `google-services.json` (Android)
5. Configurer dans chaque projet

---

## 📱 Taille des Dossiers

```
frontend/web-react/       ~50 MB  (avec node_modules)
frontend/site-vitrine/    ~38 MB  (avec APK)
mobile/app-flutter/       ~200 MB (avec build/)
mobile/ussd-gateway/      ~150 MB
backend/api-moderne/      ~80 MB  (avec node_modules)
backend/api-legacy/       ~60 MB
admin/dashboard-web/      ~5 MB
admin/dashboard-flutter/  ~100 MB

TOTAL : ~683 MB
```

---

## 🎯 Prochaines Étapes Recommandées

1. **Lire le README.md principal**
2. **Explorer mobile/app-flutter/** (projet principal)
3. **Lire RAPPORT_AVANCEMENT.md** (état détaillé)
4. **Configurer backend/api-moderne/** 
5. **Tester l'intégration complète**

---

**📅 Index généré le :** 2 novembre 2025  
**📌 Version :** 1.0  
**👨‍💻 Projet :** MeRecharge Documentation Complète
