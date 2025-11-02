import 'package:flutter/material.dart';
import '../routes/app_routes.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log In')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(decoration: const InputDecoration(labelText: 'Numéro de téléphone'), keyboardType: TextInputType.phone),
            const SizedBox(height: 12),
            TextFormField(decoration: const InputDecoration(labelText: 'Mot de passe'), obscureText: true),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.home),
                child: const Text('Log In'),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.resetPassword),
              child: const Text('Forgot Password?'),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton(onPressed: () {}, child: const Text('Google')),
                OutlinedButton(onPressed: () {}, child: const Text('Facebook')),
              ],
            )
          ],
        ),
      ),
    );
  }
}
