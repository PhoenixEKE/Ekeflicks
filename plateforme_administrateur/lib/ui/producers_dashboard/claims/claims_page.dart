import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plateforme_producteurs/api/admin_api_client.dart';
import 'package:plateforme_producteurs/core/core.dart';

class ClaimsManagementPage extends StatefulWidget {
  const ClaimsManagementPage({super.key});
  @override State<ClaimsManagementPage> createState() => _State();
}

class _State extends State<ClaimsManagementPage> {
  String type = 'closure';
  String? status;
  late Future<List<Map<String, dynamic>>> data;

  @override
  void initState() {
    super.initState();
    data = _load();
  }

  Future<List<Map<String, dynamic>>> _load() =>
      context.read<AdminApiClient>().claims(type: type, status: status);

  void reload() => setState(() => data = _load());

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Réclamations',
                style: AppTheme.textTitle.copyWith(fontSize: 24),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                children: [
                  DropdownButton<String>(
                    value: type,
                    items: const [
                      DropdownMenuItem(
                        value: 'closure',
                        child: Text('Clôture de compte'),
                      ),
                      DropdownMenuItem(
                        value: 'email',
                        child: Text("Changement d'e-mail"),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        type = v;
                        reload();
                      }
                    },
                  ),
                  DropdownButton<String?>(
                    value: status,
                    items: const [
                      DropdownMenuItem(
                        value: null,
                        child: Text('Tous les statuts'),
                      ),
                      DropdownMenuItem(
                        value: 'pending',
                        child: Text('En attente'),
                      ),
                      DropdownMenuItem(
                        value: 'rejected',
                        child: Text('Rejeté'),
                      ),
                    ],
                    onChanged: (v) {
                      status = v;
                      reload();
                    },
                  ),
                ],
              ),
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
                    final claims = s.data ?? [];
                    if (claims.isEmpty) {
                      return const Center(
                        child: Text('Aucune réclamation.'),
                      );
                    }
                    return ListView.separated(
                      itemCount: claims.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (_, i) {
                        final c = claims[i];
                        return ListTile(
                          leading: const Icon(Icons.support_agent),
                          title: Text(
                            c['user_email'] ?? c['requested_email'] ??
                                'Réclamation #${c['id']}',
                          ),
                          subtitle: Text(
                            c['reason'] ?? c['request_type'] ?? '',
                          ),
                          trailing: Chip(
                            label: Text(
                              (c['status'] ?? '').toString().toUpperCase(),
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
