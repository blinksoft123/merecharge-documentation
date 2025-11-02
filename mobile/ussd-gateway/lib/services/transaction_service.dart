import 'dart:async';
import 'dart:collection';
import 'package:logger/logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/transaction_model.dart';
import '../config/app_config.dart';
import 'ussd_service.dart';
import 'storage_service.dart';
import 'merecharge_api_service.dart';

final transactionServiceProvider = Provider((ref) => TransactionService(ref));

class TransactionService {
  final Ref _ref;
  final Logger _logger = Logger();
  final Queue<TransactionModel> _queue = Queue<TransactionModel>();
  final List<TransactionModel> _processing = [];
  final List<TransactionModel> _completed = [];
  final List<TransactionModel> _failed = [];
  
  bool _isProcessing = false;
  Timer? _processingTimer;
  
  StreamController<TransactionModel> _transactionController = 
      StreamController<TransactionModel>.broadcast();
  StreamController<Map<String, int>> _statsController =
      StreamController<Map<String, int>>.broadcast();

  TransactionService(this._ref) {
    _loadTransactions();
    _startProcessing();
  }

  // Streams pour l'UI
  Stream<TransactionModel> get transactionStream => _transactionController.stream;
  Stream<Map<String, int>> get statsStream => _statsController.stream;

  // Getters pour les états
  List<TransactionModel> get pendingTransactions => List.from(_queue);
  List<TransactionModel> get processingTransactions => List.from(_processing);
  List<TransactionModel> get completedTransactions => List.from(_completed);
  List<TransactionModel> get failedTransactions => List.from(_failed);
  List<TransactionModel> get allTransactions => [
    ..._queue,
    ..._processing,
    ..._completed,
    ..._failed,
  ];

  Map<String, int> get stats => {
    'pending': _queue.length,
    'processing': _processing.length,
    'completed': _completed.length,
    'failed': _failed.length,
    'total': allTransactions.length,
  };

  // Ajouter une transaction à la file
  Future<void> addTransaction(TransactionModel transaction) async {
    _queue.add(transaction);
    await _saveTransactions();
    _transactionController.add(transaction);
    _updateStats();
    
    _logger.i('Transaction ajoutée à la file: ${transaction.id}');
  }

  // Ajouter plusieurs transactions (batch)
  Future<void> addTransactionBatch(List<TransactionModel> transactions) async {
    for (final transaction in transactions) {
      _queue.add(transaction);
      _transactionController.add(transaction);
    }
    await _saveTransactions();
    _updateStats();
    
    _logger.i('Lot de ${transactions.length} transactions ajouté');
  }

