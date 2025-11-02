import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../config/app_config.dart';
import '../models/transaction_model.dart';

final meRechargeApiServiceProvider = Provider((ref) => MeRechargeApiService());

class MeRechargeApiService {
  final Dio _dio = Dio();
  final Logger _logger = Logger();

  MeRechargeApiService() {
    _configureDio();
  }

  void _configureDio() {
    _dio.options.baseUrl = AppConfig.meRechargeApiUrl;
    _dio.options.connectTimeout = AppConfig.apiTimeout;
    _dio.options.receiveTimeout = AppConfig.apiTimeout;

    // Intercepteur pour les logs
    _dio.interceptors.add(
      LogInterceptor(
        requestHeader: true,
        requestBody: true,
        responseHeader: true,
        responseBody: true,
        error: true,
        logPrint: (message) => _logger.d('[API] $message'),
      ),
    );

    // Intercepteur pour l'authentification
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // ✅ Ajouter le token Bearer pour l'authentification CallBox
          options.headers['Authorization'] = 'Bearer ${AppConfig.callboxToken}';
          options.headers['Content-Type'] = 'application/json';
          options.headers['User-Agent'] = 'MeRecharge-CallBox/${AppConfig.appVersion}';
          handler.next(options);
        },
        onError: (error, handler) {
          _logger.e('Erreur API: ${error.response?.statusCode} - ${error.message}');
          handler.next(error);
        },
      ),
    );
  }

  // Récupérer les transactions en attente depuis MeRecharge
  Future<List<TransactionModel>> fetchPendingTransactions() async {
    try {
      _logger.i('Récupération des transactions en attente...');
      
      // ✅ Endpoint correct avec paramètres callboxId et limit
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
      
      // En cas d'erreur réseau, retourner une liste vide pour ne pas bloquer l'app
      if (e is DioException && e.type == DioExceptionType.connectionTimeout) {
        _logger.w('Timeout de connexion - Mode hors ligne');
        return [];
      }
      
      throw Exception('Impossible de récupérer les transactions: $e');
    }
  }

  // Mettre à jour le statut d'une transaction sur MeRecharge
  Future<void> updateTransactionStatus(
    String meRechargeId,
    String status, {
    String? response,
    String? errorMessage,
  }) async {
    try {
      _logger.i('Mise à jour du statut de la transaction $meRechargeId: $status');
      
      // ✅ Format de payload adapté au backend MeRecharge
      final payload = {
        'status': status == 'success' ? 'completed' : status,
        'callboxId': AppConfig.callboxId,
        'result': {
          'success': status == 'success',
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
      
      // Ne pas relancer l'exception pour éviter de bloquer le traitement
      // Stocker pour retry ultérieur si nécessaire
      _logger.w('Mise à jour différée pour: $meRechargeId');
    }
  }

  // Envoyer des statistiques au backend MeRecharge
  Future<void> sendStats(Map<String, dynamic> stats) async {
    try {
      _logger.d('Envoi des statistiques CallBox...');
      
      final payload = {
        'callBoxId': 'CALLBOX_001', // Identifier unique de ce CallBox
        'timestamp': DateTime.now().toIso8601String(),
        'stats': stats,
        'version': AppConfig.appVersion,
      };

      await _dio.post('/call-box/stats', data: payload);
      _logger.d('Statistiques envoyées avec succès');
      
    } catch (e) {
      _logger.w('Impossible d\'envoyer les statistiques: $e');
    }
  }

  // Enregistrer ce CallBox auprès du backend MeRecharge
  Future<void> registerCallBox() async {
    try {
      _logger.i('Enregistrement du CallBox...');
      
      // ✅ Format de payload adapté au backend MeRecharge
      final payload = {
        'callboxId': AppConfig.callboxId,
        'version': AppConfig.appVersion,
        'capabilities': {
          'maxConcurrentTransactions': AppConfig.maxConcurrentTransactions,
          'supportedTypes': ['recharge', 'voucher', 'deposit', 'withdraw'],
        },
        'location': 'Development', // À personnaliser selon l'emplacement
      };

      // ✅ Endpoint correct
      final response = await _dio.post('/register', data: payload);
      
      if (response.statusCode == 200) {
        _logger.i('CallBox enregistré avec succès');
      }
      
    } catch (e) {
      _logger.w('Impossible d\'enregistrer le CallBox: $e');
    }
  }

  // Signaler que ce CallBox est en vie
  Future<void> sendHeartbeat() async {
    try {
      // ✅ Heartbeat avec métriques complètes
      final payload = {
        'callboxId': AppConfig.callboxId,
        'status': 'active',
        'queueSize': 0, // À mettre à jour dynamiquement
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

  // Récupérer la configuration depuis MeRecharge
  Future<Map<String, dynamic>?> fetchConfiguration() async {
    try {
      _logger.d('Récupération de la configuration...');
      
      final response = await _dio.get('/call-box/config');
      
      if (response.statusCode == 200) {
        final config = response.data as Map<String, dynamic>;
        _logger.d('Configuration récupérée');
        return config;
      }
      
      return null;
      
    } catch (e) {
      _logger.w('Impossible de récupérer la configuration: $e');
      return null;
    }
  }

  // Mapper une transaction MeRecharge vers notre modèle
  TransactionModel _mapMeRechargeToTransaction(Map<String, dynamic> json) {
    return TransactionModel(
      meRechargeId: json['id'].toString(),
      type: json['type'] ?? 'unknown',
      operator: json['operator'] ?? 'unknown',
      fromPhone: json['fromPhone'] ?? '',
      toPhone: json['toPhone'] ?? '',
      amount: (json['amount'] as num).toDouble(),
      fees: (json['fees'] as num?)?.toDouble() ?? 0.0,
      ussdCode: json['ussdCode'] ?? '',
      status: 'pending', // Toujours pending au départ
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      metadata: json['metadata'],
    );
  }

  // Tester la connexion avec le backend MeRecharge
  Future<bool> testConnection() async {
    try {
      _logger.d('Test de connexion au backend MeRecharge...');
      
      final response = await _dio.get('/health');
      
      if (response.statusCode == 200) {
        _logger.i('Connexion backend OK');
        return true;
      }
      
      return false;
      
    } catch (e) {
      _logger.w('Test de connexion échoué: $e');
      return false;
    }
  }

  // Obtenir les statistiques générales du backend
  Future<Map<String, dynamic>?> fetchBackendStats() async {
    try {
      final response = await _dio.get('/stats');
      
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      
      return null;
      
    } catch (e) {
      _logger.w('Impossible de récupérer les stats backend: $e');
      return null;
    }
  }

  // Récupérer les services disponibles
  Future<List<Map<String, dynamic>>> fetchAvailableServices() async {
    try {
      final response = await _dio.get('/services');
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return List<Map<String, dynamic>>.from(data['services'] ?? []);
      }
      
      return [];
      
    } catch (e) {
      _logger.w('Impossible de récupérer les services: $e');
      return [];
    }
  }

  // Nettoyage
  void dispose() {
    _dio.close();
  }
}