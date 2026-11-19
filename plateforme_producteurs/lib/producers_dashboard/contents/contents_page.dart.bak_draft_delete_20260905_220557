import 'package:flutter/material.dart';

import 'package:plateforme_producteurs/core/core.dart';
import 'package:plateforme_producteurs/services/producer_service.dart';

import '../upload/upload_page.dart';

class ContentsPage extends StatefulWidget {
  final bool selectionMode;

  const ContentsPage({super.key, this.selectionMode = false});

  @override
  State<ContentsPage> createState() => _ContentsPageState();
}

class _ContentsPageState extends State<ContentsPage> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _drafts = const [];

  @override
  void initState() {
    super.initState();
    _loadDrafts();
  }

  Future<void> _loadDrafts() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final drafts = await ProducerService.instance.getMyContents(
        submissionStatus: 'draft',
      );

      if (!mounted) return;

      setState(() {
        _drafts = drafts;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _openNewContent() async {
    // Lorsque ContentsPage est ouverte depuis le bouton
    // MES BROUILLONS de UploadPage, le formulaire de nouveau
    // contenu existe déjà derrière la fenêtre.
    //
    // On ferme donc simplement la fenêtre au lieu de créer
    // un deuxième UploadPage.
    if (widget.selectionMode) {
      Navigator.of(context).pop();
      return;
    }

    await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const UploadPage()));

    if (!mounted) return;
    await _loadDrafts();
  }

  Future<void> _openDraft(String contentId) async {
    if (widget.selectionMode) {
      Navigator.of(context).pop(contentId);
      return;
    }

    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => UploadPage(contentId: contentId)),
    );

    if (!mounted) return;
    await _loadDrafts();
  }

  String _contentTypeLabel(Map<String, dynamic> draft) {
    switch (draft['type']?.toString()) {
      case 'series':
        return 'SÉRIE';
      case 'movie':
        return 'FILM';
      default:
        return 'CONTENU';
    }
  }

  String _title(Map<String, dynamic> draft) {
    final value = draft['title']?.toString().trim() ?? '';
    return value.isEmpty ? 'Sans titre' : value;
  }

  String _updatedAt(Map<String, dynamic> draft) {
    final raw = draft['updated_at']?.toString();

    if (raw == null || raw.isEmpty) {
      return '';
    }

    final parsed = DateTime.tryParse(raw);

    if (parsed == null) {
      return '';
    }

    final local = parsed.toLocal();

    String two(int value) => value.toString().padLeft(2, '0');

    return '${two(local.day)}/${two(local.month)}/${local.year} '
        'à ${two(local.hour)}:${two(local.minute)}';
  }

  Widget _buildDraftCard(Map<String, dynamic> draft) {
    final id = draft['id']?.toString() ?? '';
    final updatedAt = _updatedAt(draft);
    final type = _contentTypeLabel(draft);

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.paddingMedium,
        vertical: AppTheme.paddingSmall,
      ),
      elevation: 3,
      color: AppTheme.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        onTap: id.isEmpty ? null : () => _openDraft(id),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.paddingMedium),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(
                    AppDecorations.borderRadiusSmall,
                  ),
                ),
                child: Icon(
                  draft['type']?.toString() == 'series'
                      ? Icons.live_tv_rounded
                      : Icons.movie_rounded,
                  color: AppTheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _title(draft),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.textSubtitle.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 8,
                      runSpacing: 5,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          type,
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '•',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                        Text(
                          'Brouillon',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        if (updatedAt.isNotEmpty) ...[
                          Text(
                            '•',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                          Text(
                            'Modifié le $updatedAt',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: id.isEmpty ? null : () => _openDraft(id),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('CONTINUER'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.paddingMedium,
        vertical: 50,
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.cloud_upload_outlined,
              size: 52,
              color: AppTheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun brouillon',
              style: AppTheme.textSubtitle.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Commencez l’envoi d’un nouveau contenu.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppTheme.paddingMedium),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Mes contenus',
                  style: AppTheme.textTitle.copyWith(fontSize: 24),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _openNewContent,
                icon: const Icon(Icons.cloud_upload_rounded),
                label: const Text('NOUVEAU CONTENU'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.paddingMedium,
          ),
          child: Row(
            children: [
              Text(
                'Mes brouillons',
                style: AppTheme.textSubtitle.copyWith(fontSize: 18),
              ),
              if (!_isLoading && _error == null) ...[
                const SizedBox(width: 8),
                Text(
                  '(${_drafts.length})',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ],
              const Spacer(),
              IconButton(
                onPressed: _isLoading ? null : _loadDrafts,
                icon: const Icon(Icons.refresh_rounded),
                color: AppTheme.primary,
                tooltip: 'Actualiser',
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadDrafts,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 70),
                      Icon(
                        Icons.error_outline,
                        size: 46,
                        color: AppTheme.primary,
                      ),
                      const SizedBox(height: 14),
                      Center(
                        child: Text(
                          'Impossible de charger vos brouillons.',
                          style: TextStyle(color: AppTheme.textPrimary),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Center(
                        child: OutlinedButton.icon(
                          onPressed: _loadDrafts,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Réessayer'),
                        ),
                      ),
                    ],
                  )
                : _drafts.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [_buildEmptyState()],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _drafts.length,
                    itemBuilder: (context, index) =>
                        _buildDraftCard(_drafts[index]),
                  ),
          ),
        ),
      ],
    );
  }
}
