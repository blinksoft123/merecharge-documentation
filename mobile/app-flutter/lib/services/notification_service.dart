import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service de gestion des notifications push
class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Initialiser le service de notifications
  Future<void> initialize() async {
    // Demander la permission pour les notifications (iOS)
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('Permission status: ${settings.authorizationStatus}');

    // Configuration des notifications locales pour Android
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Configuration des notifications locales pour iOS
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Créer un canal de notification Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'merecharge_channel', // id
      'MeRecharge Notifications', // name
      description: 'Notifications pour les transactions et mises à jour',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Gérer les notifications en avant-plan
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Gérer les notifications en arrière-plan
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

    // Vérifier si l'app a été ouverte depuis une notification
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleBackgroundMessage(initialMessage);
    }

    // Obtenir et sauvegarder le token FCM
    await _saveDeviceToken();
  }

  /// Sauvegarder le token FCM dans Firestore
  Future<void> _saveDeviceToken() async {
    final user = _auth.currentUser;
    if (user == null) return;

    String? token = await _firebaseMessaging.getToken();
    if (token == null) return;

    print('FCM Token: $token');

    // Sauvegarder le token dans Firestore
    await _firestore.collection('users').doc(user.uid).update({
      'fcmToken': token,
      'lastTokenUpdate': FieldValue.serverTimestamp(),
    });

    // Écouter les changements de token
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      _firestore.collection('users').doc(user.uid).update({
        'fcmToken': newToken,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Gérer les notifications reçues en avant-plan
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Message reçu en avant-plan: ${message.messageId}');

    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    // Afficher la notification localement
    if (notification != null && android != null) {
      await _showLocalNotification(
        title: notification.title ?? 'MeRecharge',
        body: notification.body ?? '',
        payload: message.data.toString(),
      );
    }

    // Sauvegarder dans Firestore
    await _saveNotificationToFirestore(message);
  }

  /// Gérer les notifications en arrière-plan ou terminées
  Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    print('Message reçu en arrière-plan: ${message.messageId}');
    
    // Sauvegarder dans Firestore
    await _saveNotificationToFirestore(message);
    
    // TODO: Navigation vers l'écran approprié basé sur les données
    // Navigator.pushNamed(context, '/notification-detail', arguments: message.data);
  }

  /// Afficher une notification locale
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'merecharge_channel',
      'MeRecharge Notifications',
      channelDescription: 'Notifications pour les transactions et mises à jour',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Gérer le tap sur une notification
  void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    // TODO: Navigation vers l'écran approprié
  }

  /// Sauvegarder la notification dans Firestore
  Future<void> _saveNotificationToFirestore(RemoteMessage message) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('notifications').add({
        'userId': user.uid,
        'title': message.notification?.title ?? 'Notification',
        'message': message.notification?.body ?? '',
        'data': message.data,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Erreur lors de la sauvegarde de la notification: $e');
    }
  }

  /// Envoyer une notification locale personnalisée
  Future<void> sendLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    await _showLocalNotification(
      title: title,
      body: body,
      payload: data?.toString(),
    );
  }

  /// S'abonner à un topic
  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
    print('Abonné au topic: $topic');
  }

  /// Se désabonner d'un topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
    print('Désabonné du topic: $topic');
  }

  /// Obtenir le nombre de notifications non lues
  Stream<int> getUnreadNotificationsCount() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(0);

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Supprimer le token FCM (lors de la déconnexion)
  Future<void> deleteToken() async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firebaseMessaging.deleteToken();
    
    await _firestore.collection('users').doc(user.uid).update({
      'fcmToken': FieldValue.delete(),
    });
  }
}

/// Fonction pour gérer les notifications en arrière-plan (top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling background message: ${message.messageId}');
  // Cette fonction doit être top-level ou static
}
