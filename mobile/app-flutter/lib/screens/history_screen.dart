import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../routes/app_routes.dart';

class TransactionHistoryScreen extends StatelessWidget {
  const TransactionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Historique')),
      body: user == null
          ? const Center(
              child: Text('Connectez-vous pour voir votre historique'),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('transactions')
                  .where('userId', isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Erreur: ${snapshot.error}',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucune transaction',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final transactions = snapshot.data!.docs;

                return ListView.separated(
                  padding: const EdgeInsets.all(8),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final doc = transactions[index];
                    final data = doc.data() as Map<String, dynamic>;
                    
                    final type = data['type'] as String? ?? 'transaction';
                    final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
                    final status = data['status'] as String? ?? 'pending';
                    final timestamp = data['createdAt'] as Timestamp?;
                    
                    // Icône selon le type
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
                      case 'transfer':
                        icon = Icons.swap_horiz;
                        iconColor = Colors.green;
                        typeLabel = 'Transfert';
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
                    
                    // Couleur du statut
                    Color statusColor;
                    String statusText;
                    
                    switch (status) {
                      case 'completed':
                      case 'success':
                        statusColor = Colors.green;
                        statusText = 'Terminé';
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
                    String formattedDate = '';
                    if (timestamp != null) {
                      final date = timestamp.toDate();
                      formattedDate = DateFormat('dd MMM yyyy à HH:mm').format(date);
                    }

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: iconColor.withOpacity(0.1),
                        child: Icon(icon, color: iconColor),
                      ),
                      title: Text(
                        typeLabel,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${amount.toStringAsFixed(0)} XAF'),
                          if (formattedDate.isNotEmpty)
                            Text(
                              formattedDate,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRoutes.txDetail,
                        arguments: {'id': doc.id, 'data': data},
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const Divider(height: 1),
                );
              },
            ),
    );
  }
}
