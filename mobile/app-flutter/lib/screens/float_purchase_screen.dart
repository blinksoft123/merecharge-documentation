import 'package:flutter/material.dart';
import '../routes/app_routes.dart';

class FloatPurchaseScreen extends StatefulWidget {
  const FloatPurchaseScreen({super.key});

  @override
  State<FloatPurchaseScreen> createState() => _FloatPurchaseScreenState();
}

class _FloatPurchaseScreenState extends State<FloatPurchaseScreen> {
  String? _paymentMethod;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Achat de Float (Callbox)')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Numéro SIM',
                prefixIcon: Icon(Icons.sim_card_outlined),
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
            ElevatedButton(onPressed: () {
              // TODO: Add form validation
              Navigator.pushNamed(context, AppRoutes.txConfirm, arguments: {
                'title': 'Confirmer l\'achat de float',
                'details': {
                  'Numéro SIM': '_simController.text', // TODO: Use controllers
                  'Montant': '_amountController.text', // TODO: Use controllers
                  'Paiement': _paymentMethod ?? 'Inconnu',
                },
              });
            }, child: const Text('Acheter')),
          ],
        ),
      ),
    );
  }
}
