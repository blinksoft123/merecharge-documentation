import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Politique de confidentialité')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('Contenu de la politique de confidentialité (à compléter).'),
      ),
    );
  }
}