import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_colors.dart';
import '../services/admin_service.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final AdminService _adminService = AdminService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Map<String, dynamic>> _users = [];
  DocumentSnapshot? _lastDocument;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _users = [];
        _lastDocument = null;
        _hasMore = true;
      });
    }

    setState(() {
      refresh ? _loading = true : _loadingMore = true;
    });

    try {
      final result = await _adminService.getAllUsers(
        limit: 20,
        lastDocument: _lastDocument,
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
      );

      final List<Map<String, dynamic>> newUsers = 
          List<Map<String, dynamic>>.from(result['users'] ?? []);

      setState(() {
        if (refresh) {
          _users = newUsers;
        } else {
          _users.addAll(newUsers);
        }
        _lastDocument = result['lastDocument'];
        _hasMore = result['hasMore'] ?? false;
      });
    } catch (e) {
      print('Erreur chargement utilisateurs: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors du chargement des utilisateurs'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  void _searchUsers() {
    setState(() {
      _searchQuery = _searchController.text.trim();
    });
    _loadUsers(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Utilisateurs'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadUsers(refresh: true),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche
          _buildSearchBar(),
          
          // Liste des utilisateurs
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _buildUsersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher par email ou nom...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primary),
                ),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _searchUsers(),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _searchUsers,
            icon: const Icon(Icons.search, size: 18),
            label: const Text('Rechercher'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList() {
    if (_users.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Aucun utilisateur trouvé',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadUsers(refresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _users.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _users.length) {
            // Loading indicator pour plus de données
            if (_loadingMore) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              );
            } else if (_hasMore) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: () => _loadUsers(),
                  child: const Text('Charger plus'),
                ),
              );
            }
            return const SizedBox.shrink();
          }

          final user = _users[index];
          return _buildUserCard(user);
        },
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final isActive = user['isActive'] ?? true;
    final balance = (user['balance'] as num?)?.toDouble() ?? 0;
    final createdAt = user['createdAt'];
    final email = user['email'] ?? 'Email non disponible';
    final displayName = user['displayName'] ?? user['name'] ?? 'Nom non disponible';
    final phoneNumber = user['phoneNumber'] ?? 'Numéro non disponible';

    String formattedDate = 'Date non disponible';
    if (createdAt != null) {
      DateTime date;
      if (createdAt is Timestamp) {
        date = createdAt.toDate();
      } else if (createdAt is String) {
        date = DateTime.parse(createdAt);
      } else {
        date = DateTime.now();
      }
      formattedDate = '${date.day}/${date.month}/${date.year}';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: isActive ? AppColors.primary.withOpacity(0.1) : Colors.red.withOpacity(0.1),
          child: Icon(
            Icons.person,
            color: isActive ? AppColors.primary : Colors.red,
          ),
        ),
        title: Text(
          displayName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.black87 : Colors.red[700],
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(email, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 2),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isActive ? 'Actif' : 'Suspendu',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${balance.toStringAsFixed(0)} XAF',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: balance > 0 ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Informations détaillées
                _buildInfoRow('Email', email),
                _buildInfoRow('Téléphone', phoneNumber),
                _buildInfoRow('Solde', '${balance.toStringAsFixed(0)} XAF'),
                _buildInfoRow('Inscription', formattedDate),
                _buildInfoRow('ID', user['id'] ?? 'Non disponible'),
                
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                
                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _toggleUserStatus(user['id'], !isActive),
                      icon: Icon(isActive ? Icons.block : Icons.check_circle),
                      label: Text(isActive ? 'Suspendre' : 'Réactiver'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isActive ? Colors.red : Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showBalanceDialog(user),
                      icon: const Icon(Icons.account_balance_wallet),
                      label: const Text('Solde'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showUserDetails(user),
                      icon: const Icon(Icons.info),
                      label: const Text('Détails'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleUserStatus(String userId, bool newStatus) async {
    try {
      final success = await _adminService.toggleUserStatus(userId, newStatus);
      
      if (success) {
        setState(() {
          final userIndex = _users.indexWhere((u) => u['id'] == userId);
          if (userIndex != -1) {
            _users[userIndex]['isActive'] = newStatus;
          }
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(newStatus ? 'Utilisateur réactivé' : 'Utilisateur suspendu'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Échec de la modification');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la modification du statut'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showBalanceDialog(Map<String, dynamic> user) {
    final TextEditingController balanceController = TextEditingController();
    final TextEditingController reasonController = TextEditingController();
    
    balanceController.text = ((user['balance'] as num?)?.toDouble() ?? 0).toString();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Modifier le solde - ${user['displayName'] ?? user['name'] ?? 'Utilisateur'}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: balanceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Nouveau solde (XAF)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Raison de la modification',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newBalance = double.tryParse(balanceController.text);
              final reason = reasonController.text.trim();
              
              if (newBalance != null && reason.isNotEmpty) {
                Navigator.pop(context);
                await _updateBalance(user['id'], newBalance, reason);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Modifier'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateBalance(String userId, double newBalance, String reason) async {
    try {
      final success = await _adminService.updateUserBalance(userId, newBalance, reason);
      
      if (success) {
        setState(() {
          final userIndex = _users.indexWhere((u) => u['id'] == userId);
          if (userIndex != -1) {
            _users[userIndex]['balance'] = newBalance;
          }
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Solde mis à jour avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Échec de la mise à jour');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la mise à jour du solde'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showUserDetails(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Détails - ${user['displayName'] ?? user['name'] ?? 'Utilisateur'}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailItem('ID', user['id']),
              _buildDetailItem('Email', user['email']),
              _buildDetailItem('Nom', user['displayName'] ?? user['name']),
              _buildDetailItem('Téléphone', user['phoneNumber']),
              _buildDetailItem('Solde', '${((user['balance'] as num?)?.toDouble() ?? 0).toStringAsFixed(0)} XAF'),
              _buildDetailItem('Statut', (user['isActive'] ?? true) ? 'Actif' : 'Suspendu'),
              if (user['createdAt'] != null)
                _buildDetailItem('Inscription', _formatTimestamp(user['createdAt'])),
              if (user['lastLoginAt'] != null)
                _buildDetailItem('Dernière connexion', _formatTimestamp(user['lastLoginAt'])),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value ?? 'Non disponible'),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    try {
      DateTime date;
      if (timestamp is Timestamp) {
        date = timestamp.toDate();
      } else if (timestamp is String) {
        date = DateTime.parse(timestamp);
      } else {
        return 'Date invalide';
      }
      
      return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Date invalide';
    }
  }
}