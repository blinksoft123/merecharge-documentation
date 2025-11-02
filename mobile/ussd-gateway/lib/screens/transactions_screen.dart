import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../services/transaction_service.dart';
import '../models/transaction_model.dart';
import '../config/app_config.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String _selectedOperator = '';
  String _selectedStatus = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transactionService = ref.watch(transactionServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des transactions'),
        leading: IconButton(
          onPressed: () => context.go('/dashboard'),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        actions: [
          // Bouton export
          IconButton(
            onPressed: _showExportDialog,
            icon: const Icon(Icons.file_download_rounded),
            tooltip: 'Exporter',
          ),
          
          // Menu options
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) {
              switch (value) {
                case 'clear_queue':
                  _showClearQueueDialog();
                  break;
                case 'clear_completed':
                  _showClearCompletedDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear_queue',
                child: ListTile(
                  leading: Icon(Icons.clear_all, color: Colors.red),
                  title: Text('Vider la file'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'clear_completed',
                child: ListTile(
                  leading: Icon(Icons.history),
                  title: Text('Effacer terminées'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.hourglass_empty, size: 20),
              text: 'En attente',
            ),
            Tab(
              icon: Icon(Icons.sync, size: 20), 
              text: 'En cours',
            ),
            Tab(
              icon: Icon(Icons.check_circle, size: 20),
              text: 'Terminées',
            ),
            Tab(
              icon: Icon(Icons.error, size: 20),
              text: 'Échouées',
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Barre de recherche et filtres
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 0.5,
                ),
              ),
            ),
            child: Column(
              children: [
                // Barre de recherche
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Rechercher par numéro, ID transaction...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
                
                const Gap(12),
                
                // Filtres
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedOperator.isEmpty ? null : _selectedOperator,
                        decoration: const InputDecoration(
                          labelText: 'Opérateur',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: [
                          const DropdownMenuItem(value: '', child: Text('Tous')),
                          ...AppConfig.operators.entries.map(
                            (entry) => DropdownMenuItem(
                              value: entry.key,
                              child: Text(entry.value['name']!),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedOperator = value ?? '';
                          });
                        },
                      ),
                    ),
                    
                    const Gap(12),
                    
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedStatus.isEmpty ? null : _selectedStatus,
                        decoration: const InputDecoration(
                          labelText: 'Statut',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: [
                          const DropdownMenuItem(value: '', child: Text('Tous')),
                          ...AppConfig.transactionStatuses.entries.map(
                            (entry) => DropdownMenuItem(
                              value: entry.key,
                              child: Text(entry.value),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedStatus = value ?? '';
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Contenu des onglets
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTransactionsList(
                  _filterTransactions(transactionService.pendingTransactions),
                  'pending',
                ),
                _buildTransactionsList(
                  _filterTransactions(transactionService.processingTransactions),
                  'processing',
                ),
                _buildTransactionsList(
                  _filterTransactions(transactionService.completedTransactions),
                  'completed',
                ),
                _buildTransactionsList(
                  _filterTransactions(transactionService.failedTransactions),
                  'failed',
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTransactionDialog,
        icon: const Icon(Icons.add),
        label: const Text('Ajouter test'),
        tooltip: 'Ajouter une transaction de test',
      ),
    );
  }

  List<TransactionModel> _filterTransactions(List<TransactionModel> transactions) {
    var filtered = transactions;

    // Filtrer par recherche
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((transaction) {
        return transaction.fromPhone.toLowerCase().contains(_searchQuery) ||
               transaction.toPhone.toLowerCase().contains(_searchQuery) ||
               transaction.id.toLowerCase().contains(_searchQuery) ||
               transaction.meRechargeId.toLowerCase().contains(_searchQuery);
      }).toList();
    }

    // Filtrer par opérateur
    if (_selectedOperator.isNotEmpty) {
      filtered = filtered.where((transaction) {
        return transaction.operator.toLowerCase() == _selectedOperator.toLowerCase();
      }).toList();
    }

    // Filtrer par statut
    if (_selectedStatus.isNotEmpty) {
      filtered = filtered.where((transaction) {
        return transaction.status == _selectedStatus;
      }).toList();
    }

    return filtered;
  }

  Widget _buildTransactionsList(List<TransactionModel> transactions, String category) {
    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getCategoryIcon(category),
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const Gap(16),
            Text(
              _getCategoryEmptyMessage(category),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const Gap(8),
            Text(
              _getCategoryEmptyDescription(category),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        return _buildTransactionCard(transaction);
      },
    );
  }

  Widget _buildTransactionCard(TransactionModel transaction) {
    final operatorConfig = AppConfig.operators[transaction.operator.toLowerCase()];
    final statusColor = _getStatusColor(transaction.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showTransactionDetails(transaction),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec opérateur et statut
              Row(
                children: [
                  // Icône opérateur
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: operatorConfig != null 
                          ? Color(int.parse('FF${operatorConfig['color']}', radix: 16)).withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getOperatorIcon(transaction.operator),
                      color: operatorConfig != null 
                          ? Color(int.parse('FF${operatorConfig['color']}', radix: 16))
                          : Colors.grey,
                      size: 20,
                    ),
                  ),
                  
                  const Gap(12),
                  
                  // Info principale
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              AppConfig.transactionTypes[transaction.type] ?? transaction.type,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                            const Spacer(),
                            _buildStatusChip(transaction.status),
                          ],
                        ),
                        const Gap(4),
                        Text(
                          transaction.displayAmount,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const Gap(12),
              
              // Détails de la transaction
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.phone_forwarded, size: 16),
                        const Gap(8),
                        Text('De: ${transaction.fromPhone}'),
                      ],
                    ),
                    const Gap(4),
                    Row(
                      children: [
                        const Icon(Icons.phone_callback, size: 16),
                        const Gap(8),
                        Text('Vers: ${transaction.toPhone}'),
                      ],
                    ),
                    const Gap(4),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 16),
                        const Gap(8),
                        Text('Créé: ${DateFormat('dd/MM/yyyy HH:mm').format(transaction.createdAt)}'),
                      ],
                    ),
                  ],
                ),
              ),
              
              const Gap(12),
              
              // Actions
              Row(
                children: [
                  if (transaction.canRetry) ...[
                    FilledButton.icon(
                      onPressed: () => _retryTransaction(transaction.id),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Réessayer'),
                    ),
                    const Gap(8),
                  ],
                  if (transaction.isPending || transaction.isProcessing) ...[
                    OutlinedButton.icon(
                      onPressed: () => _cancelTransaction(transaction.id),
                      icon: const Icon(Icons.cancel, size: 16),
                      label: const Text('Annuler'),
                    ),
                    const Gap(8),
                  ],
                  TextButton.icon(
                    onPressed: () => _showTransactionDetails(transaction),
                    icon: const Icon(Icons.info_outline, size: 16),
                    label: const Text('Détails'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final color = _getStatusColor(status);
    final text = AppConfig.transactionStatuses[status] ?? status;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  // Méthodes utilitaires
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

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'processing':
        return Icons.sync;
      case 'completed':
        return Icons.check_circle;
      case 'failed':
        return Icons.error;
      default:
        return Icons.list;
    }
  }

  String _getCategoryEmptyMessage(String category) {
    switch (category) {
      case 'pending':
        return 'Aucune transaction en attente';
      case 'processing':
        return 'Aucune transaction en cours';
      case 'completed':
        return 'Aucune transaction terminée';
      case 'failed':
        return 'Aucune transaction échouée';
      default:
        return 'Aucune transaction';
    }
  }

  String _getCategoryEmptyDescription(String category) {
    switch (category) {
      case 'pending':
        return 'Les nouvelles transactions apparaîtront ici';
      case 'processing':
        return 'Les transactions en cours de traitement apparaîtront ici';
      case 'completed':
        return 'Les transactions réussies apparaîtront ici';
      case 'failed':
        return 'Les transactions échouées apparaîtront ici';
      default:
        return '';
    }
  }

  // Actions
  Future<void> _retryTransaction(String transactionId) async {
    try {
      final transactionService = ref.read(transactionServiceProvider);
      await transactionService.retryTransaction(transactionId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaction remise en file'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cancelTransaction(String transactionId) async {
    try {
      final transactionService = ref.read(transactionServiceProvider);
      await transactionService.cancelTransaction(transactionId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaction annulée'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showTransactionDetails(TransactionModel transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Transaction ${transaction.id.substring(0, 8)}...'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Type', AppConfig.transactionTypes[transaction.type] ?? transaction.type),
              _buildDetailRow('Opérateur', transaction.operator),
              _buildDetailRow('De', transaction.fromPhone),
              _buildDetailRow('Vers', transaction.toPhone),
              _buildDetailRow('Montant', transaction.displayAmount),
              _buildDetailRow('Frais', transaction.displayFees),
              _buildDetailRow('Statut', AppConfig.transactionStatuses[transaction.status] ?? transaction.status),
              _buildDetailRow('Créé', DateFormat('dd/MM/yyyy HH:mm:ss').format(transaction.createdAt)),
              if (transaction.processedAt != null)
                _buildDetailRow('Traité', DateFormat('dd/MM/yyyy HH:mm:ss').format(transaction.processedAt!)),
              if (transaction.completedAt != null)
                _buildDetailRow('Terminé', DateFormat('dd/MM/yyyy HH:mm:ss').format(transaction.completedAt!)),
              if (transaction.errorMessage != null)
                _buildDetailRow('Erreur', transaction.errorMessage!),
              if (transaction.ussdResponse != null)
                _buildDetailRow('Réponse USSD', transaction.ussdResponse!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddTransactionDialog() {
    // TODO: Implémentation du dialogue d'ajout de transaction de test
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fonctionnalité en cours de développement'),
      ),
    );
  }

  void _showExportDialog() {
    // TODO: Implémentation de l'export
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export en cours de développement'),
      ),
    );
  }

  void _showClearQueueDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vider la file d\'attente'),
        content: const Text('Êtes-vous sûr de vouloir supprimer toutes les transactions en attente ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final transactionService = ref.read(transactionServiceProvider);
              await transactionService.clearQueue();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('File d\'attente vidée'),
                  ),
                );
              }
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  void _showClearCompletedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Effacer l\'historique'),
        content: const Text('Êtes-vous sûr de vouloir supprimer toutes les transactions terminées ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final transactionService = ref.read(transactionServiceProvider);
              await transactionService.clearCompleted();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Historique effacé'),
                  ),
                );
              }
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }
}