*import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:plateforme_administrateur/core/core.dart';
import 'package:plateforme_administrateur/gen/app_localizations.dart';

class StreamingStatisticsPage extends StatefulWidget {
  const StreamingStatisticsPage({super.key});

  @override
  State<StreamingStatisticsPage> createState() => _StreamingStatisticsPageState();
}

class _StreamingStatisticsPageState extends State<StreamingStatisticsPage> {
  String _selectedTimeRange = 'monthly';
  String _selectedContentType = 'all';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.streaming_analytics,
              style: AppTheme.textTitle.copyWith(fontSize: 24),
            ),
            const SizedBox(height: 16),
            _buildFiltersRow(l10n),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                children: [
                  _buildKpiRow(l10n),
                  const SizedBox(height: 24),
                  _buildChartSection(l10n.user_growth, _buildUserGrowthChart()),
                  const SizedBox(height: 24),
                  _buildChartSection(l10n.video_status_distribution, _buildVideoStatusChart()),
                  const SizedBox(height: 24),
                  _buildChartSection(l10n.avg_watch_time, _buildAvgWatchTimeChart()),
                  const SizedBox(height: 24),
                  _buildChartSection(l10n.popular_genres, _buildPopularGenresChart()),
                  const SizedBox(height: 24),
                  _buildChartSection(l10n.subscriber_retention, _buildRetentionChart()),
                  const SizedBox(height: 24),
                  _buildChartSection(l10n.monthly_revenue, _buildRevenueChart()),
                  const SizedBox(height: 24),
                  _buildChartSection(l10n.devices_used, _buildDevicesChart()),
                  const SizedBox(height: 24),
                  _buildChartSection(l10n.viewership_trends, _buildViewershipChart()),
                  const SizedBox(height: 24),
                  _buildChartSection(l10n.content_performance, _buildContentPerformanceChart()),
                  const SizedBox(height: 24),
                  _buildChartSection(l10n.user_engagement, _buildEngagementChart()),
                  const SizedBox(height: 24),
                  _buildChartSection(l10n.geo_distribution, _buildGeoChart()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersRow(AppLocalizations l10n) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedTimeRange,
                items: [
                  DropdownMenuItem(value: 'daily', child: Text(l10n.daily)),
                  DropdownMenuItem(value: 'weekly', child: Text(l10n.weekly)),
                  DropdownMenuItem(value: 'monthly', child: Text(l10n.monthly)),
                  DropdownMenuItem(value: 'yearly', child: Text(l10n.yearly)),
                ],
                onChanged: (value) => setState(() => _selectedTimeRange = value!),
                decoration: InputDecoration(
                  labelText: l10n.time_period,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedContentType,
                items: [
                  DropdownMenuItem(value: 'all', child: Text(l10n.all_content)),
                  DropdownMenuItem(value: 'movies', child: Text(l10n.movies)),
                  DropdownMenuItem(value: 'series', child: Text(l10n.series)),
                  DropdownMenuItem(value: 'documentaries', child: Text(l10n.documentaries)),
                ],
                onChanged: (value) => setState(() => _selectedContentType = value!),
                decoration: InputDecoration(
                  labelText: l10n.content_type,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          children: [
            FilterChip(
              label: Text(l10n.new_users),
              selected: false,
              onSelected: (b) {},
            ),
            FilterChip(
              label: Text(l10n.returning_users),
              selected: false,
              onSelected: (b) {},
            ),
            FilterChip(
              label: Text(l10n.premium),
              selected: false,
              onSelected: (b) {},
            ),
            FilterChip(
              label: Text(l10n.trial),
              selected: false,
              onSelected: (b) {},
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKpiRow(AppLocalizations l10n) {
    return GridView.count(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildKpiCard(
          l10n.total_viewers,
          '12.4M',
          '+8.2%',
          Icons.people_alt,
          Colors.blue,
        ),
        _buildKpiCard(
          l10n.watch_time,
          '4.7B min',
          '+12.5%',
          Icons.timer,
          Colors.green,
        ),
        _buildKpiCard(
          l10n.avg_session,
          '42 min',
          '+3.1%',
          Icons.timelapse,
          Colors.orange,
        ),
        _buildKpiCard(
          l10n.revenue,
          '\$86.2M',
          '+5.7%',
          Icons.attach_money,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildKpiCard(String title, String value, String growth, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: growth.startsWith('+') ? Colors.green[100] : Colors.red[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    growth,
                    style: TextStyle(
                      color: growth.startsWith('+') ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTheme.textBody.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: AppTheme.textTitle.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartSection(String title, Widget chart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTheme.textTitle.copyWith(fontSize: 18),
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(height: 300, child: chart),
          ),
        ),
      ],
    );
  }

  Widget _buildUserGrowthChart() {
    return SfCartesianChart(
      primaryXAxis: CategoryAxis(),
      legend: Legend(isVisible: true),
      tooltipBehavior: TooltipBehavior(enable: true),
      series: <CartesianSeries<ChartData, String>>[
        LineSeries<ChartData, String>(
          name: 'Nouveaux utilisateurs',
          dataSource: [
            ChartData('Jan', 12500),
            ChartData('Feb', 14300),
            ChartData('Mar', 18200),
            ChartData('Apr', 16500),
            ChartData('May', 21000),
            ChartData('Jun', 24500),
          ],
          xValueMapper: (ChartData data, _) => data.x,
          yValueMapper: (ChartData data, _) => data.y,
          color: Colors.blue,
          markerSettings: MarkerSettings(isVisible: true),
        ),
      ],
    );
  }

  Widget _buildVideoStatusChart() {
    return SfCircularChart(
      legend: Legend(isVisible: true),
      series: <CircularSeries<StatusData, String>>[
        PieSeries<StatusData, String>(
          dataSource: [
            StatusData('Publié', 65),
            StatusData('En attente', 15),
            StatusData('Brouillon', 10),
            StatusData('Rejeté', 5),
            StatusData('Archivé', 5),
          ],
          xValueMapper: (StatusData data, _) => data.status,
          yValueMapper: (StatusData data, _) => data.percentage,
          dataLabelSettings: DataLabelSettings(isVisible: true),
        ),
      ],
    );
  }

  Widget _buildAvgWatchTimeChart() {
    return SfCartesianChart(
      primaryXAxis: CategoryAxis(),
      primaryYAxis: NumericAxis(title: AxisTitle(text: 'Minutes')),
      series: <CartesianSeries<WatchTimeData, String>>[
        BarSeries<WatchTimeData, String>(
          name: 'Temps moyen',
          dataSource: [
            WatchTimeData('Films', 48),
            WatchTimeData('Séries', 32),
            WatchTimeData('Documentaires', 28),
            WatchTimeData('Court-métrages', 12),
            WatchTimeData('Émissions', 22),
          ],
          xValueMapper: (WatchTimeData data, _) => data.category,
          yValueMapper: (WatchTimeData data, _) => data.minutes,
          color: Colors.green,
          dataLabelSettings: DataLabelSettings(isVisible: true),
        ),
      ],
    );
  }

  
  Widget _buildPopularGenresChart() {
    return SfCartesianChart(
      primaryXAxis: CategoryAxis(), // ✅ Les genres
      primaryYAxis: NumericAxis(),  // ✅ Le nombre de vues
      series: <CartesianSeries<GenreData, String>>[
        BarSeries<GenreData, String>(
          name: 'Vues (millions)',
          dataSource: [
            GenreData('Drame', 12.4),
            GenreData('Comédie', 9.8),
            GenreData('Action', 8.5),
            GenreData('Science-fiction', 7.2),
            GenreData('Documentaire', 6.7),
          ],
          xValueMapper: (GenreData data, _) => data.genre, // String → Catégorie
          yValueMapper: (GenreData data, _) => data.views, // double → Valeur
          color: Colors.purple,
          dataLabelSettings: const DataLabelSettings(isVisible: true),
        ),
      ],
    );
  }


  Widget _buildRetentionChart() {
    return SfCartesianChart(
      primaryXAxis: CategoryAxis(),
      legend: Legend(isVisible: true),
      tooltipBehavior: TooltipBehavior(enable: true),
      series: <CartesianSeries<RetentionData, String>>[
        LineSeries<RetentionData, String>(
          name: 'Taux de rétention',
          dataSource: [
            RetentionData('Sem 1', 85),
            RetentionData('Sem 2', 72),
            RetentionData('Sem 3', 65),
            RetentionData('Sem 4', 58),
            RetentionData('Sem 5', 52),
            RetentionData('Sem 6', 48),
          ],
          xValueMapper: (RetentionData data, _) => data.week,
          yValueMapper: (RetentionData data, _) => data.rate,
          color: Colors.orange,
          markerSettings: MarkerSettings(isVisible: true),
        ),
      ],
    );
  }

  Widget _buildRevenueChart() {
    return SfCartesianChart(
      primaryXAxis: CategoryAxis(),
      primaryYAxis: NumericAxis(title: AxisTitle(text: 'USD (k)')),
      series: <CartesianSeries<RevenueData, String>>[
        ColumnSeries<RevenueData, String>(
          name: 'Revenus',
          dataSource: [
            RevenueData('Jan', 125),
            RevenueData('Feb', 143),
            RevenueData('Mar', 182),
            RevenueData('Apr', 165),
            RevenueData('May', 210),
            RevenueData('Jun', 245),
          ],
          xValueMapper: (RevenueData data, _) => data.month,
          yValueMapper: (RevenueData data, _) => data.amount,
          color: Colors.teal,
          dataLabelSettings: DataLabelSettings(isVisible: true),
        ),
      ],
    );
  }

  Widget _buildDevicesChart() {
    return SfCircularChart(
      legend: Legend(isVisible: true),
      series: <CircularSeries<DeviceData, String>>[
        PieSeries<DeviceData, String>(
          dataSource: [
            DeviceData('Mobile', 45),
            DeviceData('Desktop', 30),
            DeviceData('Tablette', 15),
            DeviceData('TV', 10),
          ],
          xValueMapper: (DeviceData data, _) => data.device,
          yValueMapper: (DeviceData data, _) => data.percentage,
          dataLabelSettings: DataLabelSettings(isVisible: true),
        ),
      ],
    );
  }

  Widget _buildViewershipChart() {
    return SfCartesianChart(
      primaryXAxis: CategoryAxis(),
      legend: Legend(isVisible: true),
      tooltipBehavior: TooltipBehavior(enable: true),
      series: <CartesianSeries<ChartData, String>>[
        ColumnSeries<ChartData, String>(
          name: 'Views',
          dataSource: [
            ChartData('Jan', 4200000),
            ChartData('Feb', 3800000),
            ChartData('Mar', 4500000),
            ChartData('Apr', 5100000),
            ChartData('May', 4900000),
            ChartData('Jun', 5400000),
          ],
          xValueMapper: (ChartData data, _) => data.x,
          yValueMapper: (ChartData data, _) => data.y,
          color: Colors.blue,
        ),
        LineSeries<ChartData, String>(
          name: 'Avg. Watch Time (min)',
          dataSource: [
            ChartData('Jan', 38),
            ChartData('Feb', 35),
            ChartData('Mar', 41),
            ChartData('Apr', 44),
            ChartData('May', 42),
            ChartData('Jun', 46),
          ],
          xValueMapper: (ChartData data, _) => data.x,
          yValueMapper: (ChartData data, _) => data.y,
          color: Colors.green,
          markerSettings: MarkerSettings(isVisible: true),
        ),
      ],
    );
  }

  Widget _buildContentPerformanceChart() {
    return SfCartesianChart(
      primaryXAxis: CategoryAxis(),
      primaryYAxis: NumericAxis(),
      zoomPanBehavior: ZoomPanBehavior(
        enablePinching: true,
        enableDoubleTapZooming: true,
      ),
      series: <CartesianSeries<ContentData, String>>[
        BarSeries<ContentData, String>(
          name: 'Top Content',
          dataSource: [
            ContentData('Stranger Things S4', 12500000, 92),
            ContentData('The Crown S5', 9800000, 88),
            ContentData('Wednesday', 15600000, 95),
            ContentData('Money Heist', 8700000, 85),
            ContentData('Dark', 7600000, 90),
          ],
          xValueMapper: (ContentData data, _) => data.title,
          yValueMapper: (ContentData data, _) => data.views,
          color: Colors.purple,
          dataLabelSettings: DataLabelSettings(
            isVisible: true,
            labelAlignment: ChartDataLabelAlignment.top,
          ),
        ),
      ],
    );
  }

  Widget _buildEngagementChart() {
    return SfCircularChart(
      legend: Legend(isVisible: true),
      series: <CircularSeries<EngagementData, String>>[
        PieSeries<EngagementData, String>(
          dataSource: [
            EngagementData('Binge Watchers', 35),
            EngagementData('Casual Viewers', 45),
            EngagementData('New Users', 15),
            EngagementData('Inactive', 5),
          ],
          xValueMapper: (EngagementData data, _) => data.segment,
          yValueMapper: (EngagementData data, _) => data.percentage,
          dataLabelSettings: DataLabelSettings(isVisible: true),
          explode: true,
          explodeIndex: 0,
        ),
      ],
    );
  }

  Widget _buildGeoChart() {
    return SfCartesianChart(
      primaryXAxis: CategoryAxis(),
      primaryYAxis: NumericAxis(),
      series: <CartesianSeries<GeoData, String>>[
        BarSeries<GeoData, String>(
          name: 'Viewers by Region',
          dataSource: [
            GeoData('North America', 4200000),
            GeoData('Europe', 3800000),
            GeoData('Asia', 3500000),
            GeoData('South America', 1800000),
            GeoData('Africa', 900000),
          ],
          xValueMapper: (GeoData data, _) => data.region,
          yValueMapper: (GeoData data, _) => data.viewers,
          color: Colors.orange,
          dataLabelSettings: DataLabelSettings(isVisible: true),
        ),
      ],
    );
  }
}

class ChartData {
  ChartData(this.x, this.y);
  final String x;
  final double y;
}

class ContentData {
  ContentData(this.title, this.views, this.rating);
  final String title;
  final int views;
  final int rating;
}

class EngagementData {
  EngagementData(this.segment, this.percentage);
  final String segment;
  final double percentage;
}

class GeoData {
  GeoData(this.region, this.viewers);
  final String region;
  final int viewers;
}

class StatusData {
  StatusData(this.status, this.percentage);
  final String status;
  final double percentage;
}

class WatchTimeData {
  WatchTimeData(this.category, this.minutes);
  final String category;
  final double minutes;
}

class GenreData {
  GenreData(this.genre, this.views);
  final String genre;
  final double views;
}

class RetentionData {
  RetentionData(this.week, this.rate);
  final String week;
  final double rate;
}

class RevenueData {
  RevenueData(this.month, this.amount);
  final String month;
  final double amount;
}

class DeviceData {
  DeviceData(this.device, this.percentage);
  final String device;
  final double percentage;
}
