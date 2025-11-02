import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../routes/app_routes.dart';

import '../data/bundles.dart';
import '../models/bundle.dart';
import '../utils/operator_detector.dart';

class BundlePurchaseScreen extends StatefulWidget {
  const BundlePurchaseScreen({super.key});

  @override
  State<BundlePurchaseScreen> createState() => _BundlePurchaseScreenState();
}

class _BundlePurchaseScreenState extends State<BundlePurchaseScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Map<String, List<Bundle>> _camtelGroupedBundles;
  late Map<String, List<Bundle>> _orangeGroupedBundles;
  late Map<String, List<Bundle>> _mtnGroupedBundles;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // Camtel, Orange, MTN
    _camtelGroupedBundles = _groupBundles(camtelBundles);
    _orangeGroupedBundles = _groupBundles(orangeBundles);
    _mtnGroupedBundles = _groupBundles(mtnBundles);
  }

  Map<String, List<Bundle>> _groupBundles(List<Bundle> bundles) {
    final map = LinkedHashMap<String, List<Bundle>>();
    for (final bundle in bundles) {
      (map[bundle.category] ??= []).add(bundle);
    }
    return map;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Acheter un forfait'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Camtel'),
            Tab(text: 'Orange'),
            Tab(text: 'MTN'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Camtel
          _buildOperatorBundles(_camtelGroupedBundles),

          // Orange
          _buildOperatorBundles(_orangeGroupedBundles),

          // MTN
          _buildOperatorBundles(_mtnGroupedBundles),
        ],
      ),
    );
  }

  Widget _buildOperatorBundles(Map<String, List<Bundle>> groupedBundles) {
    final categories = groupedBundles.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final bundles = groupedBundles[category]!;
        return ExpansionTile(
          title: Text(category, style: const TextStyle(fontWeight: FontWeight.bold)),
          initiallyExpanded: index == 0, // Expand first category
          children: bundles.map((bundle) => _BundleCard(bundle: bundle)).toList(),
        );
      },
    );
  }
}

class _BundleCard extends StatelessWidget {
  final Bundle bundle;

  const _BundleCard({required this.bundle});

  @override
  Widget build(BuildContext context) {
    final format = NumberFormat.decimalPattern('fr');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      OperatorIcon(operator: bundle.operator, size: 20),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(bundle.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${format.format(bundle.price)} XAF',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                ),
              ],
            ),
            const Divider(height: 12),
            _buildInfoRow(Icons.calendar_today_outlined, 'Validité', bundle.validity),
            if (bundle.data != null) _buildInfoRow(Icons.data_usage, 'Data', bundle.data!),
            if (bundle.dailyQuota != null) _buildInfoRow(Icons.repeat, 'Quota Journalier', bundle.dailyQuota!),
            if (bundle.dataAfter != null) _buildInfoRow(Icons.network_check, 'Après quota', bundle.dataAfter!),
            if (bundle.speed != null) _buildInfoRow(Icons.speed, 'Vitesse', bundle.speed!),
            if (bundle.calls != null) _buildInfoRow(Icons.phone_outlined, 'Appels', '${bundle.calls} u.'),
            if (bundle.sms != null) _buildInfoRow(Icons.sms_outlined, 'SMS', '${bundle.sms}'),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(onPressed: () => Navigator.pushNamed(context, AppRoutes.bundleSubscription), child: const Text('Souscrire')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
          Expanded(child: Text(value, textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}
