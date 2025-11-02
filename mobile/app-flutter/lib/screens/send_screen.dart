import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../utils/operator_detector.dart';
import '../routes/app_routes.dart';

class SendScreen extends StatefulWidget {
  const SendScreen({super.key});

  @override
  State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> {
  String? _detectedOperator;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Envoyer de l\'Argent',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Send Money Options
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: [
                _SendOption(
                  icon: Icons.phone_android,
                  title: 'Orange vers MTN',
                  subtitle: 'Transfert O->M',
                  color: Colors.orange,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.convert),
                ),
                _SendOption(
                  icon: Icons.phone_android,
                  title: 'MTN vers Orange',
                  subtitle: 'Transfert M->O',
                  color: Colors.yellow.shade700,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.convert),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Quick Send Form
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Envoi Rapide',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Numéro du destinataire',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.phone),
                        suffixIcon: _detectedOperator != null
                            ? Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: OperatorIcon(operator: _detectedOperator, size: 24),
                              )
                            : null,
                      ),
                      keyboardType: TextInputType.phone,
                      onChanged: (value) {
                        setState(() {
                          _detectedOperator = OperatorDetector.detect(value);
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Montant (XAF)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.money),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pushNamed(context, AppRoutes.txConfirm),
                        child: const Text('Envoyer'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            const Text(
              'Transferts Récents',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            
            // Recent Transfers
            const _RecentTransfersWidget(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _SendOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _SendOption({
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
                    fontSize: 13, // Réduit de 14 à 13
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
                    fontSize: 10, // Réduit de 11 à 10
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

class _RecentTransfersWidget extends StatelessWidget {
  const _RecentTransfersWidget();

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
          .where('type', whereIn: ['transfer', 'conversion'])
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Erreur: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
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
                      'Aucun transfert récent',
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
            final phoneNumber = data['phoneNumber'] as String? ?? data['recipientPhone'] as String? ?? 'Non spécifié';
            final status = data['status'] as String? ?? 'pending';
            final timestamp = data['createdAt'] as Timestamp?;
            
            // Couleur du statut
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
            String formattedDate = '';
            if (timestamp != null) {
              final date = timestamp.toDate();
              final now = DateTime.now();
              final difference = now.difference(date);
              
              if (difference.inMinutes < 1) {
                formattedDate = 'Il y a quelques secondes';
              } else if (difference.inHours < 1) {
                formattedDate = 'Il y a ${difference.inMinutes} min';
              } else if (difference.inDays < 1) {
                formattedDate = 'Il y a ${difference.inHours} h';
              } else {
                formattedDate = DateFormat('dd/MM HH:mm').format(date);
              }
            }
            
            // Masquer partiellement le numéro
            String maskedPhone = phoneNumber;
            if (phoneNumber.length > 6) {
              maskedPhone = '+237 6XX XXX ${phoneNumber.substring(phoneNumber.length - 2)}';
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green.withOpacity(0.1),
                  child: const Icon(Icons.send, color: Colors.green),
                ),
                title: Text(
                  'Envoi vers $maskedPhone',
                  style: const TextStyle(fontWeight: FontWeight.w500),
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
                      '-XAF ${amount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
