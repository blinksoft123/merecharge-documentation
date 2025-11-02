import 'package:uuid/uuid.dart';

class TransactionModel {
  final String id;
  final String meRechargeId;
  final String type;
  final String operator;
  final String fromPhone;
  final String toPhone;
  final double amount;
  final double fees;
  final String status;
  final String ussdCode;
  final String? ussdResponse;
  final String? errorMessage;
  final int retryCount;
  final DateTime createdAt;
  final DateTime? processedAt;
  final DateTime? completedAt;
  final Map<String, dynamic>? metadata;

  TransactionModel({
    String? id,
    required this.meRechargeId,
    required this.type,
    required this.operator,
    required this.fromPhone,
    required this.toPhone,
    required this.amount,
    this.fees = 0.0,
    this.status = 'pending',
    required this.ussdCode,
    this.ussdResponse,
    this.errorMessage,
    this.retryCount = 0,
    DateTime? createdAt,
    this.processedAt,
    this.completedAt,
    this.metadata,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  // Copie avec modifications
  TransactionModel copyWith({
    String? id,
    String? meRechargeId,
    String? type,
    String? operator,
    String? fromPhone,
    String? toPhone,
    double? amount,
    double? fees,
    String? status,
    String? ussdCode,
    String? ussdResponse,
    String? errorMessage,
    int? retryCount,
    DateTime? createdAt,
    DateTime? processedAt,
    DateTime? completedAt,
    Map<String, dynamic>? metadata,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      meRechargeId: meRechargeId ?? this.meRechargeId,
      type: type ?? this.type,
      operator: operator ?? this.operator,
      fromPhone: fromPhone ?? this.fromPhone,
      toPhone: toPhone ?? this.toPhone,
      amount: amount ?? this.amount,
      fees: fees ?? this.fees,
      status: status ?? this.status,
      ussdCode: ussdCode ?? this.ussdCode,
      ussdResponse: ussdResponse ?? this.ussdResponse,
      errorMessage: errorMessage ?? this.errorMessage,
      retryCount: retryCount ?? this.retryCount,
      createdAt: createdAt ?? this.createdAt,
      processedAt: processedAt ?? this.processedAt,
      completedAt: completedAt ?? this.completedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  // Conversion vers JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'meRechargeId': meRechargeId,
      'type': type,
      'operator': operator,
      'fromPhone': fromPhone,
      'toPhone': toPhone,
      'amount': amount,
      'fees': fees,
      'status': status,
      'ussdCode': ussdCode,
      'ussdResponse': ussdResponse,
      'errorMessage': errorMessage,
      'retryCount': retryCount,
      'createdAt': createdAt.toIso8601String(),
      'processedAt': processedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  // Création depuis JSON
  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'],
      meRechargeId: json['meRechargeId'],
      type: json['type'],
      operator: json['operator'],
      fromPhone: json['fromPhone'],
      toPhone: json['toPhone'],
      amount: json['amount'].toDouble(),
      fees: json['fees']?.toDouble() ?? 0.0,
      status: json['status'],
      ussdCode: json['ussdCode'],
      ussdResponse: json['ussdResponse'],
      errorMessage: json['errorMessage'],
      retryCount: json['retryCount'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
      processedAt: json['processedAt'] != null 
          ? DateTime.parse(json['processedAt']) 
          : null,
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt']) 
          : null,
      metadata: json['metadata'],
    );
  }

  // Méthodes utilitaires
  bool get isPending => status == 'pending';
  bool get isProcessing => status == 'processing';
  bool get isSuccess => status == 'success';
  bool get isFailed => status == 'failed';
  bool get isCompleted => status == 'success' || status == 'failed';
  bool get canRetry => isFailed && retryCount < 3;
  
  Duration get processingTime {
    if (processedAt == null) return Duration.zero;
    return (completedAt ?? DateTime.now()).difference(processedAt!);
  }

  String get displayAmount {
    return '${amount.toStringAsFixed(0)} FCFA';
  }

  String get displayFees {
    return fees > 0 ? '${fees.toStringAsFixed(0)} FCFA' : 'Gratuit';
  }

  @override
  String toString() {
    return 'TransactionModel(id: $id, type: $type, operator: $operator, amount: $amount, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TransactionModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}