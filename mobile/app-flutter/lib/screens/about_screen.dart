import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('À propos')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('merecharge v1.0.0+1\n\nContact: support@example.com'),
      ),
    );
  }
}