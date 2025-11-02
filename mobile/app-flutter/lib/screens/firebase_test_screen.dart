import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class FirebaseTestScreen extends StatefulWidget {
  const FirebaseTestScreen({super.key});

  @override
  State<FirebaseTestScreen> createState() => _FirebaseTestScreenState();
}

class _FirebaseTestScreenState extends State<FirebaseTestScreen> {
  final AuthService _authService = AuthService();
  final _emailController = TextEditingController(text: 'test@merecharge.com');
  final _passwordController = TextEditingController(text: 'test123456');
  final _nameController = TextEditingController(text: 'Test User');
  final _phoneController = TextEditingController(text: '+237600000000');
  
  String _statusMessage = 'En attente de test...';
  Color _statusColor = Colors.grey;
  bool _isLoading = false;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _checkFirebaseStatus();
    _listenToAuthChanges();
  }

  void _listenToAuthChanges() {
    _authService.authStateChanges.listen((User? user) {
      setState(() {
        _currentUser = user;
      });
    });
  }

  Future<void> _checkFirebaseStatus() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Vérification de Firebase...';
      _statusColor = Colors.orange;
    });

    try {
      // Vérifier Firebase Core
      final app = Firebase.app();
      print('✓ Firebase App initialisé: ${app.name}');

      // Vérifier Firebase Auth
      final auth = FirebaseAuth.instance;
      print('✓ Firebase Auth disponible');
      print('  Current User: ${auth.currentUser?.email ?? "Aucun"}');

      // Vérifier Firestore
      final firestore = FirebaseFirestore.instance;
      print('✓ Firestore disponible');

      // Test de connexion Firestore
      await firestore.collection('test').doc('connection').set({
        'timestamp': FieldValue.serverTimestamp(),
        'message': 'Test de connexion réussi',
      });
      print('✓ Écriture Firestore réussie');

      // Lire depuis Firestore
      final doc = await firestore.collection('test').doc('connection').get();
      print('✓ Lecture Firestore réussie: ${doc.data()}');

      setState(() {
        _statusMessage = '✓ Firebase connecté et fonctionnel!';
        _statusColor = Colors.green;
        _isLoading = false;
      });
    } catch (e) {
      print('✗ Erreur Firebase: $e');
      setState(() {
        _statusMessage = '✗ Erreur: $e';
        _statusColor = Colors.red;
        _isLoading = false;
      });
    }
  }

  Future<void> _testSignUp() async {
    setState(() => _isLoading = true);
    
    final result = await _authService.signUp(
      email: _emailController.text,
      password: _passwordController.text,
      name: _nameController.text,
      phoneNumber: _phoneController.text,
    );

    setState(() {
      _isLoading = false;
      if (result['success']) {
        _statusMessage = '✓ ${result['message']}';
        _statusColor = Colors.green;
      } else {
        _statusMessage = '✗ ${result['error']}';
        _statusColor = Colors.red;
      }
    });

    _showResultDialog(result);
  }

  Future<void> _testSignIn() async {
    setState(() => _isLoading = true);
    
    final result = await _authService.signIn(
      email: _emailController.text,
      password: _passwordController.text,
    );

    setState(() {
      _isLoading = false;
      if (result['success']) {
        _statusMessage = '✓ ${result['message']}';
        _statusColor = Colors.green;
      } else {
        _statusMessage = '✗ ${result['error']}';
        _statusColor = Colors.red;
      }
    });

    _showResultDialog(result);
  }

  Future<void> _testSignOut() async {
    setState(() => _isLoading = true);
    
    try {
      await _authService.signOut();
      setState(() {
        _statusMessage = '✓ Déconnexion réussie';
        _statusColor = Colors.green;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = '✗ Erreur: $e';
        _statusColor = Colors.red;
        _isLoading = false;
      });
    }
  }

  void _showResultDialog(Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(result['success'] ? 'Succès' : 'Erreur'),
        content: Text(result['success'] ? result['message'] : result['error']),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Firebase'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              color: _statusColor.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(_statusColor == Colors.green 
                        ? Icons.check_circle 
                        : _statusColor == Colors.red 
                            ? Icons.error 
                            : Icons.info,
                      color: _statusColor,
                      size: 48,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _statusMessage,
                      style: TextStyle(
                        color: _statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Current User Info
            if (_currentUser != null)
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Utilisateur connecté',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Email: ${_currentUser!.email}'),
                      Text('UID: ${_currentUser!.uid}'),
                      Text('Vérifié: ${_currentUser!.emailVerified ? "Oui" : "Non"}'),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Test Form
            const Text(
              'Formulaire de Test',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nom',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Téléphone',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Mot de passe',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
            ),

            const SizedBox(height: 24),

            // Test Buttons
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: _checkFirebaseStatus,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Vérifier Firebase'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),

                  ElevatedButton.icon(
                    onPressed: _testSignUp,
                    icon: const Icon(Icons.person_add),
                    label: const Text('Test Inscription'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),

                  ElevatedButton.icon(
                    onPressed: _testSignIn,
                    icon: const Icon(Icons.login),
                    label: const Text('Test Connexion'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (_currentUser != null)
                    ElevatedButton.icon(
                      onPressed: _testSignOut,
                      icon: const Icon(Icons.logout),
                      label: const Text('Test Déconnexion'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                ],
              ),

            const SizedBox(height: 24),

            // Info Card
            Card(
              color: Colors.amber.shade50,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📝 Instructions',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('1. Cliquez sur "Vérifier Firebase" pour tester la connexion'),
                    Text('2. Testez "Inscription" pour créer un compte'),
                    Text('3. Testez "Connexion" pour vous connecter'),
                    Text('4. Testez "Déconnexion" pour vous déconnecter'),
                    SizedBox(height: 8),
                    Text(
                      '⚠️ Les résultats s\'afficheront en haut',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
