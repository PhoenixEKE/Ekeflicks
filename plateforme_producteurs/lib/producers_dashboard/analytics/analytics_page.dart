import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import 'package:plateforme_producteurs/core/core.dart';
import 'package:plateforme_producteurs/gen/app_localizations.dart';
import 'package:plateforme_producteurs/models/producer_analytics.dart';
import 'package:plateforme_producteurs/services/producer_service.dart';
import 'package:plateforme_producteurs/widgets/producer_modal_shell.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  ProducerAnalyticsOverview? _analytics;
  Object? _error;
  bool _loading = true;
  int _days = 30;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final generation = ++_loadGeneration;
    final requestedDays = _days;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await ProducerService.instance.getProducerAnalytics(
        days: requestedDays,
      );

      if (!mounted || generation != _loadGeneration) return;

      setState(() {
        _analytics = result;
        _loading = false;
      });
    } catch (error) {
      if (!mounted || generation != _loadGeneration) return;

      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  Future<void> _changePeriod(int days) async {
    if (_days == days) return;

    _days = days;
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_loading && _analytics == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _analytics == null) {
      return _ErrorState(message: l10n.analyticsLoadError, onRetry: _load);
    }

    final analytics = _analytics;

    if (analytics == null) {
      return _ErrorState(
        message: l10n.analyticsUnavailable,
        onRetry: _load,
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: constraints.maxWidth < 700 ? 16 : 28,
              vertical: 24,
            ),
            children: [
              _Header(
                days: _days,
                loading: _loading,
                onChanged: _changePeriod,
              ),
              if (analytics.demoDataIncluded) ...[
                const SizedBox(height: 16),
                Card(
                  color: Theme.of(context).colorScheme.tertiaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      Localizations.localeOf(context).languageCode == 'en'
                          ? 'Demo analytics are included. These figures are synthetic and are not real audience or remuneration data.'
                          : 'Les statistiques de démonstration sont incluses. Ces chiffres sont fictifs et ne représentent ni une audience réelle ni une rémunération.',
                    ),
                  ),
                ),
              ],
              if (_loading) const LinearProgressIndicator(minHeight: 2),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    l10n.analyticsRefreshError,
                    style: AppTheme.textCaption.copyWith(
                      color: AppTheme.warning,
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              _KpiGrid(analytics: analytics, days: _days),
              const SizedBox(height: 24),
              _EngagementCard(engagement: analytics.engagement),
              const SizedBox(height: 24),
              if (analytics.contents.isEmpty)
                _EmptyState(message: l10n.analyticsNoData)
              else ...[
                _PerformanceChart(contents: analytics.contents),
                const SizedBox(height: 24),
                _ContentRanking(contents: analytics.contents, days: _days),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final int days;
  final bool loading;
  final ValueChanged<int> onChanged;

  const _Header({
    required this.days,
    required this.loading,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 16,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.analyticsTitle,
              style: AppTheme.textTitle.copyWith(fontSize: 28),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.analyticsSubtitle,
              style: AppTheme.textCaption,
            ),
          ],
        ),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 7, label: Text('7 j')),
            ButtonSegment(value: 30, label: Text('30 j')),
            ButtonSegment(value: 90, label: Text('90 j')),
          ],
          selected: {days},
          onSelectionChanged: loading ? null : (selection) {
            if (selection.isNotEmpty) {
              onChanged(selection.first);
            }
          },
        ),
      ],
    );
  }
}

class _KpiGrid extends StatelessWidget {
  final ProducerAnalyticsOverview analytics;
  final int days;

  const _KpiGrid({required this.analytics, required this.days});

