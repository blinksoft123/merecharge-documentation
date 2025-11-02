import 'package:flutter/material.dart';

class TransactionDetailScreen extends StatelessWidget {
  const TransactionDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = (ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?) ?? {};
    final id = args['id'] as String? ?? '—';

    return Scaffold(
      appBar: AppBar(title: const Text('Transaction Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reference: $id', style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            const Text('Type: Recharge/Bundle/Conversion'),
            const Text('Amount: —'),
            const Text('Fees: —'),
            const Text('Status: —'),
            const Divider(height: 32),
            const Text('Raw payload / metadata (à brancher avec API/Firestore)'),
          ],
        ),
      ),
    );
  }
}