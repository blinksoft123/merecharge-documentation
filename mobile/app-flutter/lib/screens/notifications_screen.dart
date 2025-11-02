import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [TextButton(onPressed: () {}, child: const Text('Mark all as read'))],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(8),
        itemBuilder: (_, i) => ListTile(
          leading: const Icon(Icons.notifications),
          title: Text('Notification ${i + 1}'),
          subtitle: const Text('Details...'),
        ),
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemCount: 10,
      ),
    );
  }
}
