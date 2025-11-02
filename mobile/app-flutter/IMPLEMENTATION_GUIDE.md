# Guide d'Implémentation MeRecharge - Authentification & Services

## 🎯 Ce qui a été implémenté

### 1. ✅ Authentification Complète

#### A. Méthodes d'authentification disponibles
- **Google Sign-In** - Connexion via compte Google
- **Authentification par téléphone** - OTP SMS
- **Email/Password** - Connexion traditionnelle (maintenu pour admin)

#### B. Service `AuthService` (`lib/services/auth_service.dart`)

**Méthodes Google Sign-In:**
```dart
// Connexion avec Google
Future<Map<String, dynamic>> signInWithGoogle()
```

**Méthodes d'authentification par téléphone:**
```dart
// Étape 1: Envoyer le code SMS
Future<Map<String, dynamic>> signInWithPhoneNumber({
  required String phoneNumber,
  required Function(String verificationId, int? resendToken) codeSent,
  required Function(String error) verificationFailed,
})

// Étape 2: Vérifier le code
Future<Map<String, dynamic>> verifyPhoneCode({
  required String verificationId,
  required String smsCode,
  String? name,
})
```

**Autres méthodes:**
- `signOut()` - Déconnexion
- `resetPassword(email)` - Réinitialiser mot de passe
- `changePassword()` - Changer mot de passe
- `getUserData(uid)` - Récupérer données utilisateur
- `isEmailVerified()` - Vérifier email
- `deleteAccount()` - Supprimer compte

### 2. ✅ Service Firestore Complet

#### Service `FirestoreService` (`lib/services/firestore_service.dart`)

**Gestion des utilisateurs:**
```dart
Future<Map<String, dynamic>?> getCurrentUserData()
Future<bool> updateBalance(String uid, double newBalance)
Future<bool> addBalance(String uid, double amount)
Future<bool> deductBalance(String uid, double amount)
```

**Gestion des transactions:**
```dart
Future<String?> createTransaction({
  required String userId,
  required String type, // 'recharge', 'deposit', 'withdraw', 'transfer', 'purchase'
  required double amount,
  required String status, // 'pending', 'completed', 'failed', 'cancelled'
  Map<String, dynamic>? details,
})

Stream<QuerySnapshot> getUserTransactions(String userId, {int limit = 50})
Future<bool> updateTransactionStatus(String transactionId, String status)
```

**Gestion des produits:**
```dart
Stream<QuerySnapshot> getProducts({String? category})
Future<Map<String, dynamic>?> getProduct(String productId)
Future<String?> createProduct(Map<String, dynamic> productData) // Admin
```

**Gestion des commandes:**
```dart
Future<String?> createOrder({
  required String userId,
  required List<Map<String, dynamic>> items,
  required String deliveryAddress,
  required String phoneNumber,
  ...
})

Stream<QuerySnapshot> getUserOrders(String userId, {int limit = 50})
Future<bool> updateOrderStatus(String orderId, String status)
Stream<QuerySnapshot> getAllOrders({int limit = 100}) // Admin
```

**Gestion des notifications:**
```dart
Future<String?> createNotification({
  required String userId,
  required String title,
  required String message,
  String type = 'info',
  Map<String, dynamic>? data,
})

Stream<QuerySnapshot> getUserNotifications(String userId, {int limit = 50})
Future<bool> markNotificationAsRead(String notificationId)
Future<bool> markAllNotificationsAsRead(String userId)
```

**Recharges spécifiques:**
```dart
Future<String?> createRecharge({
  required String userId,
  required String phoneNumber,
  required String operator,
  required double amount,
  required String paymentMethod,
})

Future<String?> createBundlePurchase({
  required String userId,
  required String phoneNumber,
  required String operator,
  required String bundleType,
  required double amount,
  Map<String, dynamic>? bundleDetails,
})
```

**Statistiques:**
```dart
Future<Map<String, dynamic>> getUserStats(String userId)
```

### 3. ✅ Service de Notifications Push

#### Service `NotificationService` (`lib/services/notification_service.dart`)

