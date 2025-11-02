import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../services/transaction_service.dart';
import '../services/merecharge_api_service.dart';
import '../config/app_config.dart';
import '../widgets/stat_card.dart';
import '../widgets/transaction_queue_widget.dart';
import '../widgets/operator_status_widget.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isConnectedToBackend = false;
  Map<String, dynamic>? _backendStats;

  @override
  void initState() {
    super.initState();
    _checkBackendConnection();
  }

  Future<void> _checkBackendConnection() async {
    try {
      final apiService = ref.read(meRechargeApiServiceProvider);
      final isConnected = await apiService.testConnection();
      final stats = await apiService.fetchBackendStats();
      
      if (mounted) {
        setState(() {
          _isConnectedToBackend = isConnected;
          _backendStats = stats;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnectedToBackend = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactionService = ref.watch(transactionServiceProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.dashboard_rounded, size: 28),
            const Gap(12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppConfig.appName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Call Box v${AppConfig.appVersion}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Indicateur de connexion backend
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _isConnectedToBackend 
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isConnectedToBackend 
                      ? Icons.cloud_done_rounded 
                      : Icons.cloud_off_rounded,
                  size: 16,
                  color: _isConnectedToBackend ? Colors.green : Colors.red,
                ),
                const Gap(4),
                Text(
                  _isConnectedToBackend ? 'Connecté' : 'Hors ligne',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _isConnectedToBackend ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
          const Gap(16),
          
          // Bouton actualiser
          IconButton(
            onPressed: _checkBackendConnection,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualiser',
          ),
          
          // Menu options
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) {
              switch (value) {
                case 'transactions':
                  context.go('/transactions');
                  break;
                case 'settings':
                  context.go('/settings');
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'transactions',
                child: ListTile(
                  leading: Icon(Icons.list_alt_rounded),
                  title: Text('Transactions'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings_rounded),
                  title: Text('Paramètres'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          const Gap(8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _checkBackendConnection,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cartes de statistiques principales
              StreamBuilder<Map<String, int>>(
                stream: transactionService.statsStream,
                initialData: transactionService.stats,
                builder: (context, snapshot) {
                  final stats = snapshot.data ?? {};
                  
                  return Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          title: 'En attente',
                          value: stats['pending']?.toString() ?? '0',
                          icon: Icons.hourglass_empty_rounded,
                          color: Colors.orange,
                          subtitle: 'transactions',
                        ).animate().slideX(delay: 100.ms),
                      ),
                      const Gap(12),
                      Expanded(
                        child: StatCard(
                          title: 'En cours',
                          value: stats['processing']?.toString() ?? '0',
                          icon: Icons.sync_rounded,
                          color: Colors.blue,
                          subtitle: 'en traitement',
                        ).animate().slideX(delay: 200.ms),
                      ),
                    ],
                  );
                },
              ),
              
              const Gap(12),
              
              StreamBuilder<Map<String, int>>(
                stream: transactionService.statsStream,
                initialData: transactionService.stats,
                builder: (context, snapshot) {
                  final stats = snapshot.data ?? {};
                  
                  return Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          title: 'Réussies',
                          value: stats['completed']?.toString() ?? '0',
                          icon: Icons.check_circle_outline_rounded,
                          color: Colors.green,
                          subtitle: 'terminées',
                        ).animate().slideX(delay: 300.ms),
                      ),
                      const Gap(12),
                      Expanded(
                        child: StatCard(
                          title: 'Échouées',
                          value: stats['failed']?.toString() ?? '0',
                          icon: Icons.error_outline_rounded,
                          color: Colors.red,
                          subtitle: 'en erreur',
                        ).animate().slideX(delay: 400.ms),
                      ),
                    ],
                  );
                },
              ),

              const Gap(24),

              // Graphique d'activité en temps réel
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.trending_up_rounded),
                          const Gap(8),
                          Text(
                            'Activité en temps réel',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Gap(16),
                      SizedBox(
                        height: 200,
                        child: _buildActivityChart(transactionService),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 500.ms),

              const Gap(16),

              // Statut des opérateurs
              const OperatorStatusWidget().animate().fadeIn(delay: 600.ms),

              const Gap(16),

              // File d'attente des transactions
              TransactionQueueWidget(
                transactions: transactionService.pendingTransactions,
                processingTransactions: transactionService.processingTransactions,
                onRetry: (transactionId) async {
                  try {
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
                },
                onCancel: (transactionId) async {
                  try {
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
                },
              ).animate().fadeIn(delay: 700.ms),

              const Gap(16),

              // Actions rapides
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Actions rapides',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Gap(16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilledButton.icon(
                            onPressed: () async {
                              await transactionService.clearQueue();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('File d\'attente vidée'),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.clear_all_rounded),
                            label: const Text('Vider la file'),
                          ),
                          FilledButton.tonal(
                            onPressed: () async {
                              await transactionService.clearCompleted();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Historique effacé'),
                                  ),
                                );
                              }
                            },
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.history_rounded),
                                Gap(8),
                                Text('Effacer historique'),
                              ],
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => context.go('/transactions'),
                            icon: const Icon(Icons.list_alt_rounded),
                            label: const Text('Voir toutes'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 800.ms),

              // Espace en bas pour le scroll
              const Gap(32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityChart(TransactionService transactionService) {
    // Données simulées pour le graphique - dans une vraie implémentation,
    // on utiliserait les vraies données de performance
    final data = List.generate(20, (index) {
      return ChartData(
        time: DateTime.now().subtract(Duration(minutes: (20 - index) * 5)),
        transactions: (transactionService.stats['total'] ?? 0) + 
                      (index % 5) - 2,
      );
    });

    return SfCartesianChart(
      primaryXAxis: DateTimeAxis(
        majorGridLines: const MajorGridLines(width: 0),
        labelFormat: 'HH:mm',
      ),
      primaryYAxis: NumericAxis(
        majorGridLines: const MajorGridLines(width: 0.5),
        minimum: 0,
      ),
      plotAreaBorderWidth: 0,
      series: <CartesianSeries>[
        SplineAreaSeries<ChartData, DateTime>(
          dataSource: data,
          xValueMapper: (ChartData data, _) => data.time,
          yValueMapper: (ChartData data, _) => data.transactions,
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          borderColor: Theme.of(context).colorScheme.primary,
          borderWidth: 2,
        ),
      ],
    );
  }
}

class ChartData {
  final DateTime time;
  final int transactions;

  ChartData({required this.time, required this.transactions});
}