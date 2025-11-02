import 'package:flutter/material.dart';

class BundleDetailScreen extends StatelessWidget {
  const BundleDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = (ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?) ?? {};
    final name = args['name'] as String? ?? 'Bundle';
    final price = args['price'] as String? ?? '—';

    return Scaffold(
      appBar: AppBar(title: const Text('Bundle Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Price: $price'),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () {/* TODO: buy */}, child: const Text('Confirm Purchase'))),
          ],
        ),
      ),
    );
  }
}