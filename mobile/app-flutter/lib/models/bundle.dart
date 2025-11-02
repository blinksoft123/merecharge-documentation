
import 'package:flutter/foundation.dart';

@immutable
class Bundle {
  final String operator;
  final String category;
  final String name;
  final int price;
  final String validity;
  final String? data;
  final String? dataAfter;
  final int? calls; // in units or minutes
  final int? sms;
  final String? dailyQuota;
  final String? speed;

  const Bundle({
    required this.operator,
    required this.category,
    required this.name,
    required this.price,
    required this.validity,
    this.data,
    this.dataAfter,
    this.calls,
    this.sms,
    this.dailyQuota,
    this.speed,
  });
}
