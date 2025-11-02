import 'package:flutter/foundation.dart';

@immutable
class SmsBundle {
  final String operator;
  final String name;
  final String? price;
  final String sms; // Can be a number or "Illimités"
  final String validity;
  final String? network;
  final String? bonus;
  final String? activationCode;

  const SmsBundle({
    required this.operator,
    required this.name,
    this.price,
    required this.sms,
    required this.validity,
    this.network,
    this.bonus,
    this.activationCode,
  });
}
