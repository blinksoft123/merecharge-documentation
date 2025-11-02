import 'package:flutter/material.dart';
import '../routes/app_routes.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const CircleAvatar(radius: 40, child: Icon(Icons.person, size: 48)),
            const SizedBox(height: 12),
            const Text('User Name'),
            const Text('user@example.com'),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: () => Navigator.pushNamed(context, AppRoutes.editProfile), child: const Text('Edit Profile')),
            ElevatedButton(onPressed: () => Navigator.pushNamed(context, AppRoutes.changePassword), child: const Text('Change Password')),
            TextButton(onPressed: () {}, child: const Text('Log Out')),
          ],
        ),
      ),
    );
  }
}
