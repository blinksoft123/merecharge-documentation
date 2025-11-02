import 'package:flutter/material.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Support / Help')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('FAQ', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Q: Comment recharger ?\nR: Allez dans Recharge...'),
            const Divider(height: 24),
            const Text('Contact Support'),
            const SizedBox(height: 8),
            TextFormField(decoration: const InputDecoration(labelText: 'Nom')),
            const SizedBox(height: 8),
            TextFormField(decoration: const InputDecoration(labelText: 'Numéro')),
            const SizedBox(height: 8),
            TextFormField(decoration: const InputDecoration(labelText: 'Message'), maxLines: 3),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () {}, child: const Text('Envoyer'))),
          ],
        ),
      ),
    );
  }
}
