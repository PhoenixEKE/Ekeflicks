import 'package:flutter/material.dart';
import 'package:plateforme_administrateur/api/admin_api_client.dart';
import 'package:plateforme_administrateur/core/core.dart';
import 'package:provider/provider.dart';

class SubscriptionsPage extends StatefulWidget {
  const SubscriptionsPage({super.key});

  @override
  State<SubscriptionsPage> createState() => _SubscriptionsPageState();
}

class _SubscriptionsPageState extends State<SubscriptionsPage> {
  final _search = TextEditingController();
  String? _status;
  String _period = 'month';
  late Future<Map<String, dynamic>> _data;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => _data = context.read<AdminApiClient>().subscriptions(
        search: _search.text.trim(),
        status: _status,
        period: _period,
      );

  void _refresh() => setState(_reload);

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Abonnements', style: AppTheme.textTitle.copyWith(fontSize: 24)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: 420,
                    child: TextField(
                      controller: _search,
                      onSubmitted: (_) => _refresh(),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        labelText: 'Rechercher un client ou une formule',
                      ),
                    ),
                  ),
                  DropdownButton<String?>(
                    value: _status,
                    hint: const Text('Tous les statuts'),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Tous les statuts')),
                      DropdownMenuItem(value: 'active', child: Text('Actifs')),
                      DropdownMenuItem(value: 'pending', child: Text('En attente')),
                      DropdownMenuItem(value: 'expired', child: Text('Expirés')),
                      DropdownMenuItem(value: 'cancelled', child: Text('Annulés')),
                    ],
                    onChanged: (value) { _status = value; _refresh(); },
                  ),
                  DropdownButton<String>(
                    value: _period,
                    items: const [
                      DropdownMenuItem(value: 'day', child: Text('Revenus par jour')),
                      DropdownMenuItem(value: 'week', child: Text('Revenus par semaine')),
                      DropdownMenuItem(value: 'month', child: Text('Revenus par mois')),
                      DropdownMenuItem(value: 'year', child: Text('Revenus par année')),
                    ],
                    onChanged: (value) { if (value != null) { _period = value; _refresh(); } },
                  ),
                  IconButton(onPressed: _refresh, tooltip: 'Actualiser', icon: const Icon(Icons.refresh)),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: FutureBuilder<Map<String, dynamic>>(
                  future: _data,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) return Center(child: Text('Erreur : ${snapshot.error}'));
                    final payload = snapshot.data ?? const {};
                    final statistics = Map<String, dynamic>.from(payload['statistics'] ?? const {});
                    final byStatus = Map<String, dynamic>.from(statistics['by_status'] ?? const {});
                    final rows = List<Map<String, dynamic>>.from(payload['results'] ?? const []);
                    final history = List<Map<String, dynamic>>.from(statistics['revenue_history'] ?? const []);
                    return Column(children: [
                      Wrap(spacing: 12, runSpacing: 12, children: [
                        _Stat('Total', statistics['total'] ?? 0, Icons.receipt_long),
                        _Stat('Actifs', byStatus['active'] ?? 0, Icons.check_circle),
                        _Stat('En attente', byStatus['pending'] ?? 0, Icons.schedule),
                        _Stat('Revenus validés', statistics['successful_revenue'] ?? 0, Icons.payments),
                      ]),
                      const SizedBox(height: 12),
                      if (history.isNotEmpty)
                        SizedBox(height: 76, child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: history.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (_, index) {
                            final item = history[index];
                            return Card(child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text('${item['period'] ?? ''}\n${item['amount']} ${item['currency']} • ${item['transactions']} transaction(s)'),
                            ));
                          },
                        )),
                      Expanded(child: rows.isEmpty
                        ? const Center(child: Text('Aucun abonnement trouvé.'))
                        : ListView.separated(
                            itemCount: rows.length,
                            separatorBuilder: (_, __) => const Divider(),
                            itemBuilder: (_, index) {
                              final row = rows[index];
                              return ListTile(
                                onTap: () => _showSubscription(row),
                                leading: const CircleAvatar(child: Icon(Icons.subscriptions)),
                                title: Text(row['name']?.toString().isNotEmpty == true ? row['name'].toString() : row['email'].toString()),
                                subtitle: Text('${row['email']} • ${row['plan']} • ${row['price']} ${row['currency']}'),
                                trailing: Chip(label: Text(_statusLabel(row['status']?.toString()))),
                              );
                            },
                          )),
                    ]);
                  },
                ),
              ),
            ],
          ),
        ),
      );

  Future<void> _showSubscription(Map<String, dynamic> subscription) async {
    final payments = List<Map<String, dynamic>>.from(subscription['payments'] ?? const []);
    await showDialog<void>(context: context, builder: (dialogContext) => AlertDialog(
      title: Text('Abonnement ${subscription['plan'] ?? ''}'),
      content: SizedBox(
        width: (MediaQuery.sizeOf(dialogContext).width - 64).clamp(260, 700).toDouble(),
        height: 460,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Client : ${subscription['name'] ?? ''} (${subscription['email'] ?? ''})'),
          Text('Période : ${subscription['started_at'] ?? ''} — ${subscription['expires_at'] ?? ''}'),
          Text('Renouvellement automatique : ${subscription['auto_renew'] == true ? 'Oui' : 'Non'}'),
          const Divider(),
          const Text('Transactions', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: payments.isEmpty
            ? const Center(child: Text('Aucune transaction liée.'))
            : ListView.separated(
                itemCount: payments.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (_, index) {
                  final payment = payments[index];
                  return ListTile(
                    leading: const Icon(Icons.payment),
                    title: SelectableText('${payment['transaction_id'] ?? ''}'),
                    subtitle: Text('${payment['provider'] ?? ''} • ${payment['paid_at'] ?? payment['created_at'] ?? ''}'),
                    trailing: Text('${payment['amount']} ${payment['currency']}\n${payment['status']}', textAlign: TextAlign.end),
                  );
                },
              )),
        ]),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Fermer'))],
    ));
  }

  String _statusLabel(String? value) => switch (value) {
        'active' => 'ACTIF',
        'pending' => 'EN ATTENTE',
        'expired' => 'EXPIRÉ',
        'cancelled' => 'ANNULÉ',
        _ => value?.toUpperCase() ?? '',
      };
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, this.icon);
  final String label;
  final Object value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: AppTheme.primary),
            const SizedBox(width: 10),
            Text('$label : $value'),
          ]),
        ),
      );
}

