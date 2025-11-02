import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../routes/app_routes.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key, this.onSelectTab});

  final ValueChanged<int>? onSelectTab;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = (user?.displayName?.trim().isNotEmpty ?? false)
        ? user!.displayName!.trim()
        : 'Utilisateur';
    final email = user?.email ?? '';
    final photoUrl = user?.photoURL;
    final initials = _initialsFrom(displayName);

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(displayName),
              accountEmail: Text(email),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                child: photoUrl == null
                    ? Text(
                        initials,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              margin: EdgeInsets.zero,
            ),

            // Navigation (tabs)
            _sectionHeader(context, 'Navigation'),
            _tile(
              context,
              icon: Icons.home_outlined,
              label: 'Accueil',
              onTap: () {
                Navigator.pop(context);
                onSelectTab?.call(0);
              },
            ),
            _tile(
              context,
              icon: Icons.flash_on_outlined,
              label: 'Crédit',
              onTap: () {
                Navigator.pop(context);
                onSelectTab?.call(1);
              },
            ),
            _tile(
              context,
              icon: Icons.send_outlined,
              label: 'Envoyer',
              onTap: () {
                Navigator.pop(context);
                onSelectTab?.call(2);
              },
            ),
            _tile(
              context,
              icon: Icons.account_balance_wallet_outlined,
              label: 'Fonds',
              onTap: () {
                Navigator.pop(context);
                onSelectTab?.call(3);
              },
            ),
            const Divider(),

            // Core operations
            _sectionHeader(context, 'Opérations'),
            _routeTile(context, icon: Icons.phone_android, label: 'Recharge', route: AppRoutes.recharge),
            _routeTile(context, icon: Icons.swap_horiz, label: 'Conversion', route: AppRoutes.convert),
            _routeTile(context, icon: Icons.wifi_tethering, label: 'Forfaits', route: AppRoutes.bundles),
            _routeTile(context, icon: Icons.history, label: 'Historique', route: AppRoutes.history),


            // Store
            ExpansionTile(
              leading: const Icon(Icons.storefront_outlined),
              title: const Text('Boutique'),
              children: [
                _routeTile(
                  context,
                  icon: Icons.storefront,
                  label: 'Aller à la boutique',
                  route: AppRoutes.store,
                  dense: true,
                  indent: 32,
                ),
              ],
            ),


            // Paramètres (inclut Profil et Informations)
            ExpansionTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Paramètres'),
              children: [
                // Profil
                _routeTile(
                  context,
                  icon: Icons.badge_outlined,
                  label: 'Mon profil',
                  route: AppRoutes.profile,
                  dense: true,
                  indent: 32,
                ),
                _routeTile(
                  context,
                  icon: Icons.edit_outlined,
                  label: 'Modifier le profil',
                  route: AppRoutes.editProfile,
                  dense: true,
                  indent: 32,
                ),
                _routeTile(
                  context,
                  icon: Icons.lock_reset,
                  label: 'Changer le mot de passe',
                  route: AppRoutes.changePassword,
                  dense: true,
                  indent: 32,
                ),
                _routeTile(
                  context,
                  icon: Icons.phone_android_outlined,
                  label: 'Numéros Payeurs',
                  route: AppRoutes.payerNumbers,
                  dense: true,
                  indent: 32,
                ),
                const Divider(indent: 32, endIndent: 32),

                // Paramètres
                _routeTile(
                  context,
                  icon: Icons.settings,
                  label: 'Paramètres',
                  route: AppRoutes.settings,
                  dense: true,
                  indent: 32,
                ),
                _routeTile(
                  context,
                  icon: Icons.notifications_none,
                  label: 'Notifications',
                  route: AppRoutes.notifications,
                  dense: true,
                  indent: 32,
                ),
                _routeTile(
                  context,
                  icon: Icons.support_agent_outlined,
                  label: 'Support',
                  route: AppRoutes.support,
                  dense: true,
                  indent: 32,
                ),
                const Divider(indent: 32, endIndent: 32),

                // Informations
                _routeTile(
                  context,
                  icon: Icons.description_outlined,
                  label: 'Conditions d’utilisation',
                  route: AppRoutes.legalTerms,
                  dense: true,
                  indent: 32,
                ),
                _routeTile(
                  context,
                  icon: Icons.privacy_tip_outlined,
                  label: 'Politique de confidentialité',
                  route: AppRoutes.privacy,
                  dense: true,
                  indent: 32,
                ),
                _routeTile(
                  context,
                  icon: Icons.info_outline,
                  label: 'À propos',
                  route: AppRoutes.about,
                  dense: true,
                  indent: 32,
                ),
              ],
            ),


            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  static String _initialsFrom(String name) {
    final parts = name.trim().split(RegExp(r"\s+"));
    final firstTwo = parts.where((e) => e.isNotEmpty).take(2).toList();
    return firstTwo.map((e) => e[0]).join().toUpperCase();
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    bool dense = false,
    double indent = 16,
  }) {
    return ListTile(
      leading: Padding(
        padding: EdgeInsets.only(left: indent - 16),
        child: Icon(icon),
      ),
      horizontalTitleGap: 8,
      dense: dense,
      title: Text(label),
      onTap: onTap,
    );
  }

  Widget _routeTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
    bool dense = false,
    double indent = 16,
  }) {
    return _tile(
      context,
      icon: icon,
      label: label,
      dense: dense,
      indent: indent,
      onTap: () {
        Navigator.pop(context);
        Navigator.pushNamed(context, route);
      },
    );
  }
}