  // Démarrer le traitement automatique
  void _startProcessing() {
    _processingTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _processQueue(),
    );
  }

  // Traiter la file d'attente
  Future<void> _processQueue() async {
    if (_isProcessing || _queue.isEmpty) return;
    if (_processing.length >= AppConfig.maxConcurrentTransactions) return;

    _isProcessing = true;

    try {
      final transaction = _queue.removeFirst();
      _processing.add(transaction);
      
      // Mettre à jour le statut
      final updatedTransaction = transaction.copyWith(
        status: 'processing',
        processedAt: DateTime.now(),
      );
      _updateTransaction(updatedTransaction);

      // Traiter la transaction
      _processTransaction(updatedTransaction);
      
    } catch (e) {
      _logger.e('Erreur lors du traitement de la file: $e');
    } finally {
      _isProcessing = false;
    }
  }

  // Traiter une transaction individuelle
  Future<void> _processTransaction(TransactionModel transaction) async {
    try {
      _logger.i('Traitement de la transaction: ${transaction.id}');

      // Exécuter le code USSD
      final ussdService = _ref.read(ussdServiceProvider);
      final result = await ussdService.executeUssd(transaction.ussdCode);

      TransactionModel updatedTransaction;
      
      if (result.isSuccess) {
        // Transaction réussie
        updatedTransaction = transaction.copyWith(
          status: 'success',
          ussdResponse: result.response,
          completedAt: DateTime.now(),
        );
        
        _processing.remove(transaction);
        _completed.add(updatedTransaction);
        
        // Notifier le backend MeRecharge
        await _notifyMeRecharge(updatedTransaction);
        
      } else {
        // Transaction échouée
        updatedTransaction = transaction.copyWith(
          status: 'failed',
          errorMessage: result.errorMessage,
          retryCount: transaction.retryCount + 1,
          completedAt: DateTime.now(),
        );

        _processing.remove(transaction);

        // Réessayer si possible
        if (updatedTransaction.canRetry) {
          _logger.w('Nouvelle tentative pour: ${transaction.id} (${updatedTransaction.retryCount}/3)');
          
          // Remettre en file avec délai
          Timer(const Duration(seconds: 10), () {
            final retryTransaction = updatedTransaction.copyWith(
              status: 'pending',
              processedAt: null,
              completedAt: null,
            );
            _queue.add(retryTransaction);
            _updateStats();
          });
        } else {
          _failed.add(updatedTransaction);
          await _notifyMeRecharge(updatedTransaction);
        }
      }

      _updateTransaction(updatedTransaction);
      await _saveTransactions();
      _updateStats();

    } catch (e) {
      _logger.e('Erreur lors du traitement de la transaction ${transaction.id}: $e');
      
      final failedTransaction = transaction.copyWith(
        status: 'failed',
        errorMessage: 'Erreur interne: $e',
        completedAt: DateTime.now(),
      );
      
      _processing.remove(transaction);
      _failed.add(failedTransaction);
      _updateTransaction(failedTransaction);
      await _saveTransactions();
      _updateStats();
    }
  }

  // Notifier le backend MeRecharge du résultat
  Future<void> _notifyMeRecharge(TransactionModel transaction) async {
    try {
      final apiService = _ref.read(meRechargeApiServiceProvider);
      await apiService.updateTransactionStatus(
        transaction.meRechargeId,
        transaction.status,
        response: transaction.ussdResponse,
        errorMessage: transaction.errorMessage,
      );
      
      _logger.i('Backend MeRecharge notifié pour: ${transaction.id}');
    } catch (e) {
      _logger.e('Erreur lors de la notification MeRecharge: $e');
    }
  }

  // Réessayer une transaction manuellement
  Future<void> retryTransaction(String transactionId) async {
    final transaction = _failed.firstWhere(
      (t) => t.id == transactionId,
      orElse: () => throw Exception('Transaction non trouvée'),
    );

    if (!transaction.canRetry) {
      throw Exception('Transaction ne peut pas être réessayée');
    }

    _failed.remove(transaction);
    final retryTransaction = transaction.copyWith(
      status: 'pending',
      processedAt: null,
      completedAt: null,
      errorMessage: null,
      ussdResponse: null,
    );

    await addTransaction(retryTransaction);
    _logger.i('Transaction remise en file: ${transactionId}');
  }

  // Annuler une transaction
  Future<void> cancelTransaction(String transactionId) async {
    // Retirer de la file d'attente
    _queue.removeWhere((t) => t.id == transactionId);
    
    // Marquer comme annulée si en traitement
    final processingIndex = _processing.indexWhere((t) => t.id == transactionId);
    if (processingIndex >= 0) {
      final transaction = _processing[processingIndex];
      final cancelledTransaction = transaction.copyWith(
        status: 'cancelled',
        completedAt: DateTime.now(),
      );
      
      _processing.removeAt(processingIndex);
      _failed.add(cancelledTransaction);
      _updateTransaction(cancelledTransaction);
    }

    await _saveTransactions();
    _updateStats();
    _logger.i('Transaction annulée: $transactionId');
  }

  // Vider la file d'attente
  Future<void> clearQueue() async {
    _queue.clear();
    await _saveTransactions();
    _updateStats();
    _logger.i('File d\'attente vidée');
  }

  // Vider les transactions terminées
  Future<void> clearCompleted() async {
    _completed.clear();
    _failed.clear();
    await _saveTransactions();
    _updateStats();
    _logger.i('Historique des transactions effacé');
  }

  // Mettre à jour une transaction dans les streams
  void _updateTransaction(TransactionModel transaction) {
    _transactionController.add(transaction);
  }

  // Mettre à jour les statistiques
  void _updateStats() {
    _statsController.add(stats);
  }

  // Sauvegarder les transactions
  Future<void> _saveTransactions() async {
    try {
      final storageService = _ref.read(storageServiceProvider);
      await storageService.saveTransactions(allTransactions);
    } catch (e) {
      _logger.e('Erreur lors de la sauvegarde: $e');
    }
  }

  // Charger les transactions sauvegardées
  Future<void> _loadTransactions() async {
    try {
      final storageService = _ref.read(storageServiceProvider);
      final transactions = await storageService.loadTransactions();
      
      for (final transaction in transactions) {
        switch (transaction.status) {
          case 'pending':
            _queue.add(transaction);
            break;
          case 'processing':
            // Remettre en pending les transactions en cours
            _queue.add(transaction.copyWith(
              status: 'pending',
              processedAt: null,
            ));
            break;
          case 'success':
            _completed.add(transaction);
            break;
          case 'failed':
          case 'cancelled':
          case 'timeout':
            _failed.add(transaction);
            break;
        }
      }
      
      _updateStats();
      _logger.i('${transactions.length} transactions chargées');
      
    } catch (e) {
      _logger.e('Erreur lors du chargement: $e');
    }
  }

  // Nettoyage
  void dispose() {
    _processingTimer?.cancel();
    _transactionController.close();
    _statsController.close();
  }
}