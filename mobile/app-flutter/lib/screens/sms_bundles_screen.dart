import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../routes/app_routes.dart';

import '../data/sms_bundles.dart';
import '../models/sms_bundle.dart';
import '../utils/operator_detector.dart';

class SmsBundlesScreen extends StatefulWidget {
  const SmsBundlesScreen({super.key});

  @override
  State<SmsBundlesScreen> createState() => _SmsBundlesScreenState();
}

class _SmsBundlesScreenState extends State<SmsBundlesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // Camtel, Orange, MTN
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
        title: const Text('Forfaits SMS'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(child: OperatorIcon(operator: 'Camtel')),
            Tab(child: OperatorIcon(operator: 'Orange')),
            Tab(child: OperatorIcon(operator: 'MTN')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOperatorSmsBundles(camtelSmsBundles),
          _buildOperatorSmsBundles(orangeSmsBundles),
          _buildOperatorSmsBundles(mtnSmsBundles),
        ],
      ),
    );
  }

  Widget _buildOperatorSmsBundles(List<SmsBundle> bundles) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: bundles.length,
      itemBuilder: (context, index) {
        final bundle = bundles[index];
        return _SmsBundleCard(bundle: bundle);
      },
    );
  }
}

class _SmsBundleCard extends StatelessWidget {
  final SmsBundle bundle;

  const _SmsBundleCard({required this.bundle});

  @override
  Widget build(BuildContext context) {
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
                if (bundle.price != null) Text(
                  bundle.price!,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                ),
              ],
            ),
            const Divider(height: 12),
            _buildInfoRow(Icons.sms_outlined, 'SMS', bundle.sms),
            _buildInfoRow(Icons.calendar_today_outlined, 'Validité', bundle.validity),
            if (bundle.network != null) _buildInfoRow(Icons.network_cell, 'Réseau', bundle.network!),
            if (bundle.bonus != null) _buildInfoRow(Icons.card_giftcard, 'Bonus', bundle.bonus!),
            if (bundle.activationCode != null) _buildInfoRow(Icons.dialpad, 'Code', bundle.activationCode!),
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
