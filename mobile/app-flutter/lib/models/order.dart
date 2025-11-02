import 'product.dart';

enum OrderStatus {
  pending,
  confirmed,
  processing,
  shipped,
  delivered,
  cancelled,
}

class OrderItem {
  final Product product;
  final int quantity;
  final double unitPrice;

  const OrderItem({
    required this.product,
    required this.quantity,
    required this.unitPrice,
  });

  double get totalPrice => unitPrice * quantity;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      product: Product.fromJson(json['product'] as Map<String, dynamic>),
      quantity: json['quantity'] as int,
      unitPrice: (json['unitPrice'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product': product.toJson(),
      'quantity': quantity,
      'unitPrice': unitPrice,
    };
  }
}

class Order {
  final String id;
  final String userId;
  final List<OrderItem> items;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String deliveryAddress;
  final String phoneNumber;
  final String? notes;
  final double shippingCost;
  final double tax;

  const Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    required this.deliveryAddress,
    required this.phoneNumber,
    this.notes,
    this.shippingCost = 0.0,
    this.tax = 0.0,
  });

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.totalPrice);
  double get total => subtotal + shippingCost + tax;

  String get statusText {
    switch (status) {
      case OrderStatus.pending:
        return 'En attente';
      case OrderStatus.confirmed:
        return 'Confirmée';
      case OrderStatus.processing:
        return 'En traitement';
      case OrderStatus.shipped:
        return 'Expédiée';
      case OrderStatus.delivered:
        return 'Livrée';
      case OrderStatus.cancelled:
        return 'Annulée';
    }
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      userId: json['userId'] as String,
      items: (json['items'] as List)
          .map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      status: OrderStatus.values.byName(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      deliveryAddress: json['deliveryAddress'] as String,
      phoneNumber: json['phoneNumber'] as String,
      notes: json['notes'] as String?,
      shippingCost: (json['shippingCost'] as num?)?.toDouble() ?? 0.0,
      tax: (json['tax'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'items': items.map((item) => item.toJson()).toList(),
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'deliveryAddress': deliveryAddress,
      'phoneNumber': phoneNumber,
      'notes': notes,
      'shippingCost': shippingCost,
      'tax': tax,
    };
  }
}