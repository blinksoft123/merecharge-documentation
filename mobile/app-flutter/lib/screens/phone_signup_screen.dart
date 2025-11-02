import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../routes/app_routes.dart';

class PhoneSignUpScreen extends StatefulWidget {
  const PhoneSignUpScreen({super.key});

  @override
  State<PhoneSignUpScreen> createState() => _PhoneSignUpScreenState();
}

class _PhoneSignUpScreenState extends State<PhoneSignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _authService = AuthService();
  
  bool _isLoading = false;
  bool _accepted = false;
  String _selectedCountryCode = '+237'; // Cameroun par défaut

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // Formatter pour le numéro de téléphone
  String _formatPhoneNumber(String phone) {
    // Enlever les espaces et caractères spéciaux
    phone = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    // Ajouter le code pays si nécessaire
    if (!phone.startsWith(_selectedCountryCode.substring(1))) {
      phone = _selectedCountryCode.substring(1) + phone;
    }
    
    return '+$phone';
  }

  Future<void> _sendVerificationCode() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_accepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez accepter les conditions générales'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final phoneNumber = _formatPhoneNumber(_phoneController.text);

    try {
      await _authService.signInWithPhoneNumber(
        phoneNumber: phoneNumber,
        codeSent: (verificationId, resendToken) {
          setState(() => _isLoading = false);
          
          // Naviguer vers l'écran OTP avec les paramètres nécessaires
          Navigator.pushNamed(
            context,
            AppRoutes.otp,
            arguments: {
              'verificationId': verificationId,
              'phoneNumber': phoneNumber,
              'name': _nameController.text.trim(),
              'resendToken': resendToken,
            },
          );

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Code de vérification envoyé !'),
              backgroundColor: Colors.green,
            ),
          );
        },
        verificationFailed: (error) {
          setState(() => _isLoading = false);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: Colors.red,
            ),
          );
        },
      );
    } catch (e) {
      setState(() => _isLoading = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inscription par téléphone'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.phone_android,
                  size: 60,
                  color: Colors.blue,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Créer un compte',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Entrez votre numéro de téléphone pour recevoir un code de vérification',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
              
                // Champ Nom
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Nom complet',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Veuillez entrer votre nom';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
              
                // Sélecteur de code pays et numéro de téléphone
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Code pays
                    SizedBox(
                      width: 100,
                      child: DropdownButtonFormField<String>(
                        value: _selectedCountryCode,
                        decoration: const InputDecoration(
                          labelText: 'Pays',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: '+237', child: Text('🇨🇲 +237')),
                          DropdownMenuItem(value: '+33', child: Text('🇫🇷 +33')),
                          DropdownMenuItem(value: '+1', child: Text('🇺🇸 +1')),
                          DropdownMenuItem(value: '+44', child: Text('🇬🇧 +44')),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedCountryCode = value ?? '+237');
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Numéro de téléphone
                    Expanded(
                      child: TextFormField(
                        controller: _phoneController,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: 'Numéro de téléphone',
                          prefixIcon: Icon(Icons.phone),
                          border: OutlineInputBorder(),
                          hintText: '6XXXXXXXX',
                        ),
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(9),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer votre numéro';
                          }
                          if (value.length < 9) {
                            return 'Numéro invalide';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              
                // Case à cocher CGU
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _accepted,
                  onChanged: (value) {
                    setState(() => _accepted = value ?? false);
                  },
                  title: Flexible(
                    child: Wrap(
                      children: [
                        const Text('J\'accepte les '),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, AppRoutes.privacyPolicy);
                          },
                          child: const Text(
                            'conditions générales',
                            style: TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                const SizedBox(height: 16),
              
                // Bouton d'envoi
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _sendVerificationCode,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Envoyer le code',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Lien vers connexion
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Vous avez déjà un compte ? '),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, AppRoutes.login);
                      },
                      child: const Text('Se connecter'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
