import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:plateforme_administrateur/api/admin_api_client.dart';
import 'package:plateforme_administrateur/core/core.dart';

class ModerationPage extends StatefulWidget {
  const ModerationPage({super.key});
  @override State<ModerationPage> createState() => _ModerationPageState();
}

class _ModerationPageState extends State<ModerationPage> {
  late Future<List<Map<String, dynamic>>> _contents;
  late Future<List<Map<String, dynamic>>> _videos;

  @override void initState() { super.initState(); _reload(); }
  void _reload() {
    final api = context.read<AdminApiClient>();
    _contents = api.moderationContents();
    _videos = api.moderationVideos();
  }

  Future<void> _review(bool video, int id, String decision) async {
    final reason = TextEditingController();
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: Text(decision == 'approved' ? 'Valider le dépôt' : 'Rejeter le dépôt'),
      content: TextField(controller: reason, maxLines: 3,
        decoration: const InputDecoration(labelText: 'Motif / commentaire')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmer')),
      ],
    ));
    if (confirmed == true) {
      final api = context.read<AdminApiClient>();
      if (video) { await api.reviewVideo(id, decision, reason: reason.text); }
      else { await api.reviewContent(id, decision, reason: reason.text); }
      if (mounted) setState(_reload);
    }
    reason.dispose();
  }

  Widget _report(Map<String, dynamic>? report) {
    if (report == null) {
      return const Text('Rapport QC/IA indisponible. L’approbation doit attendre sa génération.');
    }
    String value(Object? v) => v?.toString() ?? '—';
    final flags = (report['flags'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[];
    final events = (report['detected_events'] as List?) ?? const [];
    final scores = report['moderation_scores'] is Map
        ? Map<String, dynamic>.from(report['moderation_scores'] as Map)
        : const <String, dynamic>{};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Rapport QC/IA — statut : ${value(report['status'])}', style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('Vidéo : ${value(report['video_codec'])} ${value(report['width'])}×${value(report['height'])} • ${value(report['frame_rate'])} fps'),
        Text('Audio : ${value(report['audio_codec'])} • ${value(report['audio_channels'])} canaux • ${value(report['sample_rate'])} Hz'),
        Text('Durée : ${value(report['duration_seconds'])} s • Loudness : ${value(report['loudness_lufs'])} LUFS'),
        Text('Score technique : ${value(report['technical_score'])} • images noires : ${value(report['black_frame_count'])} • images figées : ${value(report['freeze_frame_count'])}'),
        if (flags.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text('Alertes', style: TextStyle(fontWeight: FontWeight.w600)),
          ...flags.map((flag) => Text('• $flag')),
        ],
        if (scores.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text('Scores de modération IA', style: TextStyle(fontWeight: FontWeight.w600)),
          Text(scores.entries.map((e) => '${e.key}: ${e.value}').join(' • ')),
        ],
        if (events.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text('Événements détectés', style: TextStyle(fontWeight: FontWeight.w600)),
          ...events.take(30).map((event) => Text('• $event')),
        ],
        if ((report['error_message'] ?? '').toString().isNotEmpty)
          Text('Erreur : ${report['error_message']}', style: const TextStyle(color: Colors.red)),
        if (report['technical_metadata'] is Map && (report['technical_metadata'] as Map).isNotEmpty)
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text('Détails complets QC / FFprobe / IA'),
            children: [
              SelectableText(
                const JsonEncoder.withIndent('  ').convert(report['technical_metadata']),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ],
          ),
      ],
    );
  }

  Widget _list(Future<List<Map<String, dynamic>>> future, {required bool video}) =>
    FutureBuilder<List<Map<String, dynamic>>>(future: future, builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
      if (snapshot.hasError) return Center(child: Text('Chargement impossible : ${snapshot.error}'));
      final items = snapshot.data ?? [];
      if (items.isEmpty) return const Center(child: Text('Aucun dépôt en attente.'));
      return ListView.separated(itemCount: items.length, separatorBuilder: (_, __) => const Divider(), itemBuilder: (_, index) {
        final item = items[index];
        if (!video) {
          return ListTile(
            leading: const Icon(Icons.movie_creation, color: AppTheme.primary),
            title: Text(item['title']?.toString() ?? 'Sans titre'),
            subtitle: Text('Producteur : ${item['producer_email'] ?? 'Non renseigné'}'),
            trailing: Wrap(spacing: 8, children: [
              IconButton(tooltip: 'Rejeter', onPressed: () => _review(false, item['id'] as int, 'rejected'),
                icon: const Icon(Icons.close, color: Colors.redAccent)),
              IconButton(tooltip: 'Valider', onPressed: () => _review(false, item['id'] as int, 'approved'),
                icon: const Icon(Icons.check, color: Colors.green)),
            ]),
          );
        }
        final report = item['analysis_report'] is Map
            ? Map<String, dynamic>.from(item['analysis_report'] as Map)
            : null;
        final canApprove = report != null &&
            const {'passed', 'review_required'}.contains(report['status']);
        return ExpansionTile(
          leading: const Icon(Icons.video_file, color: AppTheme.primary),
          title: Text(item['content_title']?.toString() ?? 'Sans titre'),
          subtitle: Text('Producteur : ${item['producer_email'] ?? 'Non renseigné'} • QC : ${report?['status'] ?? 'rapport absent'}'),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            _report(report),
            const SizedBox(height: 12),
            Wrap(spacing: 8, children: [
              OutlinedButton.icon(
                onPressed: () => _review(true, item['id'] as int, 'rejected'),
                icon: const Icon(Icons.close, color: Colors.redAccent),
                label: const Text('Rejeter'),
              ),
              FilledButton.icon(
                onPressed: canApprove ? () => _review(true, item['id'] as int, 'approved') : null,
                icon: const Icon(Icons.check),
                label: Text(canApprove ? 'Valider après examen' : 'QC requis avant validation'),
              ),
            ]),
          ],
        );
      });
    });

  @override Widget build(BuildContext context) => DefaultTabController(length: 2, child: Column(children: [
    Text('Modération des dépôts', style: AppTheme.textTitle.copyWith(fontSize: 24)),
    const TabBar(tabs: [Tab(text: 'Contenus'), Tab(text: 'Fichiers vidéo')]),
    Expanded(child: TabBarView(children: [_list(_contents, video: false), _list(_videos, video: true)])),
  ]));
}