  @override
  Widget build(BuildContext context) {
    final contents = analytics.contents;

    final qualifiedViews = contents.fold<int>(
      0,
      (sum, item) => sum + item.qualifiedViews,
    );

    final uniqueViewers = analytics.engagement.uniqueViewers;

    final watchSeconds = contents.fold<double>(
      0,
      (sum, item) => sum + item.watchSeconds,
    );

    final completedViews = contents.fold<int>(
      0,
      (sum, item) => sum + item.completedViews,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final l10n = AppLocalizations.of(context)!;
        final width = constraints.maxWidth;

        final count = width >= 1100
            ? 4
            : width >= 360
            ? 2
            : 1;

        final cardWidth = (width - ((count - 1) * 16)) / count;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _KpiCard(
              width: cardWidth,
              icon: Icons.visibility_rounded,
              label: l10n.analyticsQualifiedViews,
              value: _number(context, qualifiedViews),
            ),
            _KpiCard(
              width: cardWidth,
              icon: Icons.people_alt_rounded,
              label: l10n.analyticsUniqueViewers,
              value: _number(context, uniqueViewers),
            ),
            _KpiCard(
              width: cardWidth,
              icon: Icons.schedule_rounded,
              label: l10n.analyticsWatchTime,
              value: _watchTime(watchSeconds, context),
            ),
            _KpiCard(
              width: cardWidth,
              icon: Icons.task_alt_rounded,
              label: l10n.analyticsCompletedViews,
              value: _number(context, completedViews),
            ),
          ],
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  final double width;
  final IconData icon;
  final String label;
  final String value;

  const _KpiCard({
    required this.width,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppTheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: AppTheme.textTitle.copyWith(fontSize: 24)),
                const SizedBox(height: 4),
                Text(label, style: AppTheme.textCaption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EngagementCard extends StatelessWidget {
  final ProducerAnalyticsEngagement engagement;

  const _EngagementCard({required this.engagement});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppLocalizations.of(context)!.analyticsEngagement, style: AppTheme.textTitle),
          const SizedBox(height: 18),
          Wrap(
            spacing: 28,
            runSpacing: 18,
            children: [
              _MiniMetric(label: AppLocalizations.of(context)!.analyticsLikes, value: _number(context, engagement.likes)),
              _MiniMetric(label: AppLocalizations.of(context)!.analyticsUnlikes, value: _number(context, engagement.unlikes)),
              _MiniMetric(label: AppLocalizations.of(context)!.analyticsNetLikes, value: _number(context, engagement.netLikes)),
              _MiniMetric(
                label: AppLocalizations.of(context)!.analyticsCurrentLikes,
                value: _number(context, engagement.currentLikes),
              ),
              _MiniMetric(
                label: AppLocalizations.of(context)!.analyticsEngagedUsers,
                value: _number(context, engagement.uniqueLikers),
              ),
              _MiniMetric(
                label: AppLocalizations.of(context)!.analyticsEngagementRate,
                value: NumberFormat.percentPattern(Localizations.localeOf(context).toString()).format(engagement.engagementRatePercent / 100),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final String label;
  final String value;

  const _MiniMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: AppTheme.textBodyBold.copyWith(fontSize: 20)),
          const SizedBox(height: 4),
          Text(label, style: AppTheme.textCaption),
        ],
      ),
    );
  }
}

class _PerformanceChart extends StatelessWidget {
  final List<ProducerContentAnalytics> contents;

  const _PerformanceChart({required this.contents});

  @override
  Widget build(BuildContext context) {
    final data = contents.take(10).toList();

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.analyticsQualifiedViewsByContent,
            style: AppTheme.textTitle,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 320,
            child: SfCartesianChart(
              primaryXAxis: CategoryAxis(),
              tooltipBehavior: TooltipBehavior(enable: true),
              series: <CartesianSeries<ProducerContentAnalytics, String>>[
                ColumnSeries<ProducerContentAnalytics, String>(
                  dataSource: data,
                  xValueMapper: (item, _) => _shortTitle(item.title),
                  yValueMapper: (item, _) => item.qualifiedViews,
                  color: AppTheme.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContentRanking extends StatelessWidget {
  final List<ProducerContentAnalytics> contents;
  final int days;

  const _ContentRanking({required this.contents, required this.days});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(22),
            child: Text(
              AppLocalizations.of(context)!.analyticsContentPerformance,
              style: AppTheme.textTitle,
            ),
          ),
          const Divider(height: 1),
          ...contents.asMap().entries.map(
            (entry) => _ContentRow(
              rank: entry.key + 1,
              content: entry.value,
              days: days,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContentRow extends StatelessWidget {
  final int rank;
  final ProducerContentAnalytics content;
  final int days;

  const _ContentRow({
    required this.rank,
    required this.content,
    required this.days,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 1050;
    final title = content.title.isEmpty
        ? l10n.analyticsContentFallback
        : content.title;

    return InkWell(
      onTap: content.contentId.isEmpty ? null : () => _openDetail(context),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 22, vertical: 16),
        child: compact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 36,
                        child: Text('#$rank', style: AppTheme.textBodyBold),
                      ),
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.textBodyBold,
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppTheme.textSecondary,
                      ),
                    ],
                  ),
                  if (content.contentType.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 36, top: 3),
                      child: Text(
                        content.contentType,
                        style: AppTheme.textCaption,
                      ),
                    ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 18,
                    runSpacing: 12,
                    children: [
                      _TableMetric(
                        label: l10n.analyticsViews,
                        value: _number(context, content.qualifiedViews),
                      ),
                      _TableMetric(
                        label: l10n.analyticsWatchTime,
                        value: _watchTime(content.watchSeconds, context),
                      ),
                      _TableMetric(
                        label: l10n.analyticsQualification,
                        value:
                            '${content.qualificationRatePercent.toStringAsFixed(1)} %',
                      ),
                    ],
                  ),
                ],
              )
            : Row(
          children: [
            SizedBox(
              width: 36,
              child: Text('#$rank', style: AppTheme.textBodyBold),
            ),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.textBodyBold,
                  ),
                  if (content.contentType.isNotEmpty)
                    Text(content.contentType, style: AppTheme.textCaption),
                ],
              ),
            ),
            _TableMetric(
              label: l10n.analyticsViews,
              value: _number(context, content.qualifiedViews),
            ),
            _TableMetric(
              label: l10n.analyticsWatchTime,
              value: _watchTime(content.watchSeconds, context),
            ),
            _TableMetric(
              label: l10n.analyticsQualification,
              value: '${content.qualificationRatePercent.toStringAsFixed(1)} %',
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openDetail(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _AnalyticsDetailDialog(
        contentId: content.contentId,
        initialContent: content,
        days: days,
      ),
    );
  }
}

class _TableMetric extends StatelessWidget {
  final String label;
  final String value;

