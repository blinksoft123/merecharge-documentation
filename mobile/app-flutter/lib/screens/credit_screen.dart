import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../routes/app_routes.dart';

class CreditScreen extends StatelessWidget {
  const CreditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Services Crédit',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Credit Services Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                _ServiceCard(
                  icon: Icons.flash_on,
                  title: 'Recharge Crédit',
                  subtitle: 'Recharger votre crédit mobile',
                  color: Colors.blue,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.recharge),
                ),
                _ServiceCard(
                  icon: Icons.wifi,
                  title: 'Forfaits Internet',
                  subtitle: 'Acheter des forfaits data',
                  color: Colors.green,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.bundles),
                ),
                _ServiceCard(
                  icon: Icons.phone,
                  title: 'Crédit d\'Appel',
                  subtitle: 'Forfaits d\'appels illimités',
                  color: Colors.orange,
                  onTap: () {},
                ),
                _ServiceCard(
                  icon: Icons.message,
                  title: 'Forfaits SMS',
                  subtitle: 'Forfaits SMS illimités',
                  color: Colors.purple,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.smsBundles),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            const Text(
              'Historique des Recharges',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            
            // Recent Recharge History
            const _RechargeHistoryWidget(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _RechargeHistoryWidget extends StatelessWidget {
  const _RechargeHistoryWidget();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Connectez-vous pour voir votre historique',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('transactions')
          .where('userId', isEqualTo: user.uid)
          .where('type', isEqualTo: 'recharge')
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: const [
                  Icon(Icons.error_outline, color: Colors.red),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Erreur lors du chargement de l\'historique',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
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
                      'Aucune recharge effectuée',
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
            final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
            final phoneNumber = data['phoneNumber'] as String? ?? 'Non spécifié';
            final operator = data['operator'] as String? ?? 'Opérateur';
            final status = data['status'] as String? ?? 'pending';
            final timestamp = data['createdAt'] as Timestamp?;
            
            // Déterminer la couleur et le texte du statut
            Color statusColor;
            String statusText;
            
            switch (status) {
              case 'completed':
              case 'success':
                statusColor = Colors.green;
                statusText = 'Succès';
                break;
              case 'pending':
                statusColor = Colors.orange;
                statusText = 'En cours';
                break;
              case 'failed':
              case 'error':
                statusColor = Colors.red;
                statusText = 'Échoué';
                break;
              default:
                statusColor = Colors.grey;
                statusText = status;
            }
            
            // Formater la date
            String formattedDate = 'Date inconnue';
            if (timestamp != null) {
              final date = timestamp.toDate();
              formattedDate = DateFormat('dd/MM/yy HH:mm').format(date);
            }
            
            // Masquer partiellement le numéro de téléphone
            String maskedPhone = phoneNumber;
            if (phoneNumber.length > 6) {
              maskedPhone = '${phoneNumber.substring(0, 4)} XXX ${phoneNumber.substring(phoneNumber.length - 2)}';
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Icon(Icons.flash_on, color: AppColors.primary),
                ),
                title: Text(
                  '$operator - $maskedPhone',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  formattedDate,
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'XAF ${amount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                dense: true,
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 20, // Réduit de 24 à 20
                backgroundColor: color.withOpacity(0.1),
                child: Icon(icon, color: color, size: 24), // Réduit de 28 à 24
              ),
              const SizedBox(height: 8), // Réduit de 12 à 8
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12, // Réduit de 13 à 12
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 2), // Réduit de 4 à 2
              Flexible(
                child: Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 9, // Réduit de 10 à 9
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}