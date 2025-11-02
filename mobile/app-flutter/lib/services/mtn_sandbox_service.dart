import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class MtnSandboxService {
  MtnSandboxService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  // Use --dart-define=MTN_SUBSCRIPTION_KEY=your_key when running the app
  static const String _subscriptionKey = String.fromEnvironment('MTN_SUBSCRIPTION_KEY', defaultValue: '');

  static const String _baseUrl = 'https://sandbox.momodeveloper.mtn.com';

  void _ensureSubKey() {
    if (_subscriptionKey.isEmpty) {
      throw StateError(
        'MTN_SUBSCRIPTION_KEY is not set. Run the app with --dart-define=MTN_SUBSCRIPTION_KEY=YOUR_KEY',
      );
    }
  }

  /// Creates an API user and returns the X-Reference-Id used.
  Future<String> createApiUser({String? referenceId, String providerCallbackHost = 'https://example.com'}) async {
    _ensureSubKey();
    final refId = referenceId ?? const Uuid().v4();

    final uri = Uri.parse('$_baseUrl/v1_0/apiuser');
    final response = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Ocp-Apim-Subscription-Key': _subscriptionKey,
        'X-Reference-Id': refId,
      },
      body: jsonEncode({
        'providerCallbackHost': providerCallbackHost,
      }),
    );

    if (response.statusCode == 201) {
      return refId;
    }

    throw HttpExceptionWithBody(
      'Failed to create API user',
      statusCode: response.statusCode,
      body: response.body,
    );
  }

  /// Creates an API key for an API user (returns the apiKey string).
  Future<String> createApiKey(String referenceId) async {
    _ensureSubKey();

    final uri = Uri.parse('$_baseUrl/v1_0/apiuser/$referenceId/apikey');
    final response = await _client.post(
      uri,
      headers: {
        'Accept': 'application/json',
        'Ocp-Apim-Subscription-Key': _subscriptionKey,
      },
    );

    if (response.statusCode == 201) {
      final map = jsonDecode(response.body) as Map<String, dynamic>;
      final apiKey = map['apiKey'] as String?;
      if (apiKey == null || apiKey.isEmpty) {
        throw StateError('API returned 201 but no apiKey field found');
      }
      return apiKey;
    }

    throw HttpExceptionWithBody(
      'Failed to create API key',
      statusCode: response.statusCode,
      body: response.body,
    );
  }

  /// Get API user info (providerCallbackHost, paymentServerUrl, targetEnvironment in result model).
  Future<Map<String, dynamic>> getApiUser(String referenceId) async {
    _ensureSubKey();

    final uri = Uri.parse('$_baseUrl/v1_0/apiuser/$referenceId');
    final response = await _client.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Ocp-Apim-Subscription-Key': _subscriptionKey,
      },
    );

    if (response.statusCode == 200) {
      if (response.body.isEmpty) return <String, dynamic>{};
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw HttpExceptionWithBody(
      'Failed to get API user',
      statusCode: response.statusCode,
      body: response.body,
    );
  }
}

class HttpExceptionWithBody implements Exception {
  final String message;
  final int statusCode;
  final String body;

  HttpExceptionWithBody(this.message, {required this.statusCode, required this.body});

  @override
  String toString() => 'HttpExceptionWithBody(status: $statusCode, message: $message, body: $body)';
}
