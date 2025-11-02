import 'package:flutter/material.dart';
import '../routes/app_routes.dart';
import '../constants/app_colors.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: Image.asset(
                  'assets/logo.png',
                  height: 120,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Recharge, Convert, Connect',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.modernLogin),
                child: const Text('Se Connecter'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.phoneSignUp),
                child: const Text('Créer un compte'),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
