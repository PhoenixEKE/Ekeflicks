import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plateforme_producteurs/api/admin_api_client.dart';
import 'package:plateforme_producteurs/core/core.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});
  @override State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final search = TextEditingController();
  late Future<List<Map<String, dynamic>>> data;

  @override
  void initState() {
    super.initState();
    data = _load();
  }

  Future<List<Map<String, dynamic>>> _load() =>
      context.read<AdminApiClient>().users(
            kind: 'customer',
            search: search.text.trim(),
          );

  void reload() => setState(() => data = _load());

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gestion des utilisateurs',
                style: AppTheme.textTitle.copyWith(fontSize: 24),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: search,
                onSubmitted: (_) => reload(),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  labelText: 'Rechercher par e-mail',
                  suffixIcon: IconButton(
                    onPressed: reload,
                    icon: const Icon(Icons.refresh),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: data,
                  builder: (context, s) {
                    if (s.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (s.hasError) {
                      return _Error(
                        message: s.error.toString(),
                        retry: reload,
                      );
                    }
                    final users = s.data ?? [];
                    if (users.isEmpty) {
                      return const Center(
                        child: Text('Aucun utilisateur trouvé.'),
                      );
                    }
                    return ListView.separated(
                      itemCount: users.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (_, i) => _UserTile(user: users[i]),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
}

class _UserTile extends StatelessWidget {
  const _UserTile({required this.user});
  final Map<String, dynamic> user;

  @override
  Widget build(BuildContext context) {
    final name = '${user['firstname'] ?? ''} ${user['lastname'] ?? ''}'.trim();
    return ListTile(
      leading: CircleAvatar(
        child: Text(name.isEmpty ? '?' : name[0].toUpperCase()),
      ),
      title: Text(
        name.isEmpty ? (user['email'] ?? 'Sans nom') : name,
      ),
      subtitle: Text(
        '${user['email'] ?? ''} • ${user['country_code'] ?? ''}',
      ),
      trailing: Chip(
        label: Text(user['is_active'] == true ? 'ACTIF' : 'SUSPENDU'),
        backgroundColor: user['is_active'] == true
            ? Colors.green.shade800
            : Colors.red.shade800,
      ),
    );
  }
}

class _Error extends StatelessWidget {
  const _Error({required this.message, required this.retry});
  final String message;
  final VoidCallback retry;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            TextButton.icon(
              onPressed: retry,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      );
}