  const _TableMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 115,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(value, style: AppTheme.textBodyBold),
          Text(label, style: AppTheme.textCaption),
        ],
      ),
    );
  }
}

class _AnalyticsDetailDialog extends StatefulWidget {
  final String contentId;
  final ProducerContentAnalytics initialContent;
  final int days;

  const _AnalyticsDetailDialog({
    required this.contentId,
    required this.initialContent,
    required this.days,
  });

  @override
  State<_AnalyticsDetailDialog> createState() => _AnalyticsDetailDialogState();
}

class _AnalyticsDetailDialogState extends State<_AnalyticsDetailDialog> {
  ProducerAnalyticsDetail? _detail;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final detail = await ProducerService.instance.getProducerContentAnalytics(
        widget.contentId,
        days: widget.days,
      );

      if (!mounted) return;

      setState(() {
        _detail = detail;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail;
    final detailTitle = detail?.content.title;
    final title = detailTitle == null || detailTitle.isEmpty
        ? widget.initialContent.title
        : detailTitle;

    return ProducerModalShell(
      title: title,
      maxWidth: 850,
      maxHeight: 720,
      bodyPadding: const EdgeInsets.all(24),
      child: _error != null
          ? _ErrorState(message: _error.toString(), onRetry: _load)
          : detail == null
          ? const Center(child: CircularProgressIndicator())
          : _detailBody(detail),
    );
  }

  Widget _detailBody(ProducerAnalyticsDetail detail) {
    final content = detail.content;

    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      child: Column(
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
            _DetailMetric(
              label: l10n.analyticsStarts,
              value: _number(context, content.playStarts),
            ),
            _DetailMetric(
              label: l10n.analyticsQualifiedViews,
              value: _number(context, content.qualifiedViews),
            ),
            _DetailMetric(
              label: l10n.analyticsUniqueViewers,
              value: _number(context, content.uniqueViewers),
            ),
            _DetailMetric(
              label: l10n.analyticsWatchTime,
              value: _watchTime(content.watchSeconds, context),
            ),
            _DetailMetric(
              label: l10n.analyticsCompletedViews,
              value: _number(context, content.completedViews),
            ),
            _DetailMetric(
              label: l10n.analyticsQualification,
              value: '${content.qualificationRatePercent.toStringAsFixed(1)} %',
            ),
            ],
          ),
          const SizedBox(height: 28),
          _EngagementCard(engagement: detail.engagement),
        ],
      ),
    );
  }
}

class _DetailMetric extends StatelessWidget {
  final String label;
  final String value;

  const _DetailMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: AppTheme.textTitle.copyWith(fontSize: 20)),
          const SizedBox(height: 4),
          Text(label, style: AppTheme.textCaption),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 52,
            color: AppTheme.textSecondary,
          ),
          SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppTheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTheme.textBody,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(AppLocalizations.of(context)!.retry),
            ),
          ],
        ),
      ),
    );
  }
}

String _watchTime(double seconds, BuildContext context) {
  final duration = Duration(seconds: seconds.round());

  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);

  if (hours > 0) {
    return '${hours} h ${minutes} min';
  }

  return '${duration.inMinutes} min';
}

String _number(BuildContext context, num value) =>
    NumberFormat.decimalPattern(Localizations.localeOf(context).toString()).format(value);

String _shortTitle(String title) {
  if (title.length <= 16) {
    return title;
  }

  return '${title.substring(0, 14)}…';
}
