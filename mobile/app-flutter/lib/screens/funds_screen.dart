import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../routes/app_routes.dart';

class FundsScreen extends StatelessWidget {
  const FundsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final user = FirebaseAuth.instance.currentUser;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Balance Header
            StreamBuilder<DocumentSnapshot>(
              stream: user != null
                  ? FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .snapshots()
                  : null,
              builder: (context, snapshot) {
                double balance = 0.0;
                
                if (snapshot.hasData && snapshot.data!.exists) {
                  final userData = snapshot.data!.data() as Map<String, dynamic>;
                  balance = (userData['balance'] as num?)?.toDouble() ?? 0.0;
                }
                
                return Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Text('Solde disponible', style: textTheme.titleMedium),
                        const SizedBox(height: 8),
                        snapshot.connectionState == ConnectionState.waiting
                            ? const CircularProgressIndicator()
                            : Text(
                                '${balance.toStringAsFixed(0)} XAF',
                                style: textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
                              ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // Info Message
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: Text(
                'evitez l\'attente en utilisant votre solde pour une meilleur experience',
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
              ),
            ),
            const SizedBox(height: 8),

            // Depot Button
            ElevatedButton.icon(
              icon: const Icon(Icons.add_card),
              label: const Text('Faire un dépôt'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: textTheme.titleMedium,
              ),
              onPressed: () => Navigator.pushNamed(context, AppRoutes.deposit),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // Horizontal Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ActionButton(
                  icon: Icons.shopping_cart_checkout,
                  label: 'Acheter crédit',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.recharge),
                ),
                _ActionButton(
                  icon: Icons.send_to_mobile,
                  label: 'Transférer',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.convert),
                ),
                _ActionButton(
                  icon: Icons.business_center_outlined,
                  label: 'Callbox',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.floatPurchase),
                ),
                _ActionButton(
                  icon: Icons.download_for_offline_outlined,
                  label: 'Retrait',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.withdraw),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(label),
          ],
        ),
      ),
    );
  }
}