**Fonctionnalités principales:**
```dart
// Initialiser les notifications (à appeler au démarrage)
Future<void> initialize()

// Envoyer une notification locale
Future<void> sendLocalNotification({
  required String title,
  required String body,
  Map<String, dynamic>? data,
})

// Gestion des topics
Future<void> subscribeToTopic(String topic)
Future<void> unsubscribeFromTopic(String topic)

// Obtenir le nombre de notifications non lues
Stream<int> getUnreadNotificationsCount()

// Supprimer le token (déconnexion)
Future<void> deleteToken()
```

**Caractéristiques:**
- ✅ Gestion des notifications en avant-plan
- ✅ Gestion des notifications en arrière-plan
- ✅ Sauvegarde automatique dans Firestore
- ✅ Badge de notifications non lues
- ✅ Support Android et iOS
- ✅ Canal de notification personnalisé

## 📱 Collections Firestore Créées

### 1. Collection `users`
```json
{
  "uid": "string",
  "email": "string (optionnel)",
  "phoneNumber": "string (optionnel)",
  "name": "string",
  "photoURL": "string (optionnel)",
  "balance": 0.0,
  "createdAt": "timestamp",
  "updatedAt": "timestamp",
  "isVerified": false,
  "role": "user|admin",
  "provider": "phone|google|email",
  "fcmToken": "string (optionnel)"
}
```

### 2. Collection `transactions`
```json
{
  "userId": "string",
  "type": "recharge|deposit|withdraw|transfer|purchase|bundle",
  "amount": 0.0,
  "status": "pending|completed|failed|cancelled",
  "details": {
    "phoneNumber": "string",
    "operator": "MTN|Orange|Camtel",
    "paymentMethod": "string",
    ...
  },
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

### 3. Collection `products`
```json
{
  "id": "string",
  "name": "string",
  "description": "string",
  "price": 0.0,
  "category": "string",
  "imageUrl": "string",
  "isAvailable": true,
  "specifications": {},
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

### 4. Collection `orders`
```json
{
  "userId": "string",
  "items": [
    {
      "productId": "string",
      "quantity": 1,
      "unitPrice": 0.0
    }
  ],
  "status": "pending|confirmed|processing|shipped|delivered|cancelled",
  "deliveryAddress": "string",
  "phoneNumber": "string",
  "shippingCost": 0.0,
  "tax": 0.0,
  "notes": "string (optionnel)",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

### 5. Collection `notifications`
```json
{
  "userId": "string",
  "title": "string",
  "message": "string",
  "type": "info|success|warning|error",
  "data": {},
  "isRead": false,
  "createdAt": "timestamp"
}
```

## 🚀 Comment Utiliser

### 1. Initialisation dans `main.dart`

```dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/notification_service.dart';

// Handler pour notifications en arrière-plan
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('Handling background message: ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialiser les notifications
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  final notificationService = NotificationService();
  await notificationService.initialize();
  
  runApp(
    MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
        Provider<NotificationService>(create: (_) => notificationService),
        ChangeNotifierProvider(create: (_) => SettingsController()),
      ],
      child: const App(),
    ),
  );
}
```

### 2. Exemple: Connexion avec Google

```dart
final authService = Provider.of<AuthService>(context, listen: false);

// Connexion Google
final result = await authService.signInWithGoogle();

if (result['success']) {
  Navigator.pushReplacementNamed(context, '/home');
} else {
  // Afficher l'erreur
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(result['error'])),
  );
}
```

### 3. Exemple: Authentification par téléphone

```dart
final authService = Provider.of<AuthService>(context, listen: false);
String? verificationId;

// Étape 1: Envoyer le code
await authService.signInWithPhoneNumber(
  phoneNumber: '+237600000000',
  codeSent: (String verId, int? resendToken) {
    setState(() {
      verificationId = verId;
    });
    // Afficher le champ de saisie du code
  },
  verificationFailed: (String error) {
    // Afficher l'erreur
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error)),
    );
  },
);

