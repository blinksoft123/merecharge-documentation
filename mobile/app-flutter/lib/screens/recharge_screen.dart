import 'package:flutter/material.dart';
import '../utils/operator_detector.dart';
import '../routes/app_routes.dart';

class CreditRechargeScreen extends StatefulWidget {
  const CreditRechargeScreen({super.key});

  @override
  State<CreditRechargeScreen> createState() => _CreditRechargeScreenState();
}

class _CreditRechargeScreenState extends State<CreditRechargeScreen> {
  final _operators = const ['MTN', 'Orange', 'Camtel'];
  final _payments = const ['Orange Money', 'MTN Money', 'Bank Card'];
  String? _operator;
  String? _payment;
  String? _detectedOperator;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Credit Recharge')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Phone number',
                suffixIcon: _detectedOperator != null
                    ? Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: OperatorIcon(operator: _detectedOperator, size: 24),
                      )
                    : null,
              ),
              keyboardType: TextInputType.phone,
              onChanged: (value) {
                setState(() {
                  _detectedOperator = OperatorDetector.detect(value);
                  if (_operators.contains(_detectedOperator)) {
                    _operator = _detectedOperator;
                  } else {
                    _operator = null;
                  }
                });
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _operator,
              decoration: const InputDecoration(labelText: 'Operator'),
              items: _operators.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _operator = v),
            ),
            const SizedBox(height: 12),
            TextFormField(decoration: const InputDecoration(labelText: 'Amount'), keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Payment method'),
              items: _payments.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _payment = v),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Add form validation
                  Navigator.pushNamed(context, AppRoutes.txConfirm, arguments: {
                    'title': 'Confirmer la recharge',
                    'details': {
                      'Numéro': '_phoneController.text', // TODO: Use controllers
                      'Montant': '_amountController.text', // TODO: Use controllers
                      'Opérateur': _operator ?? 'Inconnu',
                      'Paiement': _payment ?? 'Inconnu',
                    },
                  });
                },
                child: const Text('Recharge Now'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
