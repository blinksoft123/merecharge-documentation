import 'package:flutter/material.dart';
import '../routes/app_routes.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool accepted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(decoration: const InputDecoration(labelText: 'Nom')), 
            const SizedBox(height: 12),
            TextFormField(decoration: const InputDecoration(labelText: 'Numéro de téléphone'), keyboardType: TextInputType.phone),
            const SizedBox(height: 12),
            TextFormField(decoration: const InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 12),
            TextFormField(decoration: const InputDecoration(labelText: 'Mot de passe'), obscureText: true),
            const SizedBox(height: 12),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: accepted,
              onChanged: (v) => setState(() => accepted = v ?? false),
              title: const Text('J\'accepte les CGU'),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: accepted
                    ? () => Navigator.pushNamed(context, AppRoutes.otp)
                    : null,
                child: const Text('Sign Up'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
