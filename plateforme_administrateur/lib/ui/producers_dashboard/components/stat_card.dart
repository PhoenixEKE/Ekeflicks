import 'package:flutter/material.dart';
import 'package:plateforme_administrateur/core/core.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final IconData trend;
  final String info;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.trend,
    required this.info,
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
                Icon(trend, color: _getTrendColor(), size: 28),
              ],
            ),
            const SizedBox(height: 16),
            Text(value, style: AppTheme.textTitle.copyWith(fontSize: 22)),
            const SizedBox(height: 4),
            Text(title, style: AppTheme.textBody),
            const SizedBox(height: 8),
            Text(
              info,
              style: AppTheme.textCaption.copyWith(
                color: _getTrendColor(),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTrendColor() {
    if (trend == Icons.trending_up) return AppTheme.success;
    if (trend == Icons.trending_down) return AppTheme.error;
    if (trend == Icons.warning_amber_rounded) return AppTheme.warning;
    return AppTheme.textSecondary;
  }
}
