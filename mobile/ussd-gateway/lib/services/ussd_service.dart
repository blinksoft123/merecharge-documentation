import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

final ussdServiceProvider = Provider((ref) => UssdService());

class UssdResult {
  final bool isSuccess;
  final String? response;
  final String? errorMessage;
  final Duration executionTime;

  UssdResult({
    required this.isSuccess,
    this.response,
    this.errorMessage,
    required this.executionTime,
  });

  factory UssdResult.success(String response, Duration executionTime) {
    return UssdResult(
      isSuccess: true,
      response: response,
      executionTime: executionTime,
    );
  }

  factory UssdResult.failure(String errorMessage, Duration executionTime) {
    return UssdResult(
      isSuccess: false,
      errorMessage: errorMessage,
      executionTime: executionTime,
    );
  }
}

class UssdService {
  final Logger _logger = Logger();
  final Random _random = Random();

  // Méthode principale pour exécuter un code USSD
  Future<UssdResult> executeUssd(String ussdCode) async {
    final startTime = DateTime.now();
    
    try {
      _logger.i('Exécution USSD: $ussdCode');

      // Dans une implémentation réelle, ceci communiquerait avec le code natif
      // Pour l'instant, on simule avec des délais et réponses réalistes
      final result = await _simulateUssdExecution(ussdCode);
      
      final executionTime = DateTime.now().difference(startTime);
      _logger.i('USSD terminé en ${executionTime.inSeconds}s: ${result.isSuccess ? "Succès" : "Échec"}');
      
      return result.copyWith(executionTime: executionTime);
      
    } catch (e) {
      final executionTime = DateTime.now().difference(startTime);
      _logger.e('Erreur USSD: $e');
      
      return UssdResult.failure(
        'Erreur d\'exécution USSD: $e',
        executionTime,
      );
    }
  }

  // Simulation de l'exécution USSD avec réponses réalistes
  Future<UssdResult> _simulateUssdExecution(String ussdCode) async {
    // Délai réaliste entre 3-15 secondes
    final delay = Duration(
      seconds: 3 + _random.nextInt(12),
      milliseconds: _random.nextInt(1000),
    );
    
    await Future.delayed(delay);

    // Simulation de différents types de réponses selon l'opérateur
    if (ussdCode.startsWith('#130')) {
      return _simulateOrangeResponse(ussdCode);
    } else if (ussdCode.startsWith('*126')) {
      return _simulateMtnResponse(ussdCode);
    } else if (ussdCode.startsWith('*133')) {
      return _simulateCamtelResponse(ussdCode);
    } else {
      return _simulateGenericResponse(ussdCode);
    }
  }

  // Simulation des réponses Orange Money
  UssdResult _simulateOrangeResponse(String ussdCode) {
    // 85% de chance de succès
    if (_random.nextDouble() < 0.85) {
      final responses = [
        'Transfert Orange Money réussi. Nouveau solde: 45,250 FCFA. Frais: 150 FCFA. Ref: OM241007123456',
        'Recharge effectuée avec succès. Crédit: 15,000 FCFA. Bonus: 500 FCFA. Valable 30 jours.',
        'Paiement facture réussi. Montant: 8,500 FCFA. Frais: 100 FCFA. Réf: PAY987654321',
        'Forfait internet activé. 1GB valable 7 jours. Solde restant: 23,750 FCFA',
      ];
      return UssdResult.success(responses[_random.nextInt(responses.length)], Duration.zero);
    } else {
      final errors = [
        'Solde insuffisant pour effectuer cette transaction',
        'Numéro destinataire non valide ou non Orange Money',
        'Service temporairement indisponible. Réessayez plus tard',
        'Limite quotidienne dépassée',
        'Code PIN incorrect',
      ];
      return UssdResult.failure(errors[_random.nextInt(errors.length)], Duration.zero);
    }
  }

  // Simulation des réponses MTN Mobile Money
  UssdResult _simulateMtnResponse(String ussdCode) {
    // 80% de chance de succès
    if (_random.nextDouble() < 0.80) {
      final responses = [
        'Transaction MTN MoMo réussie. ID: MM24100712345. Solde: 67,890 FCFA',
        'Recharge crédit réussie. Nouveau crédit: 25,000 FCFA. Bonus data: 500MB',
        'Paiement effectué. Ref: MTNPAY456789. Frais: 200 FCFA',
        'Bundle data activé: 2GB/14 jours. Solde: 31,200 FCFA',
      ];
      return UssdResult.success(responses[_random.nextInt(responses.length)], Duration.zero);
    } else {
      final errors = [
        'Fonds insuffisants dans votre compte MTN MoMo',
        'Destinataire non MTN MoMo ou inactif',
        'Erreur système MTN. Code: E502',
        'Transaction annulée par l\'utilisateur',
        'Montant hors limites autorisées',
      ];
      return UssdResult.failure(errors[_random.nextInt(errors.length)], Duration.zero);
    }
  }

  // Simulation des réponses Camtel
  UssdResult _simulateCamtelResponse(String ussdCode) {
    // 75% de chance de succès
    if (_random.nextDouble() < 0.75) {
      final responses = [
        'Recharge Camtel effectuée. Crédit: 10,000 FCFA. Validité: 60 jours',
        'Paiement facture Camtel réussi. Ref: CAM789123456. Montant: 12,500 FCFA',
        'Bundle Internet Camtel activé: 3GB/30 jours. Ref: DATA789456',
      ];
      return UssdResult.success(responses[_random.nextInt(responses.length)], Duration.zero);
    } else {
      final errors = [
        'Numéro Camtel non valide',
        'Réseau Camtel indisponible',
        'Montant minimum requis: 500 FCFA',
        'Service en maintenance',
      ];
      return UssdResult.failure(errors[_random.nextInt(errors.length)], Duration.zero);
    }
  }

  // Simulation générique pour autres opérateurs
  UssdResult _simulateGenericResponse(String ussdCode) {
    if (_random.nextDouble() < 0.70) {
      return UssdResult.success(
        'Transaction réussie. Code de confirmation: GEN${_random.nextInt(999999)}',
        Duration.zero,
      );
    } else {
      return UssdResult.failure(
        'Erreur de transaction générique',
        Duration.zero,
      );
    }
  }

  // Méthode legacy pour compatibilité
  static Future<String> runUssd(String ussdCode) async {
    final service = UssdService();
    final result = await service.executeUssd(ussdCode);
    return result.response ?? result.errorMessage ?? 'Aucune réponse';
  }
}

extension UssdResultExtension on UssdResult {
  UssdResult copyWith({
    bool? isSuccess,
    String? response,
    String? errorMessage,
    Duration? executionTime,
  }) {
    return UssdResult(
      isSuccess: isSuccess ?? this.isSuccess,
      response: response ?? this.response,
      errorMessage: errorMessage ?? this.errorMessage,
      executionTime: executionTime ?? this.executionTime,
    );
  }
}
