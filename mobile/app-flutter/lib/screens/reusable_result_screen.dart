import 'package:flutter/material.dart';

class ReusableResultScreen extends StatelessWidget {
  const ReusableResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = (ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?) ?? {};
    final success = args['success'] as bool? ?? false;
    final title = args['title'] as String? ?? 'Transaction';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                success ? Icons.check_circle_outline : Icons.error_outline,
                color: success ? Colors.green : Colors.red,
                size: 80,
              ),
              const SizedBox(height: 24),
              Text(
                success ? 'Opération réussie' : 'Échec de l\'opération',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                success
                    ? 'Votre transaction a été traitée avec succès.'
                    : 'Un problème est survenu. Veuillez réessayer.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                child: const Text('Retour à l\'accueil'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
