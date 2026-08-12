import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:plateforme_administrateur/api/admin_api_client.dart';
import 'package:plateforme_administrateur/core/core.dart';

class OverviewPage extends StatefulWidget {
  const OverviewPage({super.key});
  @override State<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage> {
  late Future<Map<String, dynamic>> data;
  @override void initState() { super.initState(); data = _load(); }
  Future<Map<String, dynamic>> _load() => context.read<AdminApiClient>().dashboard();
  void _reload() => setState(() => data = _load());

  String _ago(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
    if (date == null) return '';
    final difference = DateTime.now().difference(date);
    if (difference.inMinutes < 60) return 'il y a ${difference.inMinutes} min';
    if (difference.inHours < 24) return 'il y a ${difference.inHours} h';
    return 'il y a ${difference.inDays} j';
  }

  IconData _activityIcon(String? type) => switch (type) {
    'user' => Icons.person_add_alt_1,
    'payment' => Icons.payments,
    _ => Icons.movie_creation,
  };

  @override Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
    future: data,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return Center(
          child: FilledButton.icon(
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
            label: Text('Réessayer : ${snapshot.error}')
          )
        );
      }
      final payload = snapshot.data!;
      final stats = Map<String, dynamic>.from(payload['stats'] as Map);
      final activities = List<Map<String, dynamic>>.from(payload['recent_activity'] as List);
      final alerts = List<Map<String, dynamic>>.from(payload['alerts'] as List);
      final cards = [
        ('Utilisateurs', stats['users'], Icons.people, const Color(0xFF6C5CE7)),
        ('Producteurs actifs', stats['producers'], Icons.business, const Color(0xFF00A8CC)),
        ('Contenus', stats['contents'], Icons.video_library, const Color(0xFF9C27B0)),
        ('Publiés', stats['published'], Icons.check_circle, const Color(0xFF4CAF50)),
        ('À modérer', stats['pending_moderation'], Icons.fact_check, const Color(0xFFFF7675)),
        ('Revenu mensuel', '${stats['monthly_revenue']} €', Icons.euro, const Color(0xFF00B894)),
      ];
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(
                'Tableau de bord administrateur',
                style: AppTheme.textTitle.copyWith(fontSize: 22)
              )
            ),
            IconButton(
              onPressed: _reload,
              tooltip: 'Actualiser',
              icon: const Icon(Icons.refresh)
            )
          ]),
          const SizedBox(height: 8),
          LayoutBuilder(builder: (_, box) {
            final columns = box.maxWidth >= 1000 ? 6 : box.maxWidth >= 650 ? 3 : 2;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cards.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.65
              ),
              itemBuilder: (_, index) {
                final card = cards[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(card.$3, color: card.$4, size: 24),
                        const SizedBox(height: 4),
                        Text('${card.$2}', style: AppTheme.textTitle.copyWith(fontSize: 20)),
                        Text(card.$1, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTheme.textCaption),
                      ]
                    )
                  )
                );
              }
            );
          }),
          const SizedBox(height: 8),
          Expanded(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Expanded(
                flex: 3,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Activité récente', style: AppTheme.textSubtitle),
                      const Divider(),
                      Expanded(
                        child: activities.isEmpty
                          ? const Center(child: Text('Aucune activité récente.'))
                          : ListView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: activities.length,
                              itemBuilder: (_, index) {
                                final item = activities[index];
                                return ListTile(
                                  dense: true,
                                  visualDensity: VisualDensity.compact,
                                  contentPadding: EdgeInsets.zero,
                                  leading: CircleAvatar(
                                    radius: 16,
                                    child: Icon(_activityIcon(item['type']?.toString()), size: 17)
                                  ),
                                  title: Text(item['title']?.toString() ?? '', style: AppTheme.textBodyBold),
                                  subtitle: Text(
                                    item['message']?.toString() ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis
                                  ),
                                  trailing: Text(_ago(item['created_at']), style: AppTheme.textCaption)
                                );
                              }
                            )
                      )
                    ])
                  )
                )
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('⚠️ Alertes', style: AppTheme.textSubtitle),
                      const Divider(),
                      ...alerts.map((alert) => ListTile(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 15,
                          backgroundColor: (alert['count'] as num) > 0
                            ? Colors.orange.shade800
                            : Colors.green.shade800,
                          child: Text('${alert['count']}', style: const TextStyle(fontSize: 11, color: Colors.white))
                        ),
                        title: Text(alert['label']?.toString() ?? '', maxLines: 2)
                      )),
                    ])
                  )
                )
              ),
            ])
          ),
        ])
      );
    }
  );
}
