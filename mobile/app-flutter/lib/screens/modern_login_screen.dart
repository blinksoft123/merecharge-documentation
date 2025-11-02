import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../constants/app_colors.dart';
import '../routes/app_routes.dart';

class ModernLoginScreen extends StatefulWidget {
  const ModernLoginScreen({super.key});

  @override
  State<ModernLoginScreen> createState() => _ModernLoginScreenState();
}

class _ModernLoginScreenState extends State<ModernLoginScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    final result = await authService.signInWithGoogle();

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result['success']) {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } else {
      setState(() => _errorMessage = result['error']);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error']),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _signInWithPhone() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    String phoneNumber = _phoneController.text.trim();
    
    // Formater le numéro si nécessaire
    if (!phoneNumber.startsWith('+')) {
      // Ajouter +237 pour le Cameroun par défaut
      if (phoneNumber.startsWith('6') || phoneNumber.startsWith('2')) {
        phoneNumber = '+237$phoneNumber';
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Format de numéro invalide';
        });
        return;
      }
    }

    final authService = Provider.of<AuthService>(context, listen: false);

    await authService.signInWithPhoneNumber(
      phoneNumber: phoneNumber,
      codeSent: (String verificationId, int? resendToken) {
        setState(() => _isLoading = false);
        // Naviguer vers l'écran OTP
        Navigator.pushNamed(
          context,
          AppRoutes.otp,
          arguments: {
            'verificationId': verificationId,
            'phoneNumber': phoneNumber,
            'resendToken': resendToken,
          },
        );
      },
      verificationFailed: (String error) {
        setState(() {
          _isLoading = false;
          _errorMessage = error;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.red,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                
                // Logo
                Center(
                  child: Image.asset(
                    'assets/logo.png',
                    height: 100,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Titre
                const Text(
                  'Bienvenue',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 8),
                
                const Text(
                  'Connectez-vous pour continuer',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 40),
                
                // Bouton Google Sign-In
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _signInWithGoogle,
                  icon: Image.asset(
                    'assets/icons/google.png',
                    height: 24,
                    errorBuilder: (context, error, stackTrace) => 
                        const Icon(Icons.g_mobiledata, size: 24),
                  ),
                  label: const Text('Continuer avec Google'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 2,
                    side: const BorderSide(color: Colors.grey),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Divider
                Row(
                  children: const [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('OU', style: TextStyle(color: Colors.grey)),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Champ numéro de téléphone
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Numéro de téléphone',
                    hintText: '6XXXXXXXX ou +237XXXXXXXXX',
                    prefixIcon: const Icon(Icons.phone),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre numéro';
                    }
                    // Validation basique
                    final cleaned = value.replaceAll(RegExp(r'[\s\-]'), '');
                    if (cleaned.length < 9) {
                      return 'Numéro trop court';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Message d'erreur
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Bouton Continuer avec téléphone
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _signInWithPhone,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.arrow_forward),
                  label: Text(_isLoading ? 'Envoi...' : 'Continuer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.info_outline, color: Colors.blue, size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Nous vous enverrons un code de vérification par SMS',
                          style: TextStyle(fontSize: 12, color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
