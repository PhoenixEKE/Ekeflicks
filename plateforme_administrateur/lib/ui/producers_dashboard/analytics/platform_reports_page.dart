import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import 'package:plateforme_administrateur/api/admin_api_client.dart';
import 'package:plateforme_administrateur/core/core.dart';

class PlatformReportsPage extends StatefulWidget {
  const PlatformReportsPage({super.key});

  @override
  State<PlatformReportsPage> createState() => _PlatformReportsPageState();
}

class _PlatformReportsPageState extends State<PlatformReportsPage> {
  int _days = 30;
  late Future<Map<String, dynamic>> _report;

  @override
  void initState() {
    super.initState();
    _report = _load();
  }

  Future<Map<String, dynamic>> _load() =>
      context.read<AdminApiClient>().platformAnalytics(days: _days);

  void _refresh() => setState(() => _report = _load());

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
        future: _report,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: FilledButton.icon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh),
                label: Text('Impossible de charger le rapport : ${snapshot.error}'),
              ),
            );
          }
          final payload = snapshot.data ?? const <String, dynamic>{};
          final summary = Map<String, dynamic>.from(payload['summary'] as Map? ?? const {});
          final advertising = Map<String, dynamic>.from(payload['advertising'] as Map? ?? const {});
          final timeline = (payload['timeline'] as List? ?? const [])
              .whereType<Map>()
              .map((row) => _ReportPoint.fromJson(Map<String, dynamic>.from(row)))
              .toList();
          final contents = (payload['top_contents'] as List? ?? const [])
              .whereType<Map>()
              .map((row) => Map<String, dynamic>.from(row))
              .toList();
          final producers = (payload['top_producers'] as List? ?? const [])
              .whereType<Map>()
              .map((row) => Map<String, dynamic>.from(row))
              .toList();
          final payments = (payload['payments_by_currency'] as List? ?? const [])
              .whereType<Map>()
              .map((row) => Map<String, dynamic>.from(row))
              .toList();
          final geography = (payload['geography'] as List? ?? const [])
              .whereType<Map>()
              .map((row) => Map<String, dynamic>.from(row))
              .toList();
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Rapports et analyses',
                        style: AppTheme.textTitle.copyWith(fontSize: 24),
                      ),
                    ),
                    SizedBox(
                      width: 155,
                      child: DropdownButtonFormField<int>(
                        value: _days,
                        decoration: const InputDecoration(
                          labelText: 'Période',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: const [
                          DropdownMenuItem(value: 7, child: Text('7 jours')),
                          DropdownMenuItem(value: 30, child: Text('30 jours')),
                          DropdownMenuItem(value: 90, child: Text('90 jours')),
                          DropdownMenuItem(value: 365, child: Text('12 mois')),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _days = value;
                            _report = _load();
                          });
                        },
                      ),
                    ),
                    IconButton(
                      onPressed: _refresh,
                      tooltip: 'Actualiser',
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView(
                    children: [
                      _KpiGrid(items: [
                        _Kpi('Utilisateurs', summary['users'], Icons.people_alt_outlined),
                        _Kpi('Nouveaux utilisateurs', summary['new_users'], Icons.person_add_alt_1),
                        _Kpi('Producteurs actifs', summary['active_producers'], Icons.business_outlined),
                        _Kpi('Abonnements actifs', summary['active_subscriptions'], Icons.subscriptions_outlined),
                        _Kpi('Contenus publiés', summary['published_contents'], Icons.movie_outlined),
                        _Kpi('Vidéos prêtes', summary['ready_videos'], Icons.video_library_outlined),
                        _Kpi('Vues', summary['views'], Icons.play_circle_outline),
                        _Kpi('Heures regardées', ((summary['watch_minutes'] as num? ?? 0) / 60).toStringAsFixed(1), Icons.schedule),
                        _Kpi('Taux de complétion', '${summary['completion_rate_percent'] ?? 0} %', Icons.task_alt),
                        _Kpi('Revenu pub net', '${summary['advertising_net_revenue_eur'] ?? 0} €', Icons.campaign_outlined),
                      ]),
                      const SizedBox(height: 16),
                      _SectionCard(
                        title: 'Audience et diffusion publicitaire',
                        child: SizedBox(
                          height: 300,
                          child: SfCartesianChart(
                            legend: const Legend(isVisible: true, position: LegendPosition.bottom),
                            tooltipBehavior: TooltipBehavior(enable: true),
                            primaryXAxis: const CategoryAxis(
                              majorGridLines: MajorGridLines(width: 0),
                              labelIntersectAction: AxisLabelIntersectAction.rotate45,
                            ),
                            primaryYAxis: const NumericAxis(
                              axisLine: AxisLine(width: 0),
                              majorGridLines: MajorGridLines(width: 0.5),
                            ),
                            series: <CartesianSeries<_ReportPoint, String>>[
                              LineSeries<_ReportPoint, String>(
                                name: 'Vues',
                                dataSource: timeline,
                                xValueMapper: (point, _) => point.date,
                                yValueMapper: (point, _) => point.views,
                                color: AppTheme.primary,
                                markerSettings: const MarkerSettings(isVisible: false),
                              ),
                              ColumnSeries<_ReportPoint, String>(
                                name: 'Impressions pub',
                                dataSource: timeline,
                                xValueMapper: (point, _) => point.date,
                                yValueMapper: (point, _) => point.adImpressions,
                                color: const Color(0xFF00A8CC),
                              ),
                              LineSeries<_ReportPoint, String>(
                                name: 'Publicités terminées',
                                dataSource: timeline,
                                xValueMapper: (point, _) => point.date,
                                yValueMapper: (point, _) => point.adCompletions,
                                color: const Color(0xFFFF8A3D),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _SectionCard(
                        title: 'Performance publicitaire',
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _SmallMetric('Demandes', advertising['requests']),
                            _SmallMetric('Impressions', advertising['impressions']),
                            _SmallMetric('Taux de remplissage', '${advertising['fill_rate_percent'] ?? 0} %'),
                            _SmallMetric('Taux de complétion', '${advertising['completion_rate_percent'] ?? 0} %'),
                            _SmallMetric('CTR', '${advertising['click_through_rate_percent'] ?? 0} %'),
                            _SmallMetric('Clics interactifs', advertising['clicks']),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      LayoutBuilder(builder: (context, constraints) {
                        final wide = constraints.maxWidth >= 900;
                        final left = _RankingCard(
                          title: 'Contenus les plus regardés',
                          rows: contents,
                          titleKey: 'title',
                          valueKey: 'views',
                        );
                        final right = _RankingCard(
                          title: 'Producteurs par vues',
                          rows: producers,
                          titleKey: 'name',
                          valueKey: 'views',
                        );
                        return wide
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: left),
                                  const SizedBox(width: 12),
                                  Expanded(child: right),
                                ],
                              )
                            : Column(children: [left, const SizedBox(height: 12), right]);
                      }),
                      const SizedBox(height: 16),
                      LayoutBuilder(builder: (context, constraints) {
                        final wide = constraints.maxWidth >= 900;
                        final left = _SimpleRows(
                          title: 'Paiements par devise',
                          rows: payments,
                          label: (row) => row['currency']?.toString() ?? '—',
                          value: (row) => '${row['amount'] ?? 0} (${row['count'] ?? 0} paiements)',
                        );
                        final right = _SimpleRows(
                          title: 'Impressions et clics par pays',
                          rows: geography,
                          label: (row) => row['country_code']?.toString() ?? '—',
                          value: (row) => '${row['impressions'] ?? 0} impressions · ${row['clicks'] ?? 0} clics',
                        );
                        return wide
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: left),
                                  const SizedBox(width: 12),
                                  Expanded(child: right),
                                ],
                              )
                            : Column(children: [left, const SizedBox(height: 12), right]);
                      }),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
}

class _ReportPoint {
  const _ReportPoint(this.date, this.views, this.adImpressions, this.adCompletions);

  final String date;
  final int views;
  final int adImpressions;
  final int adCompletions;

  factory _ReportPoint.fromJson(Map<String, dynamic> row) => _ReportPoint(
        (row['date']?.toString() ?? '').substring(5),
        (row['views'] as num? ?? 0).toInt(),
        (row['ad_impressions'] as num? ?? 0).toInt(),
        (row['ad_completions'] as num? ?? 0).toInt(),
      );
}

class _Kpi {
  const _Kpi(this.label, this.value, this.icon);
  final String label;
  final dynamic value;
  final IconData icon;
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.items});
  final List<_Kpi> items;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final count = constraints.maxWidth >= 1250 ? 5 : constraints.maxWidth >= 900 ? 4 : constraints.maxWidth >= 560 ? 3 : 2;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: count,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.75,
            ),
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(item.icon, color: AppTheme.primary),
                      const SizedBox(height: 6),
                      Text('${item.value ?? 0}', style: AppTheme.textTitle.copyWith(fontSize: 20)),
                      Text(item.label, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTheme.textCaption),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: AppTheme.textSubtitle),
            const Divider(),
            child,
          ]),
        ),
      );
}

