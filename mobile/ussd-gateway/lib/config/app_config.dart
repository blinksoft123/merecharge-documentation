class AppConfig {
  // Configuration du serveur
  static const String serverHost = '0.0.0.0';
  static const int serverPort = 8080;
  
  // Configuration MeRecharge Backend
  // ⚠️ Pour développement: utiliser l'IP locale de votre Mac
  static const String meRechargeApiUrl = 'http://192.168.1.26:3000/api/call-box';
  static const String meRechargeAdminUrl = 'http://192.168.1.26:3000';
  
  // Pour production: utiliser le domaine
  // static const String meRechargeApiUrl = 'https://api.merecharge.com/api/call-box';
  // static const String meRechargeAdminUrl = 'https://api.merecharge.com';
  
  // Authentification CallBox
  static const String callboxToken = 'callbox-secure-token-2024';
  static const String callboxId = 'CALLBOX_001';
  
  // Configuration des opérateurs
  static const Map<String, Map<String, String>> operators = {
    'orange': {
      'name': 'Orange Cameroun',
      'ussdBase': '#130*',
      'color': 'FF6600',
      'icon': 'assets/icons/orange.svg',
    },
    'mtn': {
      'name': 'MTN Cameroun', 
      'ussdBase': '*126*',
      'color': 'FFDD00',
      'icon': 'assets/icons/mtn.svg',
    },
    'camtel': {
      'name': 'Camtel',
      'ussdBase': '*126*',
      'color': '0099CC',
      'icon': 'assets/icons/camtel.svg',
    },
  };
  
  // Configuration des types de transaction
  static const Map<String, String> transactionTypes = {
    'topup': 'Recharge',
    'transfer': 'Transfert',
    'bill_payment': 'Paiement facture',
    'data_bundle': 'Forfait internet',
    'subscription': 'Abonnement',
  };
  
  // Configuration des statuts
  static const Map<String, String> transactionStatuses = {
    'pending': 'En attente',
    'processing': 'En cours',
    'success': 'Succès',
    'failed': 'Échec',
    'cancelled': 'Annulé',
    'timeout': 'Timeout',
  };
  
  // Configuration de l'interface
  static const String appName = 'MeRecharge Call Box';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Automatisation des transactions USSD';
  
  // Limites et timeouts
  static const int maxRetryAttempts = 3;
  static const Duration ussdTimeout = Duration(seconds: 30);
  static const Duration apiTimeout = Duration(seconds: 15);
  static const int maxConcurrentTransactions = 5;
  static const int batchSize = 10;
  
  // Configuration des logs
  static const String logLevel = 'DEBUG';
  static const bool enableFileLogging = true;
  static const int maxLogFileSize = 10 * 1024 * 1024; // 10MB
}