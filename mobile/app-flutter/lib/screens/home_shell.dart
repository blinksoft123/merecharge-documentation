import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'credit_screen.dart';
import 'send_screen.dart';
import 'funds_screen.dart';
import '../widgets/app_drawer.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  final _pages = const [HomeScreen(), CreditScreen(), SendScreen(), FundsScreen()];
  final _titles = const ['Accueil', 'Crédit', 'Envoyer', 'Fonds'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: [
          // Bouton temporaire pour accéder au dashboard admin
          IconButton(
            icon: const Icon(Icons.admin_panel_settings),
            tooltip: 'Dashboard Admin',
            onPressed: () {
              Navigator.pushNamed(context, '/admin/login');
            },
          ),
        ],
      ),
      drawer: AppDrawer(
        onSelectTab: (i) => setState(() => _index = i),
      ),
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Accueil'),
          NavigationDestination(icon: Icon(Icons.flash_on_outlined), selectedIcon: Icon(Icons.flash_on), label: 'Crédit'),
          NavigationDestination(icon: Icon(Icons.send_outlined), selectedIcon: Icon(Icons.send), label: 'Envoyer'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet), label: 'Fonds'),
        ],
      ),
    );
  }
}
