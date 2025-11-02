import 'package:flutter/material.dart';

class PayerNumbersScreen extends StatefulWidget {
  const PayerNumbersScreen({super.key});

  @override
  State<PayerNumbersScreen> createState() => _PayerNumbersScreenState();
}

class _PayerNumbersScreenState extends State<PayerNumbersScreen> {
  final _items = <String>['690000001 (Principal)', '650000002'];
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Numéros Payeurs')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(child: TextField(controller: _ctrl, decoration: const InputDecoration(labelText: 'Ajouter un numéro payeur'))),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    final v = _ctrl.text.trim();
                    if (v.isEmpty) return;
                    setState(() => _items.add(v));
                    _ctrl.clear();
                  },
                  child: const Text('Ajouter'),
                )
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              itemCount: _items.length,
              itemBuilder: (_, i) => ListTile(
                leading: const Icon(Icons.phone_android),
                title: Text(_items[i]),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => setState(() => _items.removeAt(i)),
                ),
              ),
              separatorBuilder: (_, __) => const Divider(height: 1),
            ),
          ),
        ],
      ),
    );
  }
}
