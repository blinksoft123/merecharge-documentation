// Configuration des services et payItemIds pour l'API Maviance
// Ces données proviennent de la collection Postman fournie

class ServiceConfig {
  // IDs des services principaux
  static const Map<String, String> serviceIds = {
    'orange_topup': '20062',
    'mtn_cashout': '20053',
    'orange_cashin': '20052',
    'camtel_voucher': '2000',
    'star_times': '20021',
    'cnps_subscription': '10041',
    'eneo_bill': '202305',
  };

  // PayItemIds pour les recharges de crédit (TOPUP)
  static const Map<String, String> topupPayItemIds = {
    'orange': 'S-112-951-CMORANGE-20062-CM_ORANGE_VTU_CUSTOM-1',
    // MTN et Camtel à ajouter quand vous aurez les payItemIds spécifiques
  };

  // PayItemIds pour les retraits (CASHOUT)
  static const Map<String, String> cashoutPayItemIds = {
    'mtn': 'S-112-949-MTNMOMO-20053-200050001-1',
    // Orange et Camtel à ajouter
  };

  // PayItemIds pour les dépôts (CASHIN)
  static const Map<String, String> cashinPayItemIds = {
    'orange': 'S-112-948-CMORANGEOM-30052-2006125104-1',
    // MTN et autres à ajouter
  };

  // PayItemIds pour les forfaits (VOUCHER)
  static const Map<String, String> voucherPayItemIds = {
    'camtel': 'S-112-974-CMENEOPREPAID-2000-10010-1',
    // Orange et MTN forfaits à ajouter
  };

  // PayItemIds pour autres services
  static const Map<String, String> otherPayItemIds = {
    'star_times': 'S-112-952-CMStarTimes-20021-900210-1',
    'cnps': 'S-112-953-CMSABC-5000-2c5b2407e4cd41449d9ff5313041c917-23c1c182e0484121b971285896ecb1ef',
    'eneo': 'S-112-950-ENEO-10039-bdd6d917a39e4b53808559adb7e1876a-23a8e1b750da4dfe9b57fa877a840256',
  };

  // Méthodes utilitaires pour récupérer les payItemIds
  static String? getTopupPayItemId(String operator) {
    return topupPayItemIds[operator.toLowerCase()];
  }

  static String? getCashoutPayItemId(String operator) {
    return cashoutPayItemIds[operator.toLowerCase()];
  }

  static String? getCashinPayItemId(String operator) {
    return cashinPayItemIds[operator.toLowerCase()];
  }

  static String? getVoucherPayItemId(String operator) {
    return voucherPayItemIds[operator.toLowerCase()];
  }

  static String? getServiceId(String serviceName) {
    return serviceIds[serviceName.toLowerCase()];
  }

  // Liste des opérateurs supportés
  static const List<String> supportedOperators = [
    'Orange',
    'MTN',
    'Camtel',
  ];

  // Montants de recharge disponibles par opérateur
  static const Map<String, List<int>> rechargeAmounts = {
    'Orange': [500, 1000, 2000, 5000, 10000],
    'MTN': [500, 1000, 2000, 5000, 10000],
    'Camtel': [500, 1000, 2000, 5000, 10000],
  };
}