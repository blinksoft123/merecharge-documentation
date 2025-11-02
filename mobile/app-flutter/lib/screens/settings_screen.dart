import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/settings_controller.dart';
import '../routes/app_routes.dart';
import '../services/auth_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _showLogoutDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Déconnecter'),
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        await authService.signOut();
        
        if (context.mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.welcome,
            (route) => false,
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la déconnexion: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Notifications'),
            value: settings.notificationsEnabled,
            onChanged: (v) => settings.toggleNotifications(v),
          ),
          const ListTile(title: Text('Language')),
          RadioListTile<Locale>(
            title: const Text('Français'),
            value: const Locale('fr'),
            groupValue: settings.locale,
            onChanged: (v) => settings.setLocale(v!),
          ),
          RadioListTile<Locale>(
            title: const Text('English'),
            value: const Locale('en'),
            groupValue: settings.locale,
            onChanged: (v) => settings.setLocale(v!),
          ),
          const Divider(),
          ListTile(
            title: const Text('FAQ'),
            leading: const Icon(Icons.help_outline),
            onTap: () {},
          ),
          ListTile(
            title: const Text('Support'),
            leading: const Icon(Icons.support_agent),
            onTap: () => Navigator.pushNamed(context, AppRoutes.support),
          ),
          ListTile(
            title: const Text('CGU'),
            leading: const Icon(Icons.description_outlined),
            onTap: () => Navigator.pushNamed(context, AppRoutes.legalTerms),
          ),
          ListTile(
            title: const Text('Politique de confidentialité'),
            leading: const Icon(Icons.privacy_tip_outlined),
            onTap: () => Navigator.pushNamed(context, AppRoutes.privacy),
          ),
          const Divider(),
          ListTile(
            title: const Text('Admin - Commandes'),
            leading: const Icon(Icons.admin_panel_settings),
            subtitle: const Text('Gestion des commandes store'),
            onTap: () => Navigator.pushNamed(context, AppRoutes.adminOrders),
          ),
          const Divider(),
          ListTile(
            title: const Text('Déconnexion'),
            leading: const Icon(Icons.logout, color: Colors.red),
            textColor: Colors.red,
            onTap: () => _showLogoutDialog(context),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
