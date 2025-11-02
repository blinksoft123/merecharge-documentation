import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'dart:math';

import '../config/app_config.dart';

class OperatorStatusWidget extends StatefulWidget {
  const OperatorStatusWidget({super.key});

  @override
  State<OperatorStatusWidget> createState() => _OperatorStatusWidgetState();
}

class _OperatorStatusWidgetState extends State<OperatorStatusWidget> {
  final Map<String, OperatorStatus> _operatorStatuses = {};
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _initializeOperatorStatuses();
  }

  void _initializeOperatorStatuses() {
    for (final entry in AppConfig.operators.entries) {
      // Simuler des statuts d'opérateurs avec des données réalistes
      final isOnline = _random.nextBool();
      _operatorStatuses[entry.key] = OperatorStatus(
        name: entry.value['name']!,
        color: Color(int.parse('FF${entry.value['color']}', radix: 16)),
        isOnline: isOnline,
        responseTime: isOnline ? (50 + _random.nextInt(200)) : null,
        successRate: isOnline ? (85 + _random.nextInt(15)) : 0,
        lastUpdate: DateTime.now().subtract(
          Duration(minutes: _random.nextInt(30)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Row(
              children: [
                const Icon(Icons.cell_tower),
                const Gap(8),
                Text(
                  'Statut des opérateurs',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _initializeOperatorStatuses();
                    });
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  tooltip: 'Actualiser',
                ),
              ],
            ),
            
            const Gap(16),
            
            // Liste des opérateurs
            Column(
              children: _operatorStatuses.entries
                  .map((entry) => _buildOperatorTile(entry.key, entry.value))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOperatorTile(String operatorKey, OperatorStatus status) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: status.isOnline 
            ? Colors.green.withOpacity(0.05)
            : Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: status.isOnline 
              ? Colors.green.withOpacity(0.2)
              : Colors.red.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          // Icône opérateur avec indicateur de statut
          Stack(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: status.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getOperatorIcon(operatorKey),
                  color: status.color,
                  size: 20,
                ),
              ),
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: status.isOnline ? Colors.green : Colors.red,
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ),
          
          const Gap(12),
          
          // Informations de l'opérateur
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      status.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: status.isOnline 
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status.isOnline ? 'En ligne' : 'Hors ligne',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: status.isOnline ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const Gap(4),
                
                Row(
                  children: [
                    if (status.isOnline) ...[
                      Icon(
                        Icons.timer_outlined,
                        size: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const Gap(4),
                      Text(
                        '${status.responseTime}ms',
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const Gap(12),
                      Icon(
                        Icons.check_circle_outline,
                        size: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const Gap(4),
                      Text(
                        '${status.successRate}%',
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ] else
                      Text(
                        'Service indisponible',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.red.withOpacity(0.8),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          
          // Indicateur de performance visuel
          if (status.isOnline)
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: status.successRate / 100,
                child: Container(
                  decoration: BoxDecoration(
                    color: _getPerformanceColor(status.successRate),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
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

  Color _getPerformanceColor(int successRate) {
    if (successRate >= 95) return Colors.green;
    if (successRate >= 85) return Colors.orange;
    return Colors.red;
  }
}

class OperatorStatus {
  final String name;
  final Color color;
  final bool isOnline;
  final int? responseTime; // en millisecondes
  final int successRate; // pourcentage
  final DateTime lastUpdate;

  OperatorStatus({
    required this.name,
    required this.color,
    required this.isOnline,
    this.responseTime,
    required this.successRate,
    required this.lastUpdate,
  });
}