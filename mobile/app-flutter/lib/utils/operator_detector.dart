import 'package:flutter/material.dart';

class OperatorDetector {
  static String? detect(String phoneNumber) {
    if (phoneNumber.startsWith('67') || phoneNumber.startsWith('68')) {
      return 'MTN';
    }
    if (phoneNumber.startsWith('69') || phoneNumber.startsWith('65')) {
      return 'Orange';
    }
    if (phoneNumber.startsWith('66')) {
      return 'Camtel';
    }
    return null;
  }
}

class OperatorIcon extends StatelessWidget {
  final String? operator;
  final double size;

  const OperatorIcon({super.key, this.operator, this.size = 24});

  @override
  Widget build(BuildContext context) {
    if (operator == null) {
      return const SizedBox.shrink();
    }

    String assetName;
    switch (operator) {
      case 'MTN':
        assetName = 'assets/icons/mtn.png';
        break;
      case 'Orange':
        assetName = 'assets/icons/orange.png';
        break;
      case 'Camtel':
        assetName = 'assets/icons/camtel.png';
        break;
      default:
        return const SizedBox.shrink();
    }

    return Image.asset(assetName, height: size, width: size);
  }
}
