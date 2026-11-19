import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:plateforme_producteurs/core/core.dart';
import 'package:plateforme_producteurs/gen/app_localizations.dart';
import 'package:plateforme_producteurs/models/producer_analytics.dart';
import 'package:plateforme_producteurs/models/producer_notification.dart';
import 'package:plateforme_producteurs/services/producer_service.dart';

class OverviewPage extends StatefulWidget {
  const OverviewPage({
    super.key,
    this.notifications = const [],
    this.onRefreshNotifications,
  });

  final List<ProducerNotification> notifications;
  final Future<void> Function()? onRefreshNotifications;

  @override
  State<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage> {
  _DashboardSnapshot? _snapshot;
  Object? _error;
  bool _loading = true;

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
      final results = await Future.wait<Object>([
        ProducerService.instance.getProducerDashboard(),
        ProducerService.instance.getProducerAnalytics(days: 30),
      ]);
      final snapshot = _DashboardSnapshot.from(
        results[0] as Map<String, dynamic>,
        results[1] as ProducerAnalyticsOverview,
      );
      if (!mounted) return;
      setState(() {
        _snapshot = snapshot;
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

  Future<void> _refresh() async {
    await Future.wait([
      _load(),
      if (widget.onRefreshNotifications != null)
        widget.onRefreshNotifications!(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_loading && _snapshot == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _snapshot == null) {
      return _LoadError(message: l10n.dashboardLoadError, onRetry: _refresh);
    }

    final snapshot = _snapshot;
    if (snapshot == null) {
      return _LoadError(message: l10n.dashboardLoadError, onRetry: _refresh);
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 1100
              ? 3
              : constraints.maxWidth >= 650
              ? 3
              : 2;
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(
              constraints.maxWidth < 650 ? AppTheme.paddingMedium : 28,
            ),
            children: [
              Text(
                l10n.dashboardTitle,
                style: AppTheme.textTitle.copyWith(fontSize: 26),
              ),
              const SizedBox(height: 6),
              Text(l10n.dashboardLast30Days, style: AppTheme.textCaption),
              const SizedBox(height: 18),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    l10n.dashboardPartialLoadError,
                    style: AppTheme.textCaption.copyWith(
                      color: AppTheme.warning,
                    ),
                  ),
                ),
              if (_loading) const LinearProgressIndicator(minHeight: 2),
              GridView.count(
                crossAxisCount: columns,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: constraints.maxWidth < 380 ? 1.12 : 1.25,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  StatCard(
                    title: l10n.dashboardApprovedContents,
                    value: _formatCount(snapshot.approvedContents),
                    icon: Icons.video_library_outlined,
                    color: const Color(0xFF6C5CE7),
                  ),
                  StatCard(
                    title: l10n.dashboardPendingReview,
                    value: _formatCount(snapshot.pendingContents),
                    icon: Icons.hourglass_top_rounded,
                    color: const Color(0xFFFF7675),
                  ),
                  StatCard(
                    title: l10n.dashboardDraftContents,
                    value: _formatCount(snapshot.draftContents),
                    icon: Icons.edit_note_rounded,
                    color: const Color(0xFFFD9644),
                  ),
                  StatCard(
                    title: l10n.dashboardEligibleBalance,
                    value: snapshot.eligibleBalanceEur == null
                        ? '—'
                        : NumberFormat.currency(
                            locale: Localizations.localeOf(context).languageCode,
                            name: 'EUR',
                            symbol: '€',
                          ).format(snapshot.eligibleBalanceEur),
                    icon: Icons.account_balance_wallet_outlined,
                    color: const Color(0xFF00B894),
                  ),
                  StatCard(
                    title: l10n.dashboardQualifiedViews,
                    value: _formatCount(snapshot.qualifiedViews),
                    icon: Icons.visibility_outlined,
                    color: const Color(0xFF00CEFF),
                  ),
                  StatCard(
                    title: l10n.dashboardUniqueViewers,
                    value: _formatCount(snapshot.uniqueViewers),
                    icon: Icons.people_outline_rounded,
                    color: const Color(0xFFA55EEA),
                  ),
                  StatCard(
                    title: l10n.dashboardEngagementRate,
                    value: '${snapshot.engagementRate.toStringAsFixed(1)}%',
                    icon: Icons.show_chart_rounded,
                    color: const Color(0xFF00B894),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              Text(
                l10n.recentActivity,
                style: AppTheme.textSubtitle.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 10),
              if (widget.notifications.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 22),
                  child: Text(
                    l10n.dashboardNoRecentActivity,
                    style: AppTheme.textCaption,
                  ),
                )
              else
                for (final notification in widget.notifications.take(5))
                  ActivityItem(notification: notification),
            ],
          );
        },
      ),
    );
  }

  String _formatCount(int value) => NumberFormat.decimalPattern(
    Localizations.localeOf(context).languageCode,
  ).format(value);
}

class _DashboardSnapshot {
  final int approvedContents;
  final int pendingContents;
  final int draftContents;
  final int qualifiedViews;
  final int uniqueViewers;
  final double engagementRate;
  final double? eligibleBalanceEur;

  const _DashboardSnapshot({
    required this.approvedContents,
    required this.pendingContents,
    required this.draftContents,
    required this.qualifiedViews,
    required this.uniqueViewers,
    required this.engagementRate,
    required this.eligibleBalanceEur,
  });

  factory _DashboardSnapshot.from(
    Map<String, dynamic> dashboard,
    ProducerAnalyticsOverview analytics,
  ) {
    final rawStatuses = dashboard['content_by_submission_status'];
    final statuses = rawStatuses is Map
        ? Map<String, dynamic>.from(rawStatuses)
        : const <String, dynamic>{};
    int statusCount(String name) =>
        int.tryParse(statuses[name]?.toString() ?? '') ?? 0;

    return _DashboardSnapshot(
      approvedContents: statusCount('approved'),
      pendingContents: statusCount('pending'),
      draftContents: statusCount('draft'),
      qualifiedViews: analytics.contents.fold<int>(
        0,
        (sum, content) => sum + content.qualifiedViews,
      ),
      uniqueViewers: analytics.engagement.uniqueViewers,
      engagementRate: analytics.engagement.engagementRatePercent,
      eligibleBalanceEur: null,
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDecorations.borderRadiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(
                  AppDecorations.borderRadiusSmall,
                ),
              ),
              child: Icon(icon, color: color),
            ),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.textTitle.copyWith(fontSize: 22),
            ),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.textCaption.copyWith(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class ActivityItem extends StatelessWidget {
  const ActivityItem({super.key, required this.notification});

  final ProducerNotification notification;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final time = notification.createdAt == null
        ? ''
        : DateFormat.Md(locale)
              .add_Hm()
              .format(notification.createdAt!.toLocal());
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDecorations.borderRadiusSmall),
      ),
      child: ListTile(
        leading: Icon(
          notification.isRead
              ? Icons.notifications_none_rounded
              : Icons.notifications_active_outlined,
          color: notification.isRead
              ? AppTheme.textSecondary
              : AppTheme.primary,
        ),
        title: Text(
          notification.title.isEmpty ? notification.type : notification.title,
          style: AppTheme.textBody.copyWith(
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.w700,
          ),
        ),
        subtitle: notification.message.isEmpty
            ? null
            : Text(notification.message, style: AppTheme.textCaption),
        trailing: time.isEmpty
            ? null
            : Text(time, style: AppTheme.textCaption),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 42),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}