class _SmallMetric extends StatelessWidget {
  const _SmallMetric(this.label, this.value);
  final String label;
  final dynamic value;
  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minWidth: 145),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${value ?? 0}', style: AppTheme.textTitle.copyWith(fontSize: 18)),
          Text(label, style: AppTheme.textCaption),
        ]),
      );
}

class _RankingCard extends StatelessWidget {
  const _RankingCard({required this.title, required this.rows, required this.titleKey, required this.valueKey});
  final String title;
  final List<Map<String, dynamic>> rows;
  final String titleKey;
  final String valueKey;
  @override
  Widget build(BuildContext context) => _SectionCard(
        title: title,
        child: rows.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(22),
                child: Center(child: Text('Aucune donnée pour cette période.')),
              )
            : Column(
                children: rows.map((row) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(row[titleKey]?.toString() ?? '—', maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: Text('${row[valueKey] ?? 0} vues', style: AppTheme.textBodyBold),
                )).toList(),
              ),
      );
}

class _SimpleRows extends StatelessWidget {
  const _SimpleRows({required this.title, required this.rows, required this.label, required this.value});
  final String title;
  final List<Map<String, dynamic>> rows;
  final String Function(Map<String, dynamic>) label;
  final String Function(Map<String, dynamic>) value;
  @override
  Widget build(BuildContext context) => _SectionCard(
        title: title,
        child: rows.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: Text('Aucune donnée pour cette période.')),
              )
            : Column(
                children: rows.map((row) => ListTile(
                  dense: true,
                  title: Text(label(row)),
                  trailing: Text(value(row), style: AppTheme.textCaption),
                )).toList(),
              ),
      );
}
