import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../constants/app_colors.dart';
import '../services/firestore_service.dart';
import '../services/admin_service.dart';
import '../routes/app_routes.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminService _adminService = AdminService();
  final FirestoreService _firestoreService = FirestoreService();
  
  Map<String, dynamic> _stats = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _loading = true);
    try {
      final stats = await _adminService.getDashboardStats();
      setState(() {
        _stats = stats;
        _loading = false;
      });
    } catch (e) {
      print('Erreur lors du chargement des statistiques: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Admin'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'settings':
                  Navigator.pushNamed(context, AppRoutes.adminSettings);
                  break;
                case 'logout':
                  _logout();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('Paramètres'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Déconnexion'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre avec date
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Vue d\'ensemble',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _formatDate(DateTime.now()),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Cartes de statistiques
                    _buildStatsGrid(),
                    const SizedBox(height: 24),

                    // Graphiques
                    _buildChartsSection(),
                    const SizedBox(height: 24),

                    // Actions rapides
                    _buildQuickActions(),
                    const SizedBox(height: 24),

                    // Activité récente
                    _buildRecentActivity(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatsGrid() {
    final List<_StatCard> statCards = [
      _StatCard(
        title: 'Utilisateurs Actifs',
        value: _stats['activeUsers']?.toString() ?? '0',
        icon: Icons.people,
        color: AppColors.primary,
        trend: _stats['usersTrend']?.toString(),
      ),
      _StatCard(
        title: 'Transactions Aujourd\'hui',
        value: _stats['todayTransactions']?.toString() ?? '0',
        icon: Icons.swap_horiz,
        color: Colors.green,
        trend: _stats['transactionsTrend']?.toString(),
      ),
      _StatCard(
        title: 'Revenus du Jour',
        value: '${_stats['todayRevenue']?.toStringAsFixed(0) ?? '0'} XAF',
        icon: Icons.monetization_on,
        color: Colors.orange,
        trend: _stats['revenueTrend']?.toString(),
      ),
      _StatCard(
        title: 'Commandes Pendantes',
        value: _stats['pendingOrders']?.toString() ?? '0',
        icon: Icons.pending_actions,
        color: Colors.red,
        trend: null,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.5,
      ),
      itemCount: statCards.length,
      itemBuilder: (context, index) => _buildStatCard(statCards[index]),
    );
  }

  Widget _buildStatCard(_StatCard stat) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [stat.color.withOpacity(0.1), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(stat.icon, color: stat.color, size: 24),
                if (stat.trend != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: stat.trend!.startsWith('+') ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      stat.trend!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              stat.value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: stat.color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              stat.title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Analyses',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: Row(
            children: [
              // Graphique des transactions
              Expanded(
                flex: 2,
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Transactions (7 derniers jours)',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Expanded(child: _buildTransactionsChart()),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Graphique en secteurs des types de transactions
              Expanded(
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Types de transactions',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Expanded(child: _buildTransactionTypeChart()),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionsChart() {
    final List<FlSpot> spots = List.generate(7, (index) {
      final random = (index * 23 + 50) % 100 + 20;
      return FlSpot(index.toDouble(), random.toDouble());
    });

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primary.withOpacity(0.1),
            ),
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTypeChart() {
    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: [
          PieChartSectionData(
            value: 40,
            color: Colors.blue,
            title: 'Recharge',
            radius: 50,
            titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          PieChartSectionData(
            value: 30,
            color: Colors.green,
            title: 'Forfaits',
            radius: 50,
            titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          PieChartSectionData(
            value: 20,
            color: Colors.orange,
            title: 'Dépôts',
            radius: 50,
            titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          PieChartSectionData(
            value: 10,
            color: Colors.red,
            title: 'Autres',
            radius: 50,
            titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final List<_QuickAction> actions = [
      _QuickAction(
        title: 'Gérer les Utilisateurs',
        icon: Icons.people,
        color: AppColors.primary,
        onTap: () => Navigator.pushNamed(context, AppRoutes.adminUsers),
      ),
      _QuickAction(
        title: 'Transactions',
        icon: Icons.receipt_long,
        color: Colors.green,
        onTap: () => Navigator.pushNamed(context, AppRoutes.adminTransactions),
      ),
      _QuickAction(
        title: 'Commandes',
        icon: Icons.shopping_bag,
        color: Colors.orange,
        onTap: () => Navigator.pushNamed(context, AppRoutes.adminOrders),
      ),
      _QuickAction(
        title: 'Produits',
        icon: Icons.inventory,
        color: Colors.purple,
        onTap: () => Navigator.pushNamed(context, AppRoutes.adminProducts),
      ),
      _QuickAction(
        title: 'Notifications',
        icon: Icons.notifications,
        color: Colors.blue,
        onTap: () => Navigator.pushNamed(context, AppRoutes.adminNotifications),
      ),
      _QuickAction(
        title: 'Rapports',
        icon: Icons.analytics,
        color: Colors.teal,
        onTap: () => Navigator.pushNamed(context, AppRoutes.adminReports),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Actions Rapides',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) => _buildQuickActionCard(actions[index]),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(_QuickAction action) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(action.icon, color: action.color, size: 32),
              const SizedBox(height: 8),
              Text(
                action.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Activité Récente',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.adminActivity),
              child: const Text('Voir tout'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 5,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) => _buildActivityItem(index),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(int index) {
    final activities = [
      {
        'title': 'Nouvelle commande #1234',
        'subtitle': 'Commande de Samsung Galaxy A54',
        'time': 'Il y a 5 min',
        'icon': Icons.shopping_bag,
        'color': Colors.green,
      },
      {
        'title': 'Recharge de crédit',
        'subtitle': 'Recharge de 1000 XAF vers +237 6XX XXX XX1',
        'time': 'Il y a 15 min',
        'icon': Icons.phone_android,
        'color': Colors.blue,
      },
      {
        'title': 'Nouvel utilisateur',
        'subtitle': 'John Doe s\'est inscrit',
        'time': 'Il y a 30 min',
        'icon': Icons.person_add,
        'color': Colors.purple,
      },
      {
        'title': 'Transaction échouée',
        'subtitle': 'Échec du forfait internet vers +237 6XX XXX XX2',
        'time': 'Il y a 1h',
        'icon': Icons.error,
        'color': Colors.red,
      },
      {
        'title': 'Commande expédiée',
        'subtitle': 'Commande #1233 expédiée vers Douala',
        'time': 'Il y a 2h',
        'icon': Icons.local_shipping,
        'color': Colors.orange,
      },
    ];

    final activity = activities[index];

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: (activity['color'] as Color).withOpacity(0.1),
        child: Icon(
          activity['icon'] as IconData,
          color: activity['color'] as Color,
          size: 20,
        ),
      ),
      title: Text(
        activity['title'] as String,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        activity['subtitle'] as String,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 12,
        ),
      ),
      trailing: Text(
        activity['time'] as String,
        style: TextStyle(
          color: Colors.grey[500],
          fontSize: 10,
        ),
      ),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, AppRoutes.adminLogin);
            },
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin',
      'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _StatCard {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? trend;

  _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.trend,
  });
}

class _QuickAction {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _QuickAction({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}