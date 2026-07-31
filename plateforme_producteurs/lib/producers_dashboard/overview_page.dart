import 'package:flutter/material.dart';
import 'package:plateforme_producteurs/gen/app_localizations.dart';
import 'package:plateforme_producteurs/core/core.dart';

class OverviewPage extends StatelessWidget {
  const OverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.all(AppTheme.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.dashboardTitle,
            style: AppTheme.textTitle.copyWith(fontSize: 24),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.9,
              children: [
                StatCard(
                  title: l10n.publishedVideos,
                  value: "12",
                  icon: Icons.video_library,
                  color: const Color(0xFF6C5CE7),
                  trend: Icons.trending_up,
                ),
                StatCard(
                  title: l10n.totalViews, 
                  value: "28K",
                  icon: Icons.remove_red_eye,
                  color: const Color(0xFF00CEFF),
                  trend: Icons.trending_flat,
                ),
                StatCard(
                  title: l10n.estimatedRevenue, 
                  value: "1 250 €",
                  icon: Icons.euro,
                  color: const Color(0xFF00B894),
                  trend: Icons.trending_up,
                ),
                StatCard(
                  title: l10n.pendingItems, 
                  value: "3",
                  icon: Icons.hourglass_top,
                  color: const Color(0xFFFF7675),
                  trend: Icons.trending_down,
                ),
                StatCard(
                  title: l10n.subscribers, 
                  value: "1.2K",
                  icon: Icons.people,
                  color: const Color(0xFFA55EEA),
                  trend: Icons.trending_up,
                ),
                StatCard(
                  title: l10n.engagementRate, 
                  value: "68%",
                  icon: Icons.show_chart,
                  color: const Color(0xFFFD9644),
                  trend: Icons.trending_up,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.recentActivity,
            style: AppTheme.textSubtitle.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView(
              children: [
                ActivityItem(
                  title: l10n.newVideoPublished,
                  subtitle: l10n.videoTitle("Mon Film - Episode 3"),
                  time: l10n.timeAgo(2, "hours"),
                  icon: Icons.upload,
                ),
                ActivityItem(
                  title: l10n.paymentReceived,
                  subtitle: "+ 245,00 €",
                  time: l10n.yesterday,
                  icon: Icons.payment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final IconData trend;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.trend,
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
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppDecorations.borderRadiusSmall),
                  ),
                  child: Icon(icon, color: color),
                ),
                Icon(trend, color: _getTrendColor()),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: AppTheme.textTitle.copyWith(fontSize: 22),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: AppTheme.textCaption.copyWith(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTrendColor() {
    if (trend == Icons.trending_up) return AppTheme.success;
    if (trend == Icons.trending_down) return AppTheme.error;
    return AppTheme.warning;
  }
}

class ActivityItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String time;
  final IconData icon;

  const ActivityItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDecorations.borderRadiusSmall),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primary),
        title: Text(title, style: AppTheme.textBody),
        subtitle: Text(subtitle, style: AppTheme.textCaption),
        trailing: Text(time, style: AppTheme.textCaption),
      ),
    );
  }
}