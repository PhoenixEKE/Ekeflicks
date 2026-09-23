import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import 'package:plateforme_producteurs/core/core.dart';
import 'package:plateforme_producteurs/models/producer_analytics.dart';
import 'package:plateforme_producteurs/services/producer_service.dart';

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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await ProducerService.instance.getProducerAnalytics(
        days: _days,
      );

      if (!mounted) return;

      setState(() {
        _analytics = result;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

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
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _ErrorState(message: _error.toString(), onRetry: _load);
    }

    final analytics = _analytics;

    if (analytics == null) {
      return _ErrorState(
        message: 'Données Analytics indisponibles.',
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
              _Header(days: _days, onChanged: _changePeriod),
              const SizedBox(height: 24),
              _KpiGrid(analytics: analytics),
              const SizedBox(height: 24),
              _EngagementCard(engagement: analytics.engagement),
              const SizedBox(height: 24),
              if (analytics.contents.isEmpty)
                const _EmptyState()
              else ...[
                _PerformanceChart(contents: analytics.contents),
                const SizedBox(height: 24),
                _ContentRanking(contents: analytics.contents),
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
  final ValueChanged<int> onChanged;

  const _Header({required this.days, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 16,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Analytics', style: AppTheme.textTitle.copyWith(fontSize: 28)),
            const SizedBox(height: 6),
            Text(
              'Performance réelle de vos contenus',
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
          onSelectionChanged: (selection) {
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

  const _KpiGrid({required this.analytics});

  @override
  Widget build(BuildContext context) {
    final contents = analytics.contents;

    final qualifiedViews = contents.fold<int>(
      0,
      (sum, item) => sum + item.qualifiedViews,
    );

    final uniqueViewers = contents.fold<int>(
      0,
      (sum, item) => sum + item.uniqueViewers,
    );

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
        final width = constraints.maxWidth;

        final count = width >= 1100
            ? 4
            : width >= 650
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
              label: 'Vues qualifiées',
              value: '$qualifiedViews',
            ),
            _KpiCard(
              width: cardWidth,
              icon: Icons.people_alt_rounded,
              label: 'Spectateurs uniques',
              value: '$uniqueViewers',
            ),
            _KpiCard(
              width: cardWidth,
              icon: Icons.schedule_rounded,
              label: 'Temps de visionnage',
              value: _watchTime(watchSeconds),
            ),
            _KpiCard(
              width: cardWidth,
              icon: Icons.task_alt_rounded,
              label: 'Lectures terminées',
              value: '$completedViews',
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
          Text('Engagement', style: AppTheme.textTitle),
          const SizedBox(height: 18),
          Wrap(
            spacing: 28,
            runSpacing: 18,
            children: [
              _MiniMetric(label: 'Likes', value: '${engagement.likes}'),
              _MiniMetric(label: 'Unlikes', value: '${engagement.unlikes}'),
              _MiniMetric(label: 'Net likes', value: '${engagement.netLikes}'),
              _MiniMetric(
                label: 'Likes actuels',
                value: '${engagement.currentLikes}',
              ),
              _MiniMetric(
                label: 'Utilisateurs engagés',
                value: '${engagement.uniqueLikers}',
              ),
              _MiniMetric(
                label: 'Taux d’engagement',
                value:
                    '${engagement.engagementRatePercent.toStringAsFixed(1)} %',
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
          Text('Vues qualifiées par contenu', style: AppTheme.textTitle),
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

  const _ContentRanking({required this.contents});

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
            child: Text('Performance des contenus', style: AppTheme.textTitle),
          ),
          const Divider(height: 1),
          ...contents.asMap().entries.map(
            (entry) => _ContentRow(rank: entry.key + 1, content: entry.value),
          ),
        ],
      ),
    );
  }
}

class _ContentRow extends StatelessWidget {
  final int rank;
  final ProducerContentAnalytics content;

  const _ContentRow({required this.rank, required this.content});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: content.contentId.isEmpty ? null : () => _openDetail(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        child: Row(
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
                    content.title.isEmpty ? 'Contenu' : content.title,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.textBodyBold,
                  ),
                  if (content.contentType.isNotEmpty)
                    Text(content.contentType, style: AppTheme.textCaption),
                ],
              ),
            ),
            _TableMetric(label: 'Vues', value: '${content.qualifiedViews}'),
            _TableMetric(
              label: 'Watch time',
              value: _watchTime(content.watchSeconds),
            ),
            _TableMetric(
              label: 'Qualification',
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

  const _AnalyticsDetailDialog({
    required this.contentId,
    required this.initialContent,
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

    return Dialog(
      backgroundColor: AppTheme.cardBackground,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 850, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _error != null
              ? _ErrorState(message: _error.toString(), onRetry: _load)
              : detail == null
              ? const Center(child: CircularProgressIndicator())
              : _detailBody(detail),
        ),
      ),
    );
  }

  Widget _detailBody(ProducerAnalyticsDetail detail) {
    final content = detail.content;

    return ListView(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                content.title.isEmpty
                    ? widget.initialContent.title
                    : content.title,
                style: AppTheme.textTitle.copyWith(fontSize: 24),
              ),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _DetailMetric(label: 'Démarrages', value: '${content.playStarts}'),
            _DetailMetric(
              label: 'Vues qualifiées',
              value: '${content.qualifiedViews}',
            ),
            _DetailMetric(
              label: 'Spectateurs uniques',
              value: '${content.uniqueViewers}',
            ),
            _DetailMetric(
              label: 'Watch time',
              value: _watchTime(content.watchSeconds),
            ),
            _DetailMetric(
              label: 'Terminées',
              value: '${content.completedViews}',
            ),
            _DetailMetric(
              label: 'Qualification',
              value: '${content.qualificationRatePercent.toStringAsFixed(1)} %',
            ),
          ],
        ),
        const SizedBox(height: 28),
        _EngagementCard(engagement: detail.engagement),
      ],
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
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 52,
            color: AppTheme.textSecondary,
          ),
          SizedBox(height: 16),
          Text(
            'Aucune donnée Analytics disponible '
            'pour cette période.',
            textAlign: TextAlign.center,
          ),
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
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

String _watchTime(double seconds) {
  final duration = Duration(seconds: seconds.round());

  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);

  if (hours > 0) {
    return '${hours}h ${minutes}min';
  }

  return '${duration.inMinutes} min';
}

String _shortTitle(String title) {
  if (title.length <= 16) {
    return title;
  }

  return '${title.substring(0, 14)}…';
}
