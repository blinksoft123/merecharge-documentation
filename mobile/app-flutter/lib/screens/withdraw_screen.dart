import 'package:flutter/material.dart';
import '../routes/app_routes.dart';

class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({super.key});

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Retirer de l\'argent')),
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
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Numéro payeur',
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // TODO: Add form validation
                Navigator.pushNamed(context, AppRoutes.txConfirm, arguments: {
                  'title': 'Confirmer le retrait',
                  'details': {
                    'Montant': '_amountController.text', // TODO: Use controllers
                    'Vers': '_payerNumberController.text', // TODO: Use controllers
                  },
                });
              },
              child: const Text('Retirer'),
            ),
          ],
        ),
      ),
    );
  }
}
