import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ===============================
  // AUTHENTIFICATION ADMIN
  // ===============================

  /// Vérifier si l'utilisateur actuel est admin
  Future<bool> isAdmin() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final doc = await _firestore.collection('admins').doc(user.uid).get();
      return doc.exists && doc.data()?['isActive'] == true;
    } catch (e) {
      print('Erreur vérification admin: $e');
      return false;
    }
  }

  /// Connexion admin avec email/mot de passe
  Future<bool> adminLogin(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Vérifier si c'est bien un admin
        final isAdminUser = await isAdmin();
        if (!isAdminUser) {
          await _auth.signOut();
          return false;
        }

        // Log de connexion admin
        await _logAdminActivity(
          'login',
          {'timestamp': FieldValue.serverTimestamp()},
        );

        return true;
      }
      return false;
    } catch (e) {
      print('Erreur connexion admin: $e');
      return false;
    }
  }

  // ===============================
  // STATISTIQUES DASHBOARD
  // ===============================

  /// Récupérer les statistiques du dashboard
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final yesterdayStart = todayStart.subtract(const Duration(days: 1));

      // Statistiques utilisateurs
      final usersSnapshot = await _firestore.collection('users').get();
      final totalUsers = usersSnapshot.docs.length;

      // Utilisateurs actifs (connectés dans les 7 derniers jours)
      final activeUsersSnapshot = await _firestore
          .collection('users')
          .where('lastLoginAt', isGreaterThan: now.subtract(const Duration(days: 7)))
          .get();
      final activeUsers = activeUsersSnapshot.docs.length;

      // Transactions du jour
      final todayTransactionsSnapshot = await _firestore
          .collection('transactions')
          .where('createdAt', isGreaterThan: Timestamp.fromDate(todayStart))
          .get();
      final todayTransactions = todayTransactionsSnapshot.docs.length;

      // Transactions d'hier pour comparaison
      final yesterdayTransactionsSnapshot = await _firestore
          .collection('transactions')
          .where('createdAt', isGreaterThan: Timestamp.fromDate(yesterdayStart))
          .where('createdAt', isLessThan: Timestamp.fromDate(todayStart))
          .get();
      final yesterdayTransactions = yesterdayTransactionsSnapshot.docs.length;

      // Calcul des revenus du jour
      double todayRevenue = 0;
      double yesterdayRevenue = 0;

      for (var doc in todayTransactionsSnapshot.docs) {
        final data = doc.data();
        if (data['status'] == 'completed') {
          todayRevenue += (data['amount'] as num?)?.toDouble() ?? 0;
        }
      }

      for (var doc in yesterdayTransactionsSnapshot.docs) {
        final data = doc.data();
        if (data['status'] == 'completed') {
          yesterdayRevenue += (data['amount'] as num?)?.toDouble() ?? 0;
        }
      }

      // Commandes pendantes
      final pendingOrdersSnapshot = await _firestore
          .collection('orders')
          .where('status', isEqualTo: 'pending')
          .get();
      final pendingOrders = pendingOrdersSnapshot.docs.length;

      // Calcul des tendances
      String transactionsTrend = _calculateTrend(todayTransactions, yesterdayTransactions);
      String revenueTrend = _calculateTrend(todayRevenue, yesterdayRevenue);
      String usersTrend = '+5%'; // Simulé pour l'exemple

      return {
        'totalUsers': totalUsers,
        'activeUsers': activeUsers,
        'todayTransactions': todayTransactions,
        'todayRevenue': todayRevenue,
        'pendingOrders': pendingOrders,
        'transactionsTrend': transactionsTrend,
        'revenueTrend': revenueTrend,
        'usersTrend': usersTrend,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('Erreur récupération statistiques: $e');
      return {};
    }
  }

  String _calculateTrend(dynamic today, dynamic yesterday) {
    if (yesterday == 0) return '+100%';
    
    final difference = today - yesterday;
    final percentage = (difference / yesterday * 100).round();
    
    return percentage >= 0 ? '+$percentage%' : '$percentage%';
  }

  // ===============================
  // GESTION UTILISATEURS
  // ===============================

  /// Récupérer tous les utilisateurs avec pagination
  Future<Map<String, dynamic>> getAllUsers({
    int limit = 20,
    DocumentSnapshot? lastDocument,
    String? searchQuery,
  }) async {
    try {
      Query query = _firestore.collection('users').orderBy('createdAt', descending: true);

      if (searchQuery != null && searchQuery.isNotEmpty) {
        // Recherche par email ou nom
        query = query
            .where('email', isGreaterThanOrEqualTo: searchQuery)
            .where('email', isLessThanOrEqualTo: '$searchQuery\uf8ff');
      }

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      query = query.limit(limit);

      final snapshot = await query.get();
      final users = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();

      return {
        'users': users,
        'hasMore': snapshot.docs.length == limit,
        'lastDocument': snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
      };
    } catch (e) {
      print('Erreur récupération utilisateurs: $e');
      return {'users': [], 'hasMore': false};
    }
  }

  /// Suspendre/réactiver un utilisateur
  Future<bool> toggleUserStatus(String userId, bool isActive) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _logAdminActivity(
        isActive ? 'user_activated' : 'user_suspended',
        {'userId': userId},
      );

      return true;
    } catch (e) {
      print('Erreur modification statut utilisateur: $e');
      return false;
    }
  }

  /// Mettre à jour le solde d'un utilisateur
  Future<bool> updateUserBalance(String userId, double newBalance, String reason) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'balance': newBalance,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Créer une transaction pour traçabilité
      await _firestore.collection('transactions').add({
        'userId': userId,
        'type': 'admin_adjustment',
        'amount': newBalance,
        'status': 'completed',
        'details': {'reason': reason, 'adjustedBy': _auth.currentUser?.uid},
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _logAdminActivity(
        'balance_updated',
        {'userId': userId, 'newBalance': newBalance, 'reason': reason},
      );

      return true;
    } catch (e) {
      print('Erreur mise à jour solde: $e');
      return false;
    }
  }

  // ===============================
  // GESTION TRANSACTIONS
  // ===============================

  /// Récupérer toutes les transactions avec filtres
  Stream<QuerySnapshot> getAllTransactions({
    String? status,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) {
    Query query = _firestore.collection('transactions').orderBy('createdAt', descending: true);

    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }

    if (type != null) {
      query = query.where('type', isEqualTo: type);
    }

    if (startDate != null) {
      query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }

    if (endDate != null) {
      query = query.where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }

    return query.limit(limit).snapshots();
  }

  /// Mettre à jour le statut d'une transaction
  Future<bool> updateTransactionStatus(String transactionId, String newStatus) async {
    try {
      await _firestore.collection('transactions').doc(transactionId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _auth.currentUser?.uid,
      });

      await _logAdminActivity(
        'transaction_status_updated',
        {'transactionId': transactionId, 'newStatus': newStatus},
      );

      return true;
    } catch (e) {
      print('Erreur mise à jour transaction: $e');
      return false;
    }
  }

  // ===============================
  // GESTION PRODUITS
  // ===============================

  /// Ajouter un nouveau produit
  Future<String?> createProduct(Map<String, dynamic> productData) async {
    try {
      final docRef = await _firestore.collection('products').add({
        ...productData,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'createdBy': _auth.currentUser?.uid,
      });

      await _logAdminActivity(
        'product_created',
        {'productId': docRef.id, 'productName': productData['name']},
      );

      return docRef.id;
    } catch (e) {
      print('Erreur création produit: $e');
      return null;
    }
  }

  /// Mettre à jour un produit
  Future<bool> updateProduct(String productId, Map<String, dynamic> productData) async {
    try {
      await _firestore.collection('products').doc(productId).update({
        ...productData,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _auth.currentUser?.uid,
      });

      await _logAdminActivity(
        'product_updated',
        {'productId': productId},
      );

      return true;
    } catch (e) {
      print('Erreur mise à jour produit: $e');
      return false;
    }
  }

  /// Supprimer un produit (soft delete)
  Future<bool> deleteProduct(String productId) async {
    try {
      await _firestore.collection('products').doc(productId).update({
        'isDeleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
        'deletedBy': _auth.currentUser?.uid,
      });

      await _logAdminActivity(
        'product_deleted',
        {'productId': productId},
      );

      return true;
    } catch (e) {
      print('Erreur suppression produit: $e');
      return false;
    }
  }

  // ===============================
  // NOTIFICATIONS PUSH
  // ===============================

  /// Envoyer une notification à tous les utilisateurs
  Future<bool> sendBroadcastNotification({
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Récupérer tous les tokens FCM
      final usersSnapshot = await _firestore.collection('users').get();
      
      final batch = _firestore.batch();
      
      for (var userDoc in usersSnapshot.docs) {
        final notificationRef = _firestore.collection('notifications').doc();
        batch.set(notificationRef, {
          'userId': userDoc.id,
          'title': title,
          'message': message,
          'data': data ?? {},
          'type': 'broadcast',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      await _logAdminActivity(
        'broadcast_notification_sent',
        {'title': title, 'recipientCount': usersSnapshot.docs.length},
      );

      return true;
    } catch (e) {
      print('Erreur envoi notification broadcast: $e');
      return false;
    }
  }

  /// Envoyer une notification à un utilisateur spécifique
  Future<bool> sendUserNotification({
    required String userId,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'message': message,
        'data': data ?? {},
        'type': 'direct',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _logAdminActivity(
        'user_notification_sent',
        {'userId': userId, 'title': title},
      );

      return true;
    } catch (e) {
      print('Erreur envoi notification utilisateur: $e');
      return false;
    }
  }

  // ===============================
  // RAPPORTS ET ANALYSES
  // ===============================

  /// Générer un rapport pour une période donnée
  Future<Map<String, dynamic>> generateReport({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // Transactions dans la période
      final transactionsSnapshot = await _firestore
          .collection('transactions')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      // Analyse des transactions
      int totalTransactions = transactionsSnapshot.docs.length;
      int completedTransactions = 0;
      double totalRevenue = 0;
      Map<String, int> transactionsByType = {};
      Map<String, double> revenueByType = {};

      for (var doc in transactionsSnapshot.docs) {
        final data = doc.data();
        final type = data['type'] as String;
        final amount = (data['amount'] as num?)?.toDouble() ?? 0;
        final status = data['status'] as String;

        // Compteurs par type
        transactionsByType[type] = (transactionsByType[type] ?? 0) + 1;

        if (status == 'completed') {
          completedTransactions++;
          totalRevenue += amount;
          revenueByType[type] = (revenueByType[type] ?? 0) + amount;
        }
      }

      // Nouveaux utilisateurs dans la période
      final newUsersSnapshot = await _firestore
          .collection('users')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      return {
        'period': {
          'start': startDate.toIso8601String(),
          'end': endDate.toIso8601String(),
        },
        'transactions': {
          'total': totalTransactions,
          'completed': completedTransactions,
          'failed': totalTransactions - completedTransactions,
          'successRate': totalTransactions > 0 ? (completedTransactions / totalTransactions * 100).round() : 0,
          'byType': transactionsByType,
        },
        'revenue': {
          'total': totalRevenue,
          'byType': revenueByType,
        },
        'users': {
          'newUsers': newUsersSnapshot.docs.length,
        },
        'generatedAt': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('Erreur génération rapport: $e');
      return {};
    }
  }

  // ===============================
  // LOGS D'ACTIVITÉ ADMIN
  // ===============================

  /// Enregistrer une activité admin
  Future<void> _logAdminActivity(String action, Map<String, dynamic> details) async {
    try {
      await _firestore.collection('admin_logs').add({
        'adminId': _auth.currentUser?.uid,
        'action': action,
        'details': details,
        'timestamp': FieldValue.serverTimestamp(),
        'ipAddress': 'unknown', // À implémenter si nécessaire
      });
    } catch (e) {
      print('Erreur log activité admin: $e');
    }
  }

  /// Récupérer les logs d'activité admin
  Stream<QuerySnapshot> getAdminLogs({int limit = 100}) {
    return _firestore
        .collection('admin_logs')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots();
  }

  // ===============================
  // CONFIGURATION SYSTÈME
  // ===============================

  /// Récupérer la configuration système
  Future<Map<String, dynamic>> getSystemConfig() async {
    try {
      final doc = await _firestore.collection('system_config').doc('main').get();
      return doc.data() ?? {};
    } catch (e) {
      print('Erreur récupération config: $e');
      return {};
    }
  }

  /// Mettre à jour la configuration système
  Future<bool> updateSystemConfig(Map<String, dynamic> config) async {
    try {
      await _firestore.collection('system_config').doc('main').set({
        ...config,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _auth.currentUser?.uid,
      }, SetOptions(merge: true));

      await _logAdminActivity(
        'system_config_updated',
        config,
      );

      return true;
    } catch (e) {
      print('Erreur mise à jour config: $e');
      return false;
    }
  }
}