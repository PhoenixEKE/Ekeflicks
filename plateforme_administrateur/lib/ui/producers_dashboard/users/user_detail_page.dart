import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plateforme_administrateur/api/admin_api_client.dart';
import 'package:plateforme_administrateur/core/core.dart';

class UserDetailPage extends StatefulWidget {
  final int userId;
  const UserDetailPage({super.key, required this.userId});

  @override
  State<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage> {
  late Future<Map<String, dynamic>> data;

  @override
  void initState() {
    super.initState();
    data = _load();
  }

  Future<Map<String, dynamic>> _load() =>
      context.read<AdminApiClient>().userDetail(widget.userId);

  void _reload() => setState(() => data = _load());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails de l\'utilisateur'),
        actions: [
          IconButton(
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: data,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Erreur : ${snapshot.error}'),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _reload,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }
          final user = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête avec avatar et nom
                Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      child: Text(
                        '${user['firstname'] ?? ''} ${user['lastname'] ?? ''}'
                            .trim()
                            .isEmpty
                            ? '?'
                            : '${user['firstname'] ?? ''} ${user['lastname'] ?? ''}'
                                .trim()[0]
                                .toUpperCase(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${user['firstname'] ?? ''} ${user['lastname'] ?? ''}'.trim(),
                            style: AppTheme.textTitle,
                          ),
                          Text(
                            user['email'] ?? '',
                            style: AppTheme.textBody,
                          ),
                          Chip(
                            label: Text(
                              user['is_active'] == true ? 'ACTIF' : 'SUSPENDU',
                            ),
                            backgroundColor: user['is_active'] == true
                                ? Colors.green.shade800
                                : Colors.red.shade800,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Informations
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Informations',
                          style: AppTheme.textSubtitle,
                        ),
                        const SizedBox(height: 12),
                        _infoRow('Email', user['email'] ?? ''),
                        _infoRow('Téléphone', user['phone'] ?? ''),
                        _infoRow('Pays', user['country_code'] ?? ''),
                        _infoRow('Date d\'inscription', user['created_at'] ?? ''),
                        _infoRow('Vérifié', user['is_verified'] == true ? 'Oui' : 'Non'),
                        _infoRow('Producteur', user['is_producer'] == true ? 'Oui' : 'Non'),
                        if (user['producer_company'] != null &&
                            user['producer_company'].toString().isNotEmpty)
                          _infoRow('Société', user['producer_company']),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Actions
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () async {
                          final newStatus = !(user['is_active'] as bool);
                          try {
                            await context.read<AdminApiClient>().setUserStatus(
                                  widget.userId,
                                  isActive: newStatus,
                                );
                            _reload();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Utilisateur ${newStatus ? "réactivé" : "suspendu"}',
                                ),
                                backgroundColor: newStatus ? Colors.green : Colors.orange,
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Erreur : $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        icon: Icon(
                          user['is_active'] == true
                              ? Icons.block
                              : Icons.check_circle,
                        ),
                        label: Text(
                          user['is_active'] == true ? 'Suspendre' : 'Réactiver',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // Voir les paiements
                        },
                        icon: const Icon(Icons.payments),
                        label: const Text('Paiements'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTheme.textCaption,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTheme.textBody,
            ),
          ),
        ],
      ),
    );
  }
}
