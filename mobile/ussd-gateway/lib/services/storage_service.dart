import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../models/transaction_model.dart';

final storageServiceProvider = Provider((ref) => StorageService());

class StorageService {
  final Logger _logger = Logger();
  static const String _transactionsKey = 'call_box_transactions';
  static const String _settingsKey = 'call_box_settings';
  static const String _transactionsFileName = 'transactions.json';

  // Sauvegarder les transactions
  Future<void> saveTransactions(List<TransactionModel> transactions) async {
    try {
      final transactionsJson = transactions.map((t) => t.toJson()).toList();
      
      // Sauvegarder dans SharedPreferences pour un accès rapide
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_transactionsKey, jsonEncode(transactionsJson));
      
      // Sauvegarder aussi dans un fichier pour persistance
      await _saveToFile(transactionsJson);
      
      _logger.d('${transactions.length} transactions sauvegardées');
    } catch (e) {
      _logger.e('Erreur lors de la sauvegarde des transactions: $e');
      throw Exception('Impossible de sauvegarder les transactions: $e');
    }
  }

  // Charger les transactions
  Future<List<TransactionModel>> loadTransactions() async {
    try {
      // Essayer de charger depuis SharedPreferences d'abord
      final prefs = await SharedPreferences.getInstance();
      final transactionsString = prefs.getString(_transactionsKey);
      
      if (transactionsString != null) {
        final transactionsJson = jsonDecode(transactionsString) as List;
        final transactions = transactionsJson
            .map((json) => TransactionModel.fromJson(json))
            .toList();
        
        _logger.d('${transactions.length} transactions chargées depuis les préférences');
        return transactions;
      }
      
      // Sinon, charger depuis le fichier
      return await _loadFromFile();
      
    } catch (e) {
      _logger.e('Erreur lors du chargement des transactions: $e');
      
      // En cas d'erreur, essayer de charger depuis le fichier de sauvegarde
      try {
        return await _loadFromFile();
      } catch (fileError) {
        _logger.w('Impossible de charger depuis le fichier: $fileError');
        return [];
      }
    }
  }

  // Sauvegarder dans un fichier
  Future<void> _saveToFile(List<Map<String, dynamic>> transactionsJson) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_transactionsFileName');
      
      final jsonString = const JsonEncoder.withIndent('  ').convert({
        'savedAt': DateTime.now().toIso8601String(),
        'version': '1.0',
        'transactions': transactionsJson,
      });
      
      await file.writeAsString(jsonString);
      _logger.d('Transactions sauvegardées dans le fichier: ${file.path}');
      
    } catch (e) {
      _logger.e('Erreur lors de la sauvegarde fichier: $e');
    }
  }

  // Charger depuis un fichier
  Future<List<TransactionModel>> _loadFromFile() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_transactionsFileName');
      
      if (!await file.exists()) {
        _logger.d('Fichier de transactions inexistant');
        return [];
      }
      
      final jsonString = await file.readAsString();
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final transactionsJson = data['transactions'] as List;
      
      final transactions = transactionsJson
          .map((json) => TransactionModel.fromJson(json))
          .toList();
      
      _logger.d('${transactions.length} transactions chargées depuis le fichier');
      return transactions;
      
    } catch (e) {
      _logger.e('Erreur lors du chargement fichier: $e');
      return [];
    }
  }

  // Sauvegarder les paramètres de l'application
  Future<void> saveSettings(Map<String, dynamic> settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_settingsKey, jsonEncode(settings));
      _logger.d('Paramètres sauvegardés');
    } catch (e) {
      _logger.e('Erreur lors de la sauvegarde des paramètres: $e');
    }
  }

  // Charger les paramètres de l'application
  Future<Map<String, dynamic>> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsString = prefs.getString(_settingsKey);
      
      if (settingsString != null) {
        final settings = jsonDecode(settingsString) as Map<String, dynamic>;
        _logger.d('Paramètres chargés');
        return settings;
      }
      
      return _getDefaultSettings();
      
    } catch (e) {
      _logger.e('Erreur lors du chargement des paramètres: $e');
      return _getDefaultSettings();
    }
  }

  // Paramètres par défaut
  Map<String, dynamic> _getDefaultSettings() {
    return {
      'autoProcessing': true,
      'processingInterval': 2, // secondes
      'maxRetries': 3,
      'maxConcurrentTransactions': 5,
      'notificationsEnabled': true,
      'soundEnabled': true,
      'darkMode': false,
      'language': 'fr',
      'meRechargeApiUrl': 'http://localhost:4000/api',
      'serverPort': 8080,
      'logLevel': 'INFO',
    };
  }

  // Exporter les transactions vers un fichier
  Future<String> exportTransactions(List<TransactionModel> transactions) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final fileName = 'transactions_export_$timestamp.json';
      final file = File('${directory.path}/$fileName');
      
      final exportData = {
        'exportedAt': DateTime.now().toIso8601String(),
        'version': '1.0',
        'appName': 'MeRecharge Call Box',
        'totalTransactions': transactions.length,
        'summary': {
          'pending': transactions.where((t) => t.isPending).length,
          'processing': transactions.where((t) => t.isProcessing).length,
          'success': transactions.where((t) => t.isSuccess).length,
          'failed': transactions.where((t) => t.isFailed).length,
        },
        'transactions': transactions.map((t) => t.toJson()).toList(),
      };
      
      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
      await file.writeAsString(jsonString);
      
      _logger.i('Transactions exportées: ${file.path}');
      return file.path;
      
    } catch (e) {
      _logger.e('Erreur lors de l\'export: $e');
      throw Exception('Impossible d\'exporter les transactions: $e');
    }
  }

  // Importer les transactions depuis un fichier
  Future<List<TransactionModel>> importTransactions(String filePath) async {
    try {
      final file = File(filePath);
      
      if (!await file.exists()) {
        throw Exception('Fichier d\'import inexistant');
      }
      
      final jsonString = await file.readAsString();
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      
      // Vérifier la version et la structure
      if (data['version'] != '1.0') {
        throw Exception('Version de fichier non supportée');
      }
      
      final transactionsJson = data['transactions'] as List;
      final transactions = transactionsJson
          .map((json) => TransactionModel.fromJson(json))
          .toList();
      
      _logger.i('${transactions.length} transactions importées depuis: $filePath');
      return transactions;
      
    } catch (e) {
      _logger.e('Erreur lors de l\'import: $e');
      throw Exception('Impossible d\'importer les transactions: $e');
    }
  }

  // Effacer toutes les données stockées
  Future<void> clearAllData() async {
    try {
      // Effacer SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_transactionsKey);
      await prefs.remove(_settingsKey);
      
      // Effacer le fichier de transactions
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_transactionsFileName');
      
      if (await file.exists()) {
        await file.delete();
      }
      
      _logger.i('Toutes les données stockées ont été effacées');
      
    } catch (e) {
      _logger.e('Erreur lors de l\'effacement des données: $e');
    }
  }

  // Obtenir les statistiques de stockage
  Future<Map<String, dynamic>> getStorageStats() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_transactionsFileName');
      
      final stats = <String, dynamic>{
        'fileExists': await file.exists(),
        'filePath': file.path,
        'fileSize': 0,
        'lastModified': null,
      };
      
      if (await file.exists()) {
        final fileStat = await file.stat();
        stats['fileSize'] = fileStat.size;
        stats['lastModified'] = fileStat.modified.toIso8601String();
      }
      
      // Taille des SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final transactionsString = prefs.getString(_transactionsKey);
      stats['preferencesSize'] = transactionsString?.length ?? 0;
      
      return stats;
      
    } catch (e) {
      _logger.e('Erreur lors de l\'obtention des stats de stockage: $e');
      return {};
    }
  }
}