import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart' as shelf;
import 'package:shelf_cors_headers/shelf_cors_headers.dart';

import 'config/app_config.dart';
import 'screens/dashboard_screen.dart';
import 'screens/transactions_screen.dart';
import 'screens/settings_screen.dart';
import 'services/ussd_service.dart';
import 'services/transaction_service.dart';
import 'services/merecharge_api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Démarrer le serveur API en arrière-plan
  _startServer();

  runApp(const ProviderScope(child: CallBoxApp()));
}

// Configuration du routeur pour la navigation
final _appRouter = GoRouter(
  initialLocation: '/dashboard',
  routes: [
    GoRoute(
      path: '/dashboard',
      name: 'dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/transactions',
      name: 'transactions', 
      builder: (context, state) => const TransactionsScreen(),
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);

// Configuration du routeur API
final _apiRouter = shelf.Router()
  // API pour recevoir les transactions depuis MeRecharge
  ..post('/api/transactions', (Request request) async {
    try {
      final payload = await request.readAsString();
      final data = jsonDecode(payload) as Map<String, dynamic>;

      // TODO: Valider et traiter la transaction
      // Pour l'instant, on simule une réponse
      
      return Response.ok(
        jsonEncode({
          'success': true,
          'message': 'Transaction reçue et mise en file',
          'transactionId': data['id'],
        }),
        headers: {'Content-Type': 'application/json'},
      );
      
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Erreur lors du traitement: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  })
  
  // API legacy pour compatibilité
  ..post('/ussd', (Request request) async {
    final payload = await request.readAsString();
    final data = jsonDecode(payload);

    final ussdCode = data['ussdCode'] as String?;
    if (ussdCode == null) {
      return Response.badRequest(
        body: jsonEncode({'error': 'Le champ \'ussdCode\' est requis.'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    // Exécuter le code USSD
    final result = await UssdService.runUssd(ussdCode);

    return Response.ok(
      jsonEncode({'result': result}),
      headers: {'Content-Type': 'application/json'},
    );
  })
  
  // API de santé / status
  ..get('/health', (Request request) {
    return Response.ok(
      jsonEncode({
        'status': 'healthy',
        'version': AppConfig.appVersion,
        'timestamp': DateTime.now().toIso8601String(),
      }),
      headers: {'Content-Type': 'application/json'},
    );
  });

// Démarrer le serveur Shelf avec CORS
void _startServer() async {
  final handler = const Pipeline()
    .addMiddleware(corsHeaders())
    .addHandler(_apiRouter);
    
  final server = await io.serve(
    handler, 
    AppConfig.serverHost, 
    AppConfig.serverPort,
  );
  
  print('🚀 Serveur CallBox démarré sur ${server.address.host}:${server.port}');
  print('📊 Dashboard disponible dans l\'application');
}

class CallBoxApp extends ConsumerWidget {
  const CallBoxApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      routerConfig: _appRouter,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 1,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }
}
