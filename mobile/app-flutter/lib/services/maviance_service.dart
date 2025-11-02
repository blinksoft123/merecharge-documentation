import 'dart:convert';
import 'package:http/http.dart' as http;

class MavianceService {
  static const String baseUrl = 'http://localhost:3000/api';
  static const String apiKey = 'votre_cle_api_secrete'; // Même clé que dans le backend

  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'x-api-key': apiKey,
  };

  // Test de ping
  static Future<Map<String, dynamic>> ping() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/ping'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.body}'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur réseau: $e'
      };
    }
  }

  // Recharge de crédit
  static Future<Map<String, dynamic>> rechargeCredit({
    required String phoneNumber,
    required double amount,
    required String payItemId,
    required Map<String, String> customerInfo,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/recharge'),
        headers: headers,
        body: jsonEncode({
          'phoneNumber': phoneNumber,
          'amount': amount,
          'payItemId': payItemId,
          'customerInfo': customerInfo,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur réseau: $e'
      };
    }
  }

  // Achat de forfait
  static Future<Map<String, dynamic>> purchaseVoucher({
    required String phoneNumber,
    required String payItemId,
    required Map<String, String> customerInfo,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/voucher'),
        headers: headers,
        body: jsonEncode({
          'phoneNumber': phoneNumber,
          'payItemId': payItemId,
          'customerInfo': customerInfo,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur réseau: $e'
      };
    }
  }

  // Dépôt d'argent
  static Future<Map<String, dynamic>> depositMoney({
    required double amount,
    required String payItemId,
    required Map<String, String> customerInfo,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/deposit'),
        headers: headers,
        body: jsonEncode({
          'amount': amount,
          'payItemId': payItemId,
          'customerInfo': customerInfo,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur réseau: $e'
      };
    }
  }

  // Retrait d'argent
  static Future<Map<String, dynamic>> withdrawMoney({
    required double amount,
    required String payItemId,
    required Map<String, String> customerInfo,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/withdraw'),
        headers: headers,
        body: jsonEncode({
          'amount': amount,
          'payItemId': payItemId,
          'customerInfo': customerInfo,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur réseau: $e'
      };
    }
  }

  // Vérifier une transaction
  static Future<Map<String, dynamic>> verifyTransaction(String transactionId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/verify/$transactionId'),
        headers: headers,
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur réseau: $e'
      };
    }
  }

  // Récupérer les services disponibles
  static Future<Map<String, dynamic>> getServices() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/services'),
        headers: headers,
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur réseau: $e'
      };
    }
  }

  // Récupérer les produits TOPUP pour un service
  static Future<Map<String, dynamic>> getTopupProducts(String serviceId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/topup/$serviceId'),
        headers: headers,
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur réseau: $e'
      };
    }
  }

  // Récupérer les forfaits pour un service
  static Future<Map<String, dynamic>> getVoucherProducts(String serviceId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/voucher/$serviceId'),
        headers: headers,
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur réseau: $e'
      };
    }
  }

  // Méthodes utilitaires pour générer les données client
  static Map<String, String> generateCustomerInfo({
    required String phone,
    required String email,
    required String name,
    String address = 'Yaoundé, Cameroun',
  }) {
    return {
      'phone': phone,
      'email': email,
      'name': name,
      'address': address,
    };
  }
}