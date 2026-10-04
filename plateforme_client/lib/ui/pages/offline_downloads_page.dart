import 'dart:async';

import 'package:app_ekeflicks/providers/profile_provider.dart';
import 'package:app_ekeflicks/services/content_api_service.dart';
import 'package:app_ekeflicks/services/offline_download_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class OfflineDownloadsPage extends StatefulWidget {
  const OfflineDownloadsPage({super.key});

  @override
  State<OfflineDownloadsPage> createState() => _OfflineDownloadsPageState();
}

class _OfflineDownloadsPageState extends State<OfflineDownloadsPage> {
  Timer? _refreshTimer;
  List<OfflineDownload> _downloads = const [];
  bool _loading = true;
  String? _error;

  String? get _profileId =>
      context.read<ProfileProvider>().currentProfile?.id;

  OfflineDownloadService get _service => OfflineDownloadService(
        ContentApiService(context.read<ProfileProvider>().apiClient.dio),
      );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refresh();
      _refreshTimer = Timer.periodic(
        const Duration(seconds: 2),
        (_) => _refresh(silent: true),
      );
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refresh({bool silent = false}) async {
    if (!OfflineDownloadService.isSupported) {
      if (mounted) {
        setState(() {
          _downloads = const [];
          _loading = false;
          _error = null;
        });
      }
      return;
    }
    final profileId = _profileId;
    if (profileId == null || profileId.isEmpty) {
      if (mounted) {
        setState(() {
          _downloads = const [];
          _loading = false;
          _error = 'Sélectionnez un profil pour afficher ses téléchargements.';
        });
      }
      return;
    }
    try {
      final downloads = (await _service.list())
          .where((item) => item.profileId == profileId)
          .toList(growable: false);
      if (!mounted) return;
      setState(() {
        _downloads = downloads;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (!silent) {
          _error = 'Impossible de lire les téléchargements de cet appareil.';
        }
      });
    }
  }

  Future<void> _play(OfflineDownload download) async {
    try {
      await _service.play(download);
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      final message = error is StateError
          ? error.message.toString()
          : 'La lecture hors ligne a échoué.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _remove(OfflineDownload download) async {
    final profileId = _profileId;
    if (profileId == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le téléchargement ?'),
        content: Text('« ${download.title} » sera supprimé de cet appareil.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final revoked = await _service.remove(download, profileId: profileId);
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            revoked
                ? 'Téléchargement et autorisation supprimés.'
                : 'Téléchargement supprimé. La révocation serveur sera retentée à la prochaine connexion.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de supprimer ce téléchargement.')),
      );
    }
  }

  Future<void> _toggleDownloads() async {
    try {
      final active = _downloads.any(
        (item) => item.status == 'downloading' || item.status == 'queued',
      );
      if (active) {
        await _service.pauseAll();
      } else {
        await _service.resumeAll();
      }
      await _refresh();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gestion des téléchargements indisponible.')),
      );
    }
  }

  String _statusLabel(OfflineDownload item) {
    if (item.isExpired) return 'Licence expirée';
    switch (item.status) {
      case 'completed':
        return 'Disponible hors connexion';
      case 'downloading':
        return 'Téléchargement ${item.progress.round()} %';
      case 'paused':
        return 'En pause';
      case 'failed':
        return 'Échec du téléchargement';
      case 'removing':
        return 'Suppression…';
      default:
        return 'En attente';
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasActive = _downloads.any(
      (item) => item.status == 'downloading' || item.status == 'queued',
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Téléchargements'),
        actions: [
          if (OfflineDownloadService.isSupported)
            IconButton(
              tooltip: hasActive ? 'Mettre en pause' : 'Reprendre',
              onPressed: _toggleDownloads,
              icon: Icon(hasActive ? Icons.pause : Icons.play_arrow),
            ),
          IconButton(
            tooltip: 'Actualiser',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: kIsWeb
          ? const Center(
              child: Text('Les téléchargements hors ligne sont disponibles dans l’application mobile.'),
            )
          : _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(_error!, textAlign: TextAlign.center),
                      ),
                    )
                  : _downloads.isEmpty
                      ? const Center(
                          child: Text('Aucune vidéo téléchargée pour ce profil.'),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _downloads.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final item = _downloads[index];
                            return Card(
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                leading: item.posterUrl.isEmpty
                                    ? const Icon(Icons.movie_outlined, size: 40)
                                    : Image.network(
                                        item.posterUrl,
                                        width: 48,
                                        height: 64,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) =>
                                            const Icon(Icons.movie_outlined, size: 40),
                                      ),
                                title: Text(item.title, maxLines: 2),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(_statusLabel(item)),
                                    if (item.status == 'downloading' ||
                                        item.status == 'queued') ...[
                                      const SizedBox(height: 6),
                                      LinearProgressIndicator(
                                        value: item.status == 'queued'
                                            ? null
                                            : (item.progress / 100).clamp(0, 1).toDouble(),
                                      ),
                                    ],
                                    if (item.expiresAt != null)
                                      Text(
                                        'Expire le ${MaterialLocalizations.of(context).formatMediumDate(item.expiresAt!.toLocal())}',
                                      ),
                                  ],
                                ),
                                trailing: Wrap(
                                  spacing: 0,
                                  children: [
                                    if (item.canPlay)
                                      IconButton(
                                        tooltip: 'Lire hors connexion',
                                        onPressed: () => _play(item),
                                        icon: const Icon(Icons.play_circle_outline),
                                      ),
                                    IconButton(
                                      tooltip: 'Supprimer',
                                      onPressed: () => _remove(item),
                                      icon: const Icon(Icons.delete_outline),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
    );
  }
}
