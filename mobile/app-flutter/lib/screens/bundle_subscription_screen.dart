import 'package:flutter/material.dart';
import '../routes/app_routes.dart';

class BundleSubscriptionScreen extends StatefulWidget {
  const BundleSubscriptionScreen({super.key});

  @override
  State<BundleSubscriptionScreen> createState() => _BundleSubscriptionScreenState();
}

class _BundleSubscriptionScreenState extends State<BundleSubscriptionScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Souscrire au forfait')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // TODO: Display bundle details passed from previous screen
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Numéro bénéficiaire',
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: () {
              // TODO: Add form validation
              Navigator.pushNamed(context, AppRoutes.txConfirm, arguments: {
                'title': 'Confirmer la souscription',
                'details': {
                  'Forfait': 'TODO', // TODO: Pass bundle details
                  'Numéro': '_phoneController.text', // TODO: Use controllers
                },
              });
            }, child: const Text('Continuer')),
          ],
        ),
      ),
    );
  }
}
