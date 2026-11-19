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

  Widget _list(Future<List<Map<String, dynamic>>> future, {required bool video}) =>
    FutureBuilder<List<Map<String, dynamic>>>(future: future, builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
      if (snapshot.hasError) return Center(child: Text('Chargement impossible : ${snapshot.error}'));
      final items = snapshot.data ?? [];
      if (items.isEmpty) return const Center(child: Text('Aucun dépôt en attente.'));
      return ListView.separated(itemCount: items.length, separatorBuilder: (_, __) => const Divider(), itemBuilder: (_, index) {
        final item = items[index];
        return ListTile(
          leading: Icon(video ? Icons.video_file : Icons.movie_creation, color: AppTheme.primary),
          title: Text((video ? item['content_title'] : item['title'])?.toString() ?? 'Sans titre'),
          subtitle: Text('Producteur : ${item['producer_email'] ?? 'Non renseigné'}'),
          trailing: Wrap(spacing: 8, children: [
            IconButton(tooltip: 'Rejeter', onPressed: () => _review(video, item['id'] as int, 'rejected'),
              icon: const Icon(Icons.close, color: Colors.redAccent)),
            IconButton(tooltip: 'Valider', onPressed: () => _review(video, item['id'] as int, 'approved'),
              icon: const Icon(Icons.check, color: Colors.green)),
          ]),
        );
      });
    });

  @override Widget build(BuildContext context) => DefaultTabController(length: 2, child: Column(children: [
    Text('Modération des dépôts', style: AppTheme.textTitle.copyWith(fontSize: 24)),
    const TabBar(tabs: [Tab(text: 'Contenus'), Tab(text: 'Fichiers vidéo')]),
    Expanded(child: TabBarView(children: [_list(_contents, video: false), _list(_videos, video: true)])),
  ]));
}
