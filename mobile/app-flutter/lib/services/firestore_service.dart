import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ====================
  // UTILISATEURS
  // ====================

  /// Obtenir les données de l'utilisateur connecté
  Future<Map<String, dynamic>?> getCurrentUserData() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data();
  }

  /// Obtenir les données d'un utilisateur par UID
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data();
  }

  /// Mettre à jour le solde de l'utilisateur
  Future<bool> updateBalance(String uid, double newBalance) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'balance': newBalance,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Erreur lors de la mise à jour du solde: $e');
      return false;
    }
  }

  /// Ajouter du crédit au solde
  Future<bool> addBalance(String uid, double amount) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'balance': FieldValue.increment(amount),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Erreur lors de l\'ajout de crédit: $e');
      return false;
    }
  }

  /// Retirer du crédit du solde
  Future<bool> deductBalance(String uid, double amount) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'balance': FieldValue.increment(-amount),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Erreur lors du retrait: $e');
      return false;
    }
  }

  // ====================
  // TRANSACTIONS
  // ====================

  /// Créer une nouvelle transaction
  Future<String?> createTransaction({
    required String userId,
    required String type, // 'recharge', 'deposit', 'withdraw', 'transfer', 'purchase'
    required double amount,
    required String status, // 'pending', 'completed', 'failed', 'cancelled'
    Map<String, dynamic>? details,
  }) async {
    try {
      final docRef = await _firestore.collection('transactions').add({
        'userId': userId,
        'type': type,
        'amount': amount,
        'status': status,
        'details': details ?? {},
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      print('Erreur lors de la création de la transaction: $e');
      return null;
    }
  }

  /// Mettre à jour le statut d'une transaction
  Future<bool> updateTransactionStatus(String transactionId, String status) async {
    try {
      await _firestore.collection('transactions').doc(transactionId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Erreur lors de la mise à jour: $e');
      return false;
    }
  }

  /// Obtenir les transactions d'un utilisateur
  Stream<QuerySnapshot> getUserTransactions(String userId, {int limit = 50}) {
    return _firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots();
  }

  /// Obtenir une transaction spécifique
  Future<Map<String, dynamic>?> getTransaction(String transactionId) async {
    final doc = await _firestore.collection('transactions').doc(transactionId).get();
    return doc.data();
  }

  // ====================
  // PRODUITS
  // ====================

  /// Obtenir tous les produits
  Stream<QuerySnapshot> getProducts({String? category}) {
    Query query = _firestore.collection('products');
    
    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }
    
    return query.where('isAvailable', isEqualTo: true).snapshots();
  }

  /// Obtenir un produit spécifique
  Future<Map<String, dynamic>?> getProduct(String productId) async {
    final doc = await _firestore.collection('products').doc(productId).get();
    return doc.data();
  }

  /// Créer un produit (admin uniquement)
  Future<String?> createProduct(Map<String, dynamic> productData) async {
    try {
      final docRef = await _firestore.collection('products').add({
        ...productData,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      print('Erreur lors de la création du produit: $e');
      return null;
    }
  }

  // ====================
  // COMMANDES
  // ====================

  /// Créer une nouvelle commande
  Future<String?> createOrder({
    required String userId,
    required List<Map<String, dynamic>> items,
    required String deliveryAddress,
    required String phoneNumber,
    double shippingCost = 0.0,
    double tax = 0.0,
    String? notes,
  }) async {
    try {
      final docRef = await _firestore.collection('orders').add({
        'userId': userId,
        'items': items,
        'status': 'pending',
        'deliveryAddress': deliveryAddress,
        'phoneNumber': phoneNumber,
        'shippingCost': shippingCost,
        'tax': tax,
        'notes': notes,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      print('Erreur lors de la création de la commande: $e');
      return null;
    }
  }

  /// Obtenir les commandes d'un utilisateur
  Stream<QuerySnapshot> getUserOrders(String userId, {int limit = 50}) {
    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots();
  }

  /// Mettre à jour le statut d'une commande
  Future<bool> updateOrderStatus(String orderId, String status) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Erreur lors de la mise à jour: $e');
      return false;
    }
  }

  /// Obtenir toutes les commandes (admin)
  Stream<QuerySnapshot> getAllOrders({int limit = 100}) {
    return _firestore
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots();
  }

  // ====================
  // NOTIFICATIONS
  // ====================

  /// Créer une notification
  Future<String?> createNotification({
    required String userId,
    required String title,
    required String message,
    String type = 'info', // 'info', 'success', 'warning', 'error'
    Map<String, dynamic>? data,
  }) async {
    try {
      final docRef = await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'message': message,
        'type': type,
        'data': data ?? {},
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      print('Erreur lors de la création de la notification: $e');
      return null;
    }
  }

  /// Obtenir les notifications d'un utilisateur
  Stream<QuerySnapshot> getUserNotifications(String userId, {int limit = 50}) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots();
  }

  /// Marquer une notification comme lue
  Future<bool> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });
      return true;
    } catch (e) {
      print('Erreur: $e');
      return false;
    }
  }

  /// Marquer toutes les notifications comme lues
  Future<bool> markAllNotificationsAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in notifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
      return true;
    } catch (e) {
      print('Erreur: $e');
      return false;
    }
  }

  // ====================
  // RECHARGES
  // ====================

  /// Créer une recharge de crédit
  Future<String?> createRecharge({
    required String userId,
    required String phoneNumber,
    required String operator,
    required double amount,
    required String paymentMethod,
  }) async {
    try {
      // Créer une transaction
      final transactionId = await createTransaction(
        userId: userId,
        type: 'recharge',
        amount: amount,
        status: 'pending',
        details: {
          'phoneNumber': phoneNumber,
          'operator': operator,
          'paymentMethod': paymentMethod,
        },
      );

      return transactionId;
    } catch (e) {
      print('Erreur lors de la recharge: $e');
      return null;
    }
  }

  /// Créer un achat de forfait
  Future<String?> createBundlePurchase({
    required String userId,
    required String phoneNumber,
    required String operator,
    required String bundleType,
    required double amount,
    Map<String, dynamic>? bundleDetails,
  }) async {
    try {
      final transactionId = await createTransaction(
        userId: userId,
        type: 'bundle',
        amount: amount,
        status: 'pending',
        details: {
          'phoneNumber': phoneNumber,
          'operator': operator,
          'bundleType': bundleType,
          'bundleDetails': bundleDetails ?? {},
        },
      );

      return transactionId;
    } catch (e) {
      print('Erreur lors de l\'achat: $e');
      return null;
    }
  }

  // ====================
  // STATISTIQUES
  // ====================

  /// Obtenir les statistiques de l'utilisateur
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      // Nombre total de transactions
      final transactionsSnapshot = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .get();

      // Montant total dépensé
      double totalSpent = 0;
      int completedTransactions = 0;

      for (var doc in transactionsSnapshot.docs) {
        final data = doc.data();
        if (data['status'] == 'completed') {
          totalSpent += (data['amount'] as num).toDouble();
          completedTransactions++;
        }
      }

      // Nombre de commandes
      final ordersSnapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .get();

      return {
        'totalTransactions': transactionsSnapshot.docs.length,
        'completedTransactions': completedTransactions,
        'totalSpent': totalSpent,
        'totalOrders': ordersSnapshot.docs.length,
      };
    } catch (e) {
      print('Erreur lors de la récupération des stats: $e');
      return {};
    }
  }
}
