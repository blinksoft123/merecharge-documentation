import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';

import '../services/storage_service.dart';
import '../services/merecharge_api_service.dart';
import '../services/transaction_service.dart';
import '../config/app_config.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  Map<String, dynamic> _settings = {};
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final storageService = ref.read(storageServiceProvider);
      final settings = await storageService.loadSettings();
      
      if (mounted) {
        setState(() {
          _settings = settings;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des paramètres: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveSettings() async {
    try {
      final storageService = ref.read(storageServiceProvider);
      await storageService.saveSettings(_settings);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Paramètres sauvegardés'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sauvegarde: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
        leading: IconButton(
          onPressed: () => context.go('/dashboard'),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        actions: [
          IconButton(
            onPressed: _saveSettings,
            icon: const Icon(Icons.save_rounded),
            tooltip: 'Sauvegarder',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Traitement automatique
            _buildSectionCard(
              title: 'Traitement automatique',
              icon: Icons.auto_mode_rounded,
              children: [
                _buildSwitchTile(
                  title: 'Traitement automatique',
                  subtitle: 'Traiter automatiquement les transactions en attente',
                  value: _settings['autoProcessing'] ?? true,
                  onChanged: (value) {
                    setState(() {
                      _settings['autoProcessing'] = value;
                    });
                  },
                ),
                
                _buildSliderTile(
                  title: 'Intervalle de traitement',
                  subtitle: '${_settings['processingInterval'] ?? 2} secondes entre chaque traitement',
                  value: (_settings['processingInterval'] ?? 2).toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  onChanged: (value) {
                    setState(() {
                      _settings['processingInterval'] = value.round();
                    });
                  },
                ),
                
                _buildSliderTile(
                  title: 'Transactions simultanées',
                  subtitle: '${_settings['maxConcurrentTransactions'] ?? 5} transactions maximum en parallèle',
                  value: (_settings['maxConcurrentTransactions'] ?? 5).toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  onChanged: (value) {
                    setState(() {
                      _settings['maxConcurrentTransactions'] = value.round();
                    });
                  },
                ),
                
                _buildSliderTile(
                  title: 'Tentatives de retry',
                  subtitle: '${_settings['maxRetries'] ?? 3} tentatives maximum en cas d\'échec',
                  value: (_settings['maxRetries'] ?? 3).toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  onChanged: (value) {
                    setState(() {
                      _settings['maxRetries'] = value.round();
                    });
                  },
                ),
              ],
            ),

            const Gap(16),

            // Section Connexion MeRecharge
            _buildSectionCard(
              title: 'Connexion MeRecharge',
              icon: Icons.cloud_sync_rounded,
              children: [
                _buildTextFieldTile(
                  title: 'URL API MeRecharge',
                  subtitle: 'Adresse du backend MeRecharge',
                  value: _settings['meRechargeApiUrl'] ?? AppConfig.meRechargeApiUrl,
                  onChanged: (value) {
                    setState(() {
                      _settings['meRechargeApiUrl'] = value;
                    });
                  },
                ),
                
                _buildTextFieldTile(
                  title: 'Port du serveur CallBox',
                  subtitle: 'Port d\'écoute pour les requêtes entrantes',
                  value: (_settings['serverPort'] ?? AppConfig.serverPort).toString(),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final port = int.tryParse(value);
                    if (port != null) {
                      setState(() {
                        _settings['serverPort'] = port;
                      });
                    }
                  },
                ),
                
                _buildActionTile(
                  title: 'Tester la connexion',
                  subtitle: 'Vérifier la connectivité avec le backend MeRecharge',
                  icon: Icons.network_ping_rounded,
                  onTap: _testBackendConnection,
                ),
              ],
            ),

            const Gap(16),

            // Section Notifications
            _buildSectionCard(
              title: 'Notifications',
              icon: Icons.notifications_rounded,
              children: [
                _buildSwitchTile(
                  title: 'Notifications activées',
                  subtitle: 'Afficher les notifications pour les événements importants',
                  value: _settings['notificationsEnabled'] ?? true,
                  onChanged: (value) {
                    setState(() {
                      _settings['notificationsEnabled'] = value;
                    });
                  },
                ),
                
                _buildSwitchTile(
                  title: 'Sons activés',
                  subtitle: 'Jouer des sons pour les notifications',
                  value: _settings['soundEnabled'] ?? true,
                  onChanged: (value) {
                    setState(() {
                      _settings['soundEnabled'] = value;
                    });
                  },
                ),
              ],
            ),

            const Gap(16),

            // Section Interface
            _buildSectionCard(
              title: 'Interface',
              icon: Icons.palette_rounded,
              children: [
                _buildSwitchTile(
                  title: 'Mode sombre',
                  subtitle: 'Utiliser le thème sombre',
                  value: _settings['darkMode'] ?? false,
                  onChanged: (value) {
                    setState(() {
                      _settings['darkMode'] = value;
                    });
                  },
                ),
                
                _buildDropdownTile(
                  title: 'Langue',
                  subtitle: 'Langue de l\'interface utilisateur',
                  value: _settings['language'] ?? 'fr',
                  items: const {
                    'fr': 'Français',
                    'en': 'English',
                  },
                  onChanged: (value) {
                    setState(() {
                      _settings['language'] = value;
                    });
                  },
                ),
              ],
            ),

            const Gap(16),

            // Section Données et sécurité
            _buildSectionCard(
              title: 'Données et sécurité',
              icon: Icons.security_rounded,
              children: [
                _buildActionTile(
                  title: 'Exporter les données',
                  subtitle: 'Sauvegarder toutes les transactions',
                  icon: Icons.file_download_rounded,
                  onTap: _exportData,
                ),
                
                _buildActionTile(
                  title: 'Statistiques de stockage',
                  subtitle: 'Voir l\'utilisation de l\'espace de stockage',
                  icon: Icons.storage_rounded,
                  onTap: _showStorageStats,
                ),
                
                const Divider(),
                
                _buildActionTile(
                  title: 'Effacer toutes les données',
                  subtitle: 'Supprimer définitivement toutes les transactions et paramètres',
                  icon: Icons.delete_forever_rounded,
                  iconColor: Colors.red,
                  textColor: Colors.red,
                  onTap: _showClearDataDialog,
                ),
              ],
            ),

            const Gap(16),

            // Section Informations
            _buildSectionCard(
              title: 'Informations',
              icon: Icons.info_rounded,
              children: [
                _buildInfoTile('Version', AppConfig.appVersion),
                _buildInfoTile('Application', AppConfig.appName),
                _buildInfoTile('Description', AppConfig.appDescription),
                
                const Divider(),
                
                _buildActionTile(
                  title: 'Logs de l\'application',
                  subtitle: 'Voir les journaux d\'activité',
                  icon: Icons.article_rounded,
                  onTap: _showLogs,
                ),
              ],
            ),

            // Espace en bas pour le scroll
            const Gap(32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20),
                const Gap(8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Gap(16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildSliderTile({
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          title: Text(title),
          subtitle: Text(subtitle),
          contentPadding: EdgeInsets.zero,
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildTextFieldTile({
    required String title,
    required String subtitle,
    required String value,
    required ValueChanged<String> onChanged,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          title: Text(title),
          subtitle: Text(subtitle),
          contentPadding: EdgeInsets.zero,
        ),
        const Gap(8),
        TextField(
          controller: TextEditingController(text: value),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          keyboardType: keyboardType,
          onChanged: onChanged,
        ),
        const Gap(16),
      ],
    );
  }

  Widget _buildDropdownTile({
    required String title,
    required String subtitle,
    required String value,
    required Map<String, String> items,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          title: Text(title),
          subtitle: Text(subtitle),
          contentPadding: EdgeInsets.zero,
        ),
        const Gap(8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          items: items.entries.map(
            (entry) => DropdownMenuItem(
              value: entry.key,
              child: Text(entry.value),
            ),
          ).toList(),
          onChanged: (newValue) {
            if (newValue != null) {
              onChanged(newValue);
            }
          },
        ),
        const Gap(16),
      ],
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title, style: TextStyle(color: textColor)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildInfoTile(String title, String value) {
    return ListTile(
      title: Text(title),
      trailing: Text(
        value,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  // Actions
  Future<void> _testBackendConnection() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            Gap(16),
            Text('Test de connexion...'),
          ],
        ),
      ),
    );

    try {
      final apiService = ref.read(meRechargeApiServiceProvider);
      final isConnected = await apiService.testConnection();
      
      if (mounted) {
        Navigator.of(context).pop(); // Fermer le dialog de chargement
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(isConnected ? 'Connexion réussie' : 'Connexion échouée'),
            content: Text(
              isConnected 
                  ? 'La connexion avec le backend MeRecharge fonctionne correctement.'
                  : 'Impossible de se connecter au backend MeRecharge. Vérifiez l\'URL et la connectivité réseau.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Fermer le dialog de chargement
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Erreur de connexion'),
            content: Text('Erreur lors du test: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _exportData() async {
    try {
      final transactionService = ref.read(transactionServiceProvider);
      final storageService = ref.read(storageServiceProvider);
      
      final transactions = transactionService.allTransactions;
      final filePath = await storageService.exportTransactions(transactions);
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Export réussi'),
            content: Text('Les données ont été exportées vers:\n$filePath'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'export: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showStorageStats() async {
    try {
      final storageService = ref.read(storageServiceProvider);
      final stats = await storageService.getStorageStats();
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Statistiques de stockage'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Fichier existant: ${stats['fileExists'] ? 'Oui' : 'Non'}'),
                if (stats['fileExists']) ...[
                  const Gap(8),
                  Text('Taille du fichier: ${(stats['fileSize'] / 1024).toStringAsFixed(1)} KB'),
                  const Gap(4),
                  Text('Dernière modification: ${stats['lastModified'] ?? 'Inconnue'}'),
                ],
                const Gap(8),
                Text('Taille en mémoire: ${(stats['preferencesSize'] / 1024).toStringAsFixed(1)} KB'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fermer'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Effacer toutes les données'),
        content: const Text(
          'Cette action est irréversible. Toutes les transactions, paramètres et données de l\'application seront définitivement supprimées.\n\nÊtes-vous absolument sûr ?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () async {
              Navigator.of(context).pop();
              
              try {
                final storageService = ref.read(storageServiceProvider);
                final transactionService = ref.read(transactionServiceProvider);
                
                await storageService.clearAllData();
                await transactionService.clearQueue();
                await transactionService.clearCompleted();
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Toutes les données ont été effacées'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  
                  // Recharger les paramètres par défaut
                  _loadSettings();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur lors de l\'effacement: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Effacer définitivement'),
          ),
        ],
      ),
    );
  }

  void _showLogs() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fonctionnalité de logs en cours de développement'),
      ),
    );
  }
}