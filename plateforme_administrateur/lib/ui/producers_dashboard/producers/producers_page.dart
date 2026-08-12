import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plateforme_administrateur/api/admin_api_client.dart';
import 'package:plateforme_administrateur/core/core.dart';
import '../users/user_detail_page.dart';

class ProducersPage extends StatefulWidget {
  const ProducersPage({super.key});
  @override State<ProducersPage> createState() => _State();
}

class _State extends State<ProducersPage> {
  late Future<List<Map<String, dynamic>>> data;

  @override
  void initState() {
    super.initState();
    data = _load();
  }

  Future<List<Map<String, dynamic>>> _load() =>
      context.read<AdminApiClient>().users(kind: 'producer');

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Gestion des producteurs',
                    style: AppTheme.textTitle.copyWith(fontSize: 24),
                  ),
                  IconButton(
                    onPressed: () => setState(() => data = _load()),
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: data,
                  builder: (context, s) {
                    if (s.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (s.hasError) {
                      return Center(
                        child: Text('Erreur API : ${s.error}'),
                      );
                    }
                    final rows = s.data ?? [];
                    if (rows.isEmpty) {
                      return const Center(
                        child: Text('Aucun producteur.'),
                      );
                    }
                    return ListView.separated(
                      itemCount: rows.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (_, i) {
                        final p = rows[i];
                        return ListTile(
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => UserDetailPage(userId: p['id'] as int)
                              )
                            );
                            if (mounted) setState(() => data = _load());
                          },
                          leading: const CircleAvatar(
                            child: Icon(Icons.movie_creation),
                          ),
                          title: Text(
                            (p['producer_company'] as String?)?.isNotEmpty == true
                                ? p['producer_company']
                                : p['email'] ?? '',
                          ),
                          subtitle: Text(
                            '${p['email'] ?? ''} • ${p['phone'] ?? ''}',
                          ),
                          trailing: Chip(
                            label: Text(
                              p['is_active'] == true ? 'ACTIF' : 'SUSPENDU',
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
}
