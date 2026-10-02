import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:plateforme_producteurs/core/core.dart';
import 'package:plateforme_producteurs/gen/app_localizations.dart';
import 'package:plateforme_producteurs/services/producer_service.dart';

import 'content_details_modal.dart';

import '../upload/upload_page.dart';
import 'package:plateforme_producteurs/widgets/producer_modal_shell.dart';

class SeriesTab extends StatefulWidget {
  const SeriesTab({super.key, this.onEditContent});

  final void Function(String contentId)? onEditContent;

  @override
  State<SeriesTab> createState() => _SeriesTabState();
}

class _SeriesTabState extends State<SeriesTab> {
  static const Map<String, String?> _filters = {
    'all': null,
    'drafts': 'draft',
    'pending': 'pending',
    'approved': 'approved',
    'rejected': 'rejected',
  };

  bool _isLoading = true;
  String? _error;
  String _selectedFilter = 'all';
  List<Map<String, dynamic>> _series = const [];
  String? _deletingDraftId;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _loadSeries();
  }

  Future<void> _loadSeries() async {
    if (!mounted) return;
    final generation = ++_loadGeneration;
    final requestedFilter = _selectedFilter;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final series = await ProducerService.instance.getMyContents(
        type: 'series',
        submissionStatus: _filters[requestedFilter],
      );

      if (!mounted || generation != _loadGeneration) return;

      setState(() {
        _series = series;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted || generation != _loadGeneration) return;

      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteDraft(Map<String, dynamic> series) async {
    if (_deletingDraftId != null || _status(series) != 'draft') {
      return;
    }

    final id = series['id']?.toString().trim() ?? '';
    if (id.isEmpty) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return ProducerModalShell(
          title: AppLocalizations.of(context)!.deleteDraftQuestion,
          maxWidth: 560,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(AppLocalizations.of(context)!.cancel.toUpperCase()),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              icon: const Icon(Icons.delete_outline),
              label: Text(AppLocalizations.of(context)!.deleteDraftConfirm.toUpperCase()),
            ),
          ],
          child: Text(
            AppLocalizations.of(context)!.deleteDraftSeriesBody(_title(series)),
          ),
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _deletingDraftId = id;
    });

    try {
      await ProducerService.instance.deleteDraft(id);

      if (!mounted) {
        return;
      }

      setState(() {
        _series = _series
            .where((item) => item['id']?.toString() != id)
            .toList();
        _deletingDraftId = null;
      });

      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return ProducerModalShell(
            title: AppLocalizations.of(context)!.draftDeleted,
            maxWidth: 520,
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('OK'),
              ),
            ],
            child: Text(AppLocalizations.of(context)!.draftDeletedSuccess),
          );
        },
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _deletingDraftId = null;
      });

      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return ProducerModalShell(
            title: AppLocalizations.of(context)!.deleteFailed,
            maxWidth: 560,
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('OK'),
              ),
            ],
            child: Text(error.toString().replaceFirst('Exception: ', '')),
          );
        },
      );
    }
  }

  Future<void> _openContent(Map<String, dynamic> content) async {
    final id = content['id']?.toString().trim() ?? '';
    final status = _status(content);

    if (id.isEmpty) return;

    // Brouillon / refus :
    // ouverture dans l'onglet Dépôt du Dashboard.
    if (status == 'draft' || status == 'rejected') {
      final handler = widget.onEditContent;

      if (handler != null) {
        handler(id);
        return;
      }

      await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => UploadPage(contentId: id)),
      );

      if (!mounted) return;
      await _loadSeries();
      return;
    }

    // Pending / approved : lecture seule avec les vraies
    // données détaillées retournées par l'API.
    try {
      final detail = await ProducerService.instance.getContent(id);

      if (!mounted) return;

      await Navigator.of(context).push<void>(
        MaterialPageRoute(builder: (_) => ContentDetailsModal(content: detail)),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible de charger le contenu : $error')),
      );
    }
  }

  String _status(Map<String, dynamic> series) {
    return series['producer_submission_status']?.toString().trim().toLowerCase() ?? 'draft';
  }

  String _title(Map<String, dynamic> series) {
    final display = series['display_text'];
    final title = (display is Map ? display['title'] : null)?.toString().trim()
            ?? series['title']?.toString().trim()
            ?? '';
    return title.isEmpty
        ? AppLocalizations.of(context)!.analyticsContentFallback
        : title;
  }

  String _statusLabel(String status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case 'draft': return l10n.contentStatusDraft;
      case 'pending': return l10n.contentStatusPending;
      case 'approved': return l10n.contentStatusApproved;
      case 'rejected': return l10n.contentStatusRejected;
      default: return l10n.contentStatusUnknown;
    }
  }

  String _filterLabel(String key) {
    final l10n = AppLocalizations.of(context)!;
    switch (key) {
      case 'all': return l10n.filterAll;
      case 'drafts': return l10n.filterDrafts;
      case 'pending': return l10n.filterPending;
      case 'approved': return l10n.filterApproved;
      case 'rejected': return l10n.filterRejected;
      default: return key;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'draft':
        return AppTheme.disabled;
      case 'pending':
        return AppTheme.warning;
      case 'approved':
        return AppTheme.success;
      case 'rejected':
        return AppTheme.error;
      default:
        return AppTheme.disabled;
    }
  }

  String _updatedAt(Map<String, dynamic> series) {
    final raw = series['updated_at']?.toString();

    if (raw == null || raw.isEmpty) {
      return '';
    }

    final parsed = DateTime.tryParse(raw);

    if (parsed == null) {
      return '';
    }

    final local = parsed.toLocal();
    final locale = AppLocalizations.of(context)!.localeName;
    final formatted = DateFormat.yMd(locale).add_Hm().format(local);
    return AppLocalizations.of(context)!.contentUpdatedOn(formatted);
  }

  String? _draftDeletionWarning(Map<String, dynamic> content) {
    final raw = content['updated_at']?.toString().trim() ?? '';

    if (raw.isEmpty) {
      return null;
    }

    final parsed = DateTime.tryParse(raw);

    if (parsed == null) {
      return null;
    }

    final age = DateTime.now().toUtc().difference(parsed.toUtc()).inDays;

    if (age < 90) {
      return null;
    }

    final l10n = AppLocalizations.of(context)!;
    if (age >= 120) return l10n.draftDeleteSoon;
    return l10n.draftDeleteWarning(120 - age);
  }

  Widget _buildStatusBadge(String status) {
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.paddingMedium),
      child: Row(
        children: _filters.keys.map((key) {
          final selected = key == _selectedFilter;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(_filterLabel(key)),
              selected: selected,
              onSelected: (_) {
                if (selected) return;

                setState(() {
                  _selectedFilter = key;
                });

                _loadSeries();
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSeriesCard(Map<String, dynamic> series) {
    final status = _status(series);
    final updatedAt = _updatedAt(series);
    final deletionWarning = status == 'draft'
        ? _draftDeletionWarning(series)
        : null;
    final editable = status == 'draft' || status == 'rejected';

    final reviewReason = series['review_reason']?.toString().trim() ?? '';

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
        onTap: () => _openContent(series),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.paddingMedium),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 82,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(
                    AppTheme.borderRadiusSmall,
                  ),
                ),
                child: Icon(
                  Icons.live_tv_rounded,
                  color: AppTheme.primary,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            _title(series),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.textSubtitle.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        _buildStatusBadge(status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.seriesTab.toUpperCase(),
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (updatedAt.isNotEmpty)
                          Text(
                            AppLocalizations.of(context)!.contentUpdatedOn(updatedAt),
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                    if (deletionWarning != null) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 17,
                            color: AppTheme.warning,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              deletionWarning,
                              style: TextStyle(
                                color: AppTheme.warning,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (status == 'pending') ...[
                      const SizedBox(height: 10),
                      Text(
                        AppLocalizations.of(context)!.contentPendingReviewSeries,
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    if (status == 'approved') ...[
                      const SizedBox(height: 10),
                      Text(
                        AppLocalizations.of(context)!.contentApprovedSeries,
                        style: TextStyle(color: AppTheme.success, fontSize: 13),
                      ),
                    ],
                    if (status == 'rejected') ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.error.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(
                            AppTheme.borderRadiusSmall,
                          ),
                        ),
                        child: Text(
                          reviewReason.isEmpty
                              ? AppLocalizations.of(context)!.contentNeedsCorrection
                              : 'Motif du refus : $reviewReason',
                          style: TextStyle(color: AppTheme.error, fontSize: 13),
                        ),
                      ),
                    ],
                    if (editable) ...[
                      const SizedBox(height: 14),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.end,
                          children: [
                            if (status == 'draft')
                              OutlinedButton.icon(
                                onPressed: _deletingDraftId != null
                                    ? null
                                    : () => _deleteDraft(series),
                                icon:
                                    _deletingDraftId == series['id']?.toString()
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.delete_outline,
                                        size: 18,
                                      ),
                                label: Text(AppLocalizations.of(context)!.deleteDraftConfirm.toUpperCase()),
                              ),
                            ElevatedButton.icon(
                              onPressed: _deletingDraftId != null
                                  ? null
                                  : () => _openContent(series),
                              icon: Icon(
                                status == 'rejected'
                                    ? Icons.build_outlined
                                    : Icons.edit_outlined,
                                size: 18,
                              ),
                              label: Text(
                                status == 'rejected'
                                    ? AppLocalizations.of(context)!.correctContent.toUpperCase()
                                    : AppLocalizations.of(context)!.continueEditing.toUpperCase(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final filter = _selectedFilter;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.live_tv_outlined, size: 54, color: AppTheme.primary),
            const SizedBox(height: 16),
            Text(
              filter == 'all' ? AppLocalizations.of(context)!.contentNoSeries : '${AppLocalizations.of(context)!.contentNoSeries} — ${_filterLabel(filter)}',
              textAlign: TextAlign.center,
              style: AppTheme.textSubtitle.copyWith(fontSize: 18),
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
                  AppLocalizations.of(context)!.seriesPageTitle,
                  style: AppTheme.textTitle.copyWith(fontSize: 24),
                ),
              ),
              IconButton(
                onPressed: _isLoading ? null : _loadSeries,
                icon: const Icon(Icons.refresh_rounded),
                color: AppTheme.primary,
                tooltip: AppLocalizations.of(context)!.refresh,
              ),
            ],
          ),
        ),
        _buildFilters(),
        if (_isLoading && _series.isNotEmpty)
          const LinearProgressIndicator(minHeight: 2),
        if (_error != null && _series.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              AppLocalizations.of(context)!.dashboardPartialLoadError,
              style: AppTheme.textCaption.copyWith(color: AppTheme.warning),
            ),
          ),
        const SizedBox(height: 8),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadSeries,
            child: _isLoading && _series.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _error != null && _series.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 70),
                      Icon(
                        Icons.error_outline,
                        size: 46,
                        color: AppTheme.error,
                      ),
                      const SizedBox(height: 14),
                      Center(
                        child: Text(
                          AppLocalizations.of(context)!.contentLoadingSeriesError,
                          style: TextStyle(color: AppTheme.textPrimary),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Center(
                        child: OutlinedButton.icon(
                          onPressed: _loadSeries,
                          icon: const Icon(Icons.refresh),
                          label: Text(AppLocalizations.of(context)!.retry),
                        ),
                      ),
                    ],
                  )
                : _series.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(height: 300, child: _buildEmptyState()),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _series.length,
                    itemBuilder: (context, index) {
                      return _buildSeriesCard(_series[index]);
                    },
                  ),
          ),
        ),
      ],
    );
  }
}
