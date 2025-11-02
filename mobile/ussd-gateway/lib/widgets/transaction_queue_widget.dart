import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../models/transaction_model.dart';
import '../config/app_config.dart';

class TransactionQueueWidget extends StatelessWidget {
  final List<TransactionModel> transactions;
  final List<TransactionModel> processingTransactions;
  final Function(String transactionId) onRetry;
  final Function(String transactionId) onCancel;

  const TransactionQueueWidget({
    super.key,
    required this.transactions,
    required this.processingTransactions,
    required this.onRetry,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final allTransactions = [...processingTransactions, ...transactions];
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Row(
              children: [
                const Icon(Icons.queue_rounded),
                const Gap(8),
                Text(
                  'File d\'attente',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (allTransactions.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${allTransactions.length}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
              ],
            ),
            
            const Gap(16),
            
            // Liste des transactions
            if (allTransactions.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                width: double.infinity,
                child: Column(
                  children: [
                    Icon(
                      Icons.inbox_rounded,
                      size: 48,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const Gap(16),
                    Text(
                      'Aucune transaction en attente',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Gap(8),
                    Text(
                      'Les transactions apparaîtront ici une fois ajoutées à la file',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              Column(
                children: allTransactions
                    .take(5) // Limiter à 5 pour éviter que la liste soit trop longue
                    .map((transaction) => _buildTransactionTile(context, transaction))
                    .toList(),
              ),
              
            // Lien "Voir toutes" si plus de 5 transactions
            if (allTransactions.length > 5) ...[
              const Gap(8),
              Center(
                child: TextButton(
                  onPressed: () {
                    // TODO: Naviguer vers la page complète des transactions
                  },
                  child: Text('Voir les ${allTransactions.length - 5} autres transactions'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionTile(BuildContext context, TransactionModel transaction) {
    final isProcessing = transaction.isProcessing;
    final operatorConfig = AppConfig.operators[transaction.operator.toLowerCase()];
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _getStatusColor(transaction.status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                _getOperatorIcon(transaction.operator),
                color: operatorConfig != null 
                    ? Color(int.parse('FF${operatorConfig['color']}', radix: 16))
                    : Colors.grey,
                size: 24,
              ),
              if (isProcessing)
                const Positioned(
                  right: 0,
                  bottom: 0,
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),
                ),
            ],
          ),
        ),
        title: Text(
          '${AppConfig.transactionTypes[transaction.type] ?? transaction.type} - ${transaction.displayAmount}',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Gap(4),
            Text(
              'De: ${transaction.fromPhone}',
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              'Vers: ${transaction.toPhone}',
              style: const TextStyle(fontSize: 12),
            ),
            const Gap(4),
            Row(
              children: [
                _buildStatusChip(context, transaction.status),
                const Gap(8),
                Text(
                  DateFormat('HH:mm').format(transaction.createdAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: isProcessing 
            ? null 
            : PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 16),
                onSelected: (value) {
                  switch (value) {
                    case 'retry':
                      onRetry(transaction.id);
                      break;
                    case 'cancel':
                      onCancel(transaction.id);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'retry',
                    child: Row(
                      children: [
                        Icon(Icons.refresh, size: 16),
                        Gap(8),
                        Text('Réessayer'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'cancel',
                    child: Row(
                      children: [
                        Icon(Icons.cancel, size: 16, color: Colors.red),
                        Gap(8),
                        Text('Annuler'),
                      ],
                    ),
                  ),
                ],
              ),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, String status) {
    final color = _getStatusColor(status);
    final text = AppConfig.transactionStatuses[status] ?? status;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'success':
        return Colors.green;
      case 'failed':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getOperatorIcon(String operator) {
    switch (operator.toLowerCase()) {
      case 'orange':
        return Icons.phone_android;
      case 'mtn':
        return Icons.smartphone;
      case 'camtel':
        return Icons.phone;
      default:
        return Icons.sim_card;
    }
  }
}