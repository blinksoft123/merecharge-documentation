# Configuration Firebase - MeRecharge

## ✅ Configuration Complétée

### 1. Compte Firebase Connecté
- **Email**: investbligroup@gmail.com
- **Projet**: merecharge-50ab0
- **Project Number**: 891263588555

### 2. Fichiers Créés

#### Configuration Firebase
- ✅ `lib/firebase_options.dart` - Options de configuration multi-plateforme
- ✅ `firebase.json` - Configuration Firebase CLI
- ✅ `firestore.rules` - Règles de sécurité Firestore (déployées ✅)
- ✅ `firestore.indexes.json` - Index Firestore

#### Services
- ✅ `lib/services/auth_service.dart` - Service d'authentification complet
  - Inscription
  - Connexion
  - Déconnexion
  - Réinitialisation de mot de passe
  - Changement de mot de passe
  - Vérification email
  - Suppression de compte

#### Écrans de Test
- ✅ `lib/screens/firebase_test_screen.dart` - Interface de test Firebase
- ✅ Route ajoutée: `/dev/firebase-test`
- ✅ Bouton d'accès depuis l'écran de bienvenue

### 3. Règles Firestore Déployées

Les règles de sécurité suivantes sont actives:

- **Collection `test`**: Lecture/écriture ouverte (pour les tests)
- **Collection `users`**: Chaque utilisateur peut lire/écrire ses propres données
- **Collection `transactions`**: Utilisateur peut voir uniquement ses transactions
- **Collection `orders`**: Utilisateur peut voir uniquement ses commandes
- **Collection `products`**: Lecture publique, écriture admin uniquement
- **Collection `notifications`**: Lecture par utilisateur, création par admin

### 4. Fonctionnalités Firebase Disponibles

✅ **Firebase Core** - Initialisé
✅ **Firebase Auth** - Authentification email/password
✅ **Cloud Firestore** - Base de données en temps réel
✅ **Firebase Messaging** - Notifications push (configuré)
✅ **Local Notifications** - Notifications locales

## 🚀 Comment Tester Firebase

### Option 1: Via l'Application Flutter

1. Lancez l'application:
```bash
flutter run -d <device_id>
```

2. Sur l'écran de bienvenue, cliquez sur **"Test Firebase"**

3. Dans l'écran de test:
   - Cliquez sur **"Vérifier Firebase"** pour tester la connexion
   - Utilisez **"Test Inscription"** pour créer un compte
   - Utilisez **"Test Connexion"** pour vous connecter
   - Utilisez **"Test Déconnexion"** pour vous déconnecter

### Option 2: Via le Script de Test

```bash
dart test_firebase.dart
```

Ce script testera:
- ✅ Initialisation Firebase
- ✅ Disponibilité Firebase Auth
- ✅ Écriture dans Firestore
- ✅ Lecture depuis Firestore

## 📱 Plateformes Configurées

- ✅ **Android** - `google-services.json` présent
- ✅ **iOS** - Configuration disponible (nécessite `GoogleService-Info.plist`)
- ✅ **Web** - Configuration disponible
- ✅ **macOS** - Configuration disponible

## 🔐 Sécurité

### Configuration Actuelle
- ✅ Règles Firestore déployées et sécurisées
- ✅ Authentification requise pour la plupart des opérations
- ✅ Séparation des rôles (user/admin)
- ⚠️ Collection `test` ouverte (à sécuriser en production)

### À Faire pour la Production
- [ ] Activer les règles d'authentification par email
- [ ] Configurer les domaines autorisés
- [ ] Activer le mode production pour Firestore
- [ ] Supprimer ou sécuriser la collection `test`
- [ ] Configurer les quotas et limites
- [ ] Activer la facturation Firebase

## 🔧 Commandes Firebase Utiles

### Vérifier le projet actuel
```bash
firebase projects:list
```

### Déployer les règles Firestore
```bash
firebase deploy --only firestore:rules
```

### Déployer les index Firestore
```bash
firebase deploy --only firestore:indexes
```

### Voir les logs
```bash
firebase functions:log
```

### Ouvrir la console Firebase
```bash
firebase open
```

## 📊 Console Firebase

Accédez à votre projet: [https://console.firebase.google.com/project/merecharge-50ab0](https://console.firebase.google.com/project/merecharge-50ab0)

### Sections Importantes
- **Authentication** - Gérer les utilisateurs
- **Firestore Database** - Voir les données
- **Storage** - Fichiers uploadés
- **Functions** - Cloud Functions (si utilisées)
- **Hosting** - Hébergement web
- **Analytics** - Statistiques d'utilisation

## ⚠️ Notes Importantes

1. **Environnement de Développement**
   - Les règles actuelles permettent le test facile
   - À durcir avant la mise en production

2. **Authentification**
   - Email/Password configuré
   - Vérification d'email activée
   - Réinitialisation de mot de passe disponible

3. **Firestore**
   - Mode test activé
   - Index créés pour les requêtes communes
   - Règles de sécurité basiques en place

4. **Prochaines Étapes**
   - Tester l'inscription/connexion
   - Créer les collections de données
   - Implémenter la logique métier
   - Configurer les notifications push
   - Ajouter les Cloud Functions si nécessaire

## 🆘 Dépannage

### Erreur de connexion Firebase
```bash
firebase login --reauth
firebase use merecharge-50ab0
```

### Erreur de règles Firestore
```bash
firebase deploy --only firestore:rules
```

### Erreur de build Android
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

### Vérifier la configuration
```bash
flutter doctor -v
```

## 📞 Support

En cas de problème:
1. Vérifiez la console Firebase pour les erreurs
2. Consultez les logs de l'application
3. Vérifiez que Firebase est bien initialisé dans `main.dart`
4. Assurez-vous que les règles Firestore sont déployées

---

**Dernière mise à jour**: 2025-10-13
**Configuration par**: Agent Mode (Warp AI)
