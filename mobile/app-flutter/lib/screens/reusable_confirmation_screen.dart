import 'package:flutter/material.dart';
import '../routes/app_routes.dart';

class ReusableConfirmationScreen extends StatelessWidget {
  const ReusableConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = (ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?) ?? {};
    final title = args['title'] as String? ?? 'Confirmer la transaction';
    final details = args['details'] as Map<String, String>? ?? {};

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Récapitulatif', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            for (var entry in details.entries)
              _Row(label: entry.key, value: entry.value),
            const Divider(height: 32),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Frais & Total'),
              subtitle: Text('Calculés dynamiquement (à brancher)'),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      AppRoutes.txResult,
                      arguments: {
                        'success': true,
                        'title': title,
                      },
                    ),
                    child: const Text('Confirmer'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}