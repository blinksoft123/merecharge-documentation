import 'package:flutter/material.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../constants/app_colors.dart';
import '../routes/app_routes.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  OrderStatus? _selectedStatus;
  final List<OrderStatus> _statuses = OrderStatus.values;

  // Sample orders for demo
  final List<Order> _orders = [
    Order(
      id: '1',
      userId: 'user_1',
      items: [
        OrderItem(
          product: const Product(
            id: '1',
            name: 'Samsung Galaxy A54',
            description: 'Smartphone Android',
            price: 245000,
            imageUrl: 'assets/images/phone1.jpg',
            category: 'Téléphones',
          ),
          quantity: 1,
          unitPrice: 245000,
        ),
      ],
      status: OrderStatus.pending,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      deliveryAddress: 'Douala, Akwa Nord',
      phoneNumber: '+237 6XX XXX XX1',
      notes: 'Livraison rapide svp',
    ),
    Order(
      id: '2',
      userId: 'user_2',
      items: [
        OrderItem(
          product: const Product(
            id: '5',
            name: 'AirPods Pro',
            description: 'Écouteurs sans fil',
            price: 135000,
            imageUrl: 'assets/images/airpods.jpg',
            category: 'Audio',
          ),
          quantity: 2,
          unitPrice: 135000,
        ),
      ],
      status: OrderStatus.confirmed,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      deliveryAddress: 'Yaoundé, Bastos',
      phoneNumber: '+237 6XX XXX XX2',
    ),
    Order(
      id: '3',
      userId: 'user_3',
      items: [
        OrderItem(
          product: const Product(
            id: '3',
            name: 'MacBook Air M2',
            description: 'Ordinateur portable Apple',
            price: 850000,
            imageUrl: 'assets/images/laptop1.jpg',
            category: 'Ordinateurs',
          ),
          quantity: 1,
          unitPrice: 850000,
        ),
      ],
      status: OrderStatus.shipped,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      deliveryAddress: 'Bafoussam Centre',
      phoneNumber: '+237 6XX XXX XX3',
    ),
  ];

  List<Order> get _filteredOrders {
    if (_selectedStatus == null) return _orders;
    return _orders.where((order) => order.status == _selectedStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Commandes'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: Column(
        children: [
          // Status Filter
          Container(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('Toutes'),
                    selected: _selectedStatus == null,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedStatus = null);
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  ..._statuses.map((status) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(_getStatusText(status)),
                      selected: _selectedStatus == status,
                      onSelected: (selected) {
                        setState(() => _selectedStatus = selected ? status : null);
                      },
                    ),
                  )),
                ],
              ),
            ),
          ),

          // Orders Summary Cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    title: 'Total',
                    count: _orders.length.toString(),
                    color: Colors.blue,
                    icon: Icons.shopping_bag,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SummaryCard(
                    title: 'En attente',
                    count: _orders.where((o) => o.status == OrderStatus.pending).length.toString(),
                    color: Colors.orange,
                    icon: Icons.hourglass_empty,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SummaryCard(
                    title: 'Expédiées',
                    count: _orders.where((o) => o.status == OrderStatus.shipped).length.toString(),
                    color: Colors.green,
                    icon: Icons.local_shipping,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Orders List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filteredOrders.length,
              itemBuilder: (context, index) {
                final order = _filteredOrders[index];
                return _OrderCard(
                  order: order,
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.adminOrderDetail,
                    arguments: order,
                  ),
                  onStatusChanged: (newStatus) {
                    setState(() {
                      // In real app, this would update the order in database
                      final orderIndex = _orders.indexWhere((o) => o.id == order.id);
                      if (orderIndex != -1) {
                        _orders[orderIndex] = Order(
                          id: order.id,
                          userId: order.userId,
                          items: order.items,
                          status: newStatus,
                          createdAt: order.createdAt,
                          updatedAt: DateTime.now(),
                          deliveryAddress: order.deliveryAddress,
                          phoneNumber: order.phoneNumber,
                          notes: order.notes,
                          shippingCost: order.shippingCost,
                          tax: order.tax,
                        );
                      }
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'En attente';
      case OrderStatus.confirmed:
        return 'Confirmée';
      case OrderStatus.processing:
        return 'En cours';
      case OrderStatus.shipped:
        return 'Expédiée';
      case OrderStatus.delivered:
        return 'Livrée';
      case OrderStatus.cancelled:
        return 'Annulée';
    }
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String count;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              count,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback onTap;
  final Function(OrderStatus) onStatusChanged;

  const _OrderCard({
    required this.order,
    required this.onTap,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Commande #${order.id}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  _StatusChip(status: order.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${order.items.length} article${order.items.length > 1 ? "s" : ""} - XAF ${order.total.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                order.phoneNumber,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                order.deliveryAddress,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              if (order.notes != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Note: ${order.notes}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDate(order.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                  if (order.status == OrderStatus.pending)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: () => onStatusChanged(OrderStatus.confirmed),
                          child: const Text('Confirmer'),
                        ),
                        TextButton(
                          onPressed: () => onStatusChanged(OrderStatus.cancelled),
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text('Annuler'),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours}h';
    } else {
      return 'Il y a ${difference.inDays}j';
    }
  }
}

class _StatusChip extends StatelessWidget {
  final OrderStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case OrderStatus.pending:
        color = Colors.orange;
        break;
      case OrderStatus.confirmed:
        color = Colors.blue;
        break;
      case OrderStatus.processing:
        color = Colors.purple;
        break;
      case OrderStatus.shipped:
        color = Colors.teal;
        break;
      case OrderStatus.delivered:
        color = Colors.green;
        break;
      case OrderStatus.cancelled:
        color = Colors.red;
        break;
    }

    return Chip(
      label: Text(
        _getStatusText(status),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
        ),
      ),
      backgroundColor: color,
    );
  }

  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'En attente';
      case OrderStatus.confirmed:
        return 'Confirmée';
      case OrderStatus.processing:
        return 'En cours';
      case OrderStatus.shipped:
        return 'Expédiée';
      case OrderStatus.delivered:
        return 'Livrée';
      case OrderStatus.cancelled:
        return 'Annulée';
    }
  }
}