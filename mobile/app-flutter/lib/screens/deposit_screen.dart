import 'package:flutter/material.dart';
import '../routes/app_routes.dart';

class DepositScreen extends StatefulWidget {
  const DepositScreen({super.key});

  @override
  State<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends State<DepositScreen> {
  String? _paymentMethod;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recharger mon wallet')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Montant (XAF)',
                prefixIcon: Icon(Icons.money),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            const Text('Moyen de paiement', style: TextStyle(fontWeight: FontWeight.bold)),
            RadioListTile<String>(
              title: const Text('Orange Money'),
              value: 'Orange Money',
              groupValue: _paymentMethod,
              onChanged: (value) => setState(() => _paymentMethod = value),
            ),
            RadioListTile<String>(
              title: const Text('MTN Money'),
              value: 'MTN Money',
              groupValue: _paymentMethod,
              onChanged: (value) => setState(() => _paymentMethod = value),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // TODO: Add form validation
                Navigator.pushNamed(context, AppRoutes.txConfirm, arguments: {
                  'title': 'Confirmer le dépôt',
                  'details': {
                    'Montant': '_amountController.text', // TODO: Use controllers
                    'Paiement': _paymentMethod ?? 'Inconnu',
                  },
                });
              },
              child: const Text('Déposer'),
            ),
          ],
        ),
      ),
    );
  }
}
