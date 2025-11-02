import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../widgets/balance_widget.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Widget de solde en temps réel
            const BalanceWidget(),
            const SizedBox(height: 20),
            const Text('Actions rapides', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2, // Réduit de 4 à 2 pour avoir de plus gros boutons
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.9, // Ajusté pour éviter l'overflow
              children: [
                _QuickActionItem(
                  icon: Icons.flash_on,
                  label: 'Recharge Crédit',
                  subtitle: 'Acheter crédit ou data',
                  color: Colors.blue,
                  onTap: () => Navigator.pushNamed(context, '/recharge'),
                ),
                _QuickActionItem(
                  icon: Icons.swap_horiz,
                  label: 'Conversion Argent',
                  subtitle: 'Transférer vers un mobile',
                  color: Colors.green,
                  onTap: () => Navigator.pushNamed(context, '/convert'),
                ),
                _QuickActionItem(
                  icon: Icons.wifi,
                  label: 'Acheter Forfaits',
                  subtitle: 'Internet, appels, SMS',
                  color: Colors.orange,
                  onTap: () => Navigator.pushNamed(context, '/bundles'),
                ),
                _QuickActionItem(
                  icon: Icons.store,
                  label: 'Boutique',
                  subtitle: 'Articles & services',
                  color: Colors.purple,
                  onTap: () => Navigator.pushNamed(context, '/store'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Transactions récentes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const _RecentTransactionsWidget(),
            const SizedBox(height: 80), // Espace pour le bottom navigation
          ],
        ),
      ),
    );
  }
}

class _QuickActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: color.withOpacity(0.2),
                child: Icon(
                  icon,
                  color: color,
                  size: 26,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: color.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentTransactionsWidget extends StatelessWidget {
  const _RecentTransactionsWidget();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('transactions')
          .where('userId', isEqualTo: user.uid)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Erreur lors du chargement des transactions',
              style: TextStyle(color: Colors.red),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: const [
                  Icon(Icons.info_outline, color: Colors.grey),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Aucune transaction récente',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final type = data['type'] as String? ?? 'Transaction';
            final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
            final status = data['status'] as String? ?? 'pending';
            final timestamp = data['createdAt'] as Timestamp?;
            
            IconData icon;
            Color iconColor;
            String typeLabel;
            
            switch (type) {
              case 'recharge':
                icon = Icons.flash_on;
                iconColor = Colors.blue;
                typeLabel = 'Recharge';
                break;
              case 'conversion':
                icon = Icons.swap_horiz;
                iconColor = Colors.green;
                typeLabel = 'Conversion';
                break;
              case 'bundle':
                icon = Icons.wifi;
                iconColor = Colors.orange;
                typeLabel = 'Forfait';
                break;
              case 'deposit':
                icon = Icons.add_circle;
                iconColor = Colors.teal;
                typeLabel = 'Dépôt';
                break;
              case 'withdraw':
                icon = Icons.remove_circle;
                iconColor = Colors.red;
                typeLabel = 'Retrait';
                break;
              default:
                icon = Icons.receipt_long;
                iconColor = Colors.grey;
                typeLabel = 'Transaction';
            }
            
            String statusLabel;
            Color statusColor;
            
            switch (status) {
              case 'completed':
              case 'success':
                statusLabel = 'Terminé';
                statusColor = Colors.green;
                break;
              case 'pending':
                statusLabel = 'En cours';
                statusColor = Colors.orange;
                break;
              case 'failed':
              case 'error':
                statusLabel = 'Échoué';
                statusColor = Colors.red;
                break;
              default:
                statusLabel = status;
                statusColor = Colors.grey;
            }
            
            String formattedDate = 'Date inconnue';
            if (timestamp != null) {
              final date = timestamp.toDate();
              formattedDate = DateFormat('dd/MM HH:mm').format(date);
            }

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: iconColor.withOpacity(0.1),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              title: Text(
                typeLabel,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '$formattedDate \u2022 ${amount.toStringAsFixed(0)} XAF',
                style: const TextStyle(fontSize: 12),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              dense: true,
              onTap: () {
                // Navigator.pushNamed(context, AppRoutes.txDetail, arguments: doc.id);
              },
            );
          }).toList(),
        );
      },
    );
  }
}
