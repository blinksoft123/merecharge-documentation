import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../routes/app_routes.dart';
import '../services/auth_service.dart';
import 'dart:async';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final TextEditingController _otpCtrl = TextEditingController();
  final _authService = AuthService();
  
  bool _isLoading = false;
  bool _isResending = false;
  String? _verificationId;
  String? _phoneNumber;
  String? _name;
  int? _resendToken;
  
  // Timer pour le compte à rebours
  Timer? _timer;
  int _countdown = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    // Récupérer les arguments après le premier frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        setState(() {
          _verificationId = args['verificationId'] as String?;
          _phoneNumber = args['phoneNumber'] as String?;
          _name = args['name'] as String?;
          _resendToken = args['resendToken'] as int?;
        });
        _startCountdown();
      }
    });
  }

  void _startCountdown() {
    setState(() {
      _countdown = 60;
      _canResend = false;
    });
    
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        setState(() => _canResend = true);
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _otpCtrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _verifyCode() async {
    if (_otpCtrl.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer un code à 6 chiffres'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_verificationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur: ID de vérification manquant'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _authService.verifyPhoneCode(
        verificationId: _verificationId!,
        smsCode: _otpCtrl.text,
        name: _name,
      );

      setState(() => _isLoading = false);

      if (!mounted) return;

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Vérification réussie !'),
            backgroundColor: Colors.green,
          ),
        );

        // Naviguer vers l'écran principal
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.home,
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Erreur de vérification'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _resendCode() async {
    if (!_canResend || _phoneNumber == null) return;

    setState(() => _isResending = true);

    try {
      await _authService.signInWithPhoneNumber(
        phoneNumber: _phoneNumber!,
        codeSent: (verificationId, resendToken) {
          setState(() {
            _verificationId = verificationId;
            _resendToken = resendToken;
            _isResending = false;
          });
          
          _startCountdown();
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Code renvoyé avec succès !'),
              backgroundColor: Colors.green,
            ),
          );
        },
        verificationFailed: (error) {
          setState(() => _isResending = false);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: Colors.red,
            ),
          );
        },
      );
    } catch (e) {
      setState(() => _isResending = false);
      
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
        title: const Text('Vérification OTP'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.sms,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 24),
            const Text(
              'Vérification',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Entrez le code à 6 chiffres envoyé par SMS au ${_phoneNumber ?? "numéro de téléphone"}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            // Champ OTP
            TextField(
              controller: _otpCtrl,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
              ),
              maxLength: 6,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                counterText: '',
                hintText: '000000',
              ),
            ),
            const SizedBox(height: 24),
            
            // Bouton de vérification
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verifyCode,
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
                        'Vérifier',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Bouton renvoyer le code
            TextButton(
              onPressed: _canResend && !_isResending ? _resendCode : null,
              child: _isResending
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      _canResend
                          ? 'Renvoyer le code'
                          : 'Renvoyer le code (${_countdown}s)',
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
