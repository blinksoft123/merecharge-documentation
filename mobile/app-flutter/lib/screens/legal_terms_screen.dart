import 'package:flutter/material.dart';

class LegalTermsScreen extends StatelessWidget {
  const LegalTermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Conditions d\'utilisation')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('Contenu des conditions d\'utilisation (à compléter).'),
      ),
    );
  }
}