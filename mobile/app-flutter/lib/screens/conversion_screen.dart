import 'package:flutter/material.dart';
import '../routes/app_routes.dart';

class MobileMoneyConversionScreen extends StatefulWidget {
  const MobileMoneyConversionScreen({super.key});

  @override
  State<MobileMoneyConversionScreen> createState() => _MobileMoneyConversionScreenState();
}

class _MobileMoneyConversionScreenState extends State<MobileMoneyConversionScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Conversion d\'argent')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Numéro source',
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Numéro destination',
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Montant (XAF)',
                prefixIcon: Icon(Icons.money),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // TODO: Add form validation
                Navigator.pushNamed(context, AppRoutes.txConfirm, arguments: {
                  'title': 'Confirmer la conversion',
                  'details': {
                    'De': '_sourceController.text', // TODO: Use controllers
                    'Vers': '_destController.text', // TODO: Use controllers
                    'Montant': '_amountController.text', // TODO: Use controllers
                  },
                });
              },
              child: const Text('Convertir'),
            ),
          ],
        ),
      ),
    );
  }
}
