import 'package:flutter/material.dart';
import '../routes/app_routes.dart';

class NewPasswordScreen extends StatelessWidget {
  const NewPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Password')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(decoration: const InputDecoration(labelText: 'New Password'), obscureText: true),
            const SizedBox(height: 12),
            TextFormField(decoration: const InputDecoration(labelText: 'Confirm Password'), obscureText: true),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false),
                child: const Text('Save Password'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