// Étape 2: Vérifier le code (après que l'utilisateur l'ait saisi)
final result = await authService.verifyPhoneCode(
  verificationId: verificationId!,
  smsCode: codeController.text,
  name: 'Nom de l'utilisateur',
);

if (result['success']) {
  Navigator.pushReplacementNamed(context, '/home');
}
```

### 4. Exemple: Créer une transaction

```dart
final firestoreService = Provider.of<FirestoreService>(context, listen: false);
final user = FirebaseAuth.instance.currentUser;

final transactionId = await firestoreService.createRecharge(
  userId: user!.uid,
  phoneNumber: '+237600000000',
  operator: 'MTN',
  amount: 1000.0,
  paymentMethod: 'Orange Money',
);

if (transactionId != null) {
  print('Transaction créée: $transactionId');
}
```

### 5. Exemple: Écouter les transactions en temps réel

```dart
final firestoreService = Provider.of<FirestoreService>(context, listen: false);
final user = FirebaseAuth.instance.currentUser;

return StreamBuilder<QuerySnapshot>(
  stream: firestoreService.getUserTransactions(user!.uid),
  builder: (context, snapshot) {
    if (!snapshot.hasData) {
      return CircularProgressIndicator();
    }

    final transactions = snapshot.data!.docs;
    
    return ListView.builder(
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index].data() as Map<String, dynamic>;
        return ListTile(
          title: Text('${transaction['type']}'),
          subtitle: Text('${transaction['amount']} XAF'),
          trailing: Text('${transaction['status']}'),
        );
      },
    );
  },
);
```

### 6. Exemple: Envoyer une notification locale

```dart
final notificationService = Provider.of<NotificationService>(context, listen: false);

await notificationService.sendLocalNotification(
  title: 'Recharge réussie',
  body: 'Votre recharge de 1000 XAF a été effectuée avec succès',
  data: {'transactionId': '123'},
);
```

## 📦 Packages Requis

Assurez-vous que `pubspec.yaml` contient:

```yaml
dependencies:
  firebase_core: ^3.15.0
  firebase_auth: ^5.7.0
  cloud_firestore: ^5.6.0
  firebase_messaging: ^15.2.0
  flutter_local_notifications: ^17.2.0
  google_sign_in: ^6.2.2
  provider: ^6.1.0
```

## 🔧 Configuration Android

### 1. `android/app/build.gradle.kts`
```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}
```

### 2. `android/app/google-services.json`
✅ Déjà présent

### 3. Permissions dans `AndroidManifest.xml`
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.VIBRATE" />
```

## 🍎 Configuration iOS

### 1. Ajouter `GoogleService-Info.plist` dans `ios/Runner/`

### 2. Permissions dans `Info.plist`
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>Cette app nécessite l'accès aux photos</string>
<key>NSCameraUsageDescription</key>
<string>Cette app nécessite l'accès à la caméra</string>
```

## 🔐 Règles de Sécurité Firestore

Les règles sont déjà déployées. Vérifiez-les dans `firestore.rules`.

## 📊 Prochaines Étapes

### Phase 1: Intégration UI
- [ ] Créer l'écran de connexion avec options (Google + Téléphone)
- [ ] Implémenter le flux d'authentification par téléphone
- [ ] Intégrer les services dans les écrans existants

### Phase 2: Logique Métier
- [ ] Implémenter la logique de recharge
- [ ] Implémenter la logique d'achat de forfaits
- [ ] Implémenter la logique de transfert

### Phase 3: Notifications
- [ ] Tester les notifications push
- [ ] Configurer Firebase Cloud Functions pour envoyer des notifications
- [ ] Créer l'écran de notifications

### Phase 4: Paiements
- [ ] Intégrer Orange Money API
- [ ] Intégrer MTN Mobile Money API
- [ ] Implémenter la vérification des paiements

## 🆘 Commandes Utiles

```bash
# Installer les dépendances
flutter pub get

# Lancer l'app
flutter run

# Déployer les règles Firestore
firebase deploy --only firestore:rules

# Voir les logs Firebase
firebase functions:log
```

---

**Documentation complète**: `FIREBASE_SETUP.md`
**Dernière mise à jour**: 2025-10-13
