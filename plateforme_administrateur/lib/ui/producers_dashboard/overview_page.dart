import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:plateforme_producteurs/gen/app_localizations.dart';
import 'package:plateforme_producteurs/core/core.dart';

import 'components/stat_card.dart';
import 'components/activity_item.dart';

class OverviewPage extends StatelessWidget {
  const OverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.adminDashboardTitle, style: AppTheme.textTitle.copyWith(fontSize: 24)),
          const SizedBox(height: 20),
          
          // Stats Cards Grid
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.2,
            children: [
              StatCard(
                title: l10n.totalUsers,
                value: "2.4K",
                icon: Icons.people_outline,
                color: const Color(0xFF6C5CE7),
                trend: Icons.trending_up,
                info: "+12% ce mois",
              ),
              StatCard(
                title: l10n.activeProducers, 
                value: "156",
                icon: Icons.business_rounded,
                color: const Color(0xFF00CEFF),
                trend: Icons.trending_up,
                info: "+5 nouveaux",
              ),
              StatCard(
                title: l10n.totalVideos,
                value: "1,248",
                icon: Icons.video_library,
                color: const Color(0xFF9C27B0),
                trend: Icons.trending_up,
                info: "+32 ce mois",
              ),
              StatCard(
                title: l10n.publishedVideos, 
                value: "1,105",
                icon: Icons.check_circle,
                color: const Color(0xFF4CAF50),
                trend: Icons.trending_up,
                info: "+28 ce mois",
              ),
              StatCard(
                title: l10n.videosToReview, 
                value: "23",
                icon: Icons.video_library,
                color: const Color(0xFFFF7675),
                trend: Icons.warning_amber_rounded,
                info: "En attente",
              ),
              StatCard(
                title: l10n.monthlyRevenue, 
                value: "24K €",
                icon: Icons.euro_symbol_rounded,
                color: const Color(0xFF00B894),
                trend: Icons.trending_up,
                info: "+8% vs mois dernier",
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Recent Activity in Card
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.recentActivity, style: AppTheme.textSubtitle.copyWith(fontSize: 18)),
                  const SizedBox(height: 10),
                  const ActivityItem(
                    title: "Nouvelle vidéo soumise",
                    subtitle: "Documentaire: 'Les secrets de l'océan' par MarineProd",
                    time: "Il y a 15 min",
                    icon: Icons.video_camera_back_rounded,
                    status: "À revoir",
                    statusColor: AppTheme.warning,
                  ),
                  const ActivityItem(
                    title: "Nouvelle vidéo soumise",
                    subtitle: "Film: 'Le dernier voyage' par CinéCréa",
                    time: "Il y a 1h",
                    icon: Icons.video_camera_back_rounded,
                    status: "Publiée",
                    statusColor: AppTheme.warning,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChartData {
  final String x;
  final double y;

  ChartData(this.x, this.y);
}