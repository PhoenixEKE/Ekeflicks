import 'package:flutter/material.dart';
import 'package:plateforme_producteurs/gen/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:plateforme_producteurs/core/core.dart';
import 'package:plateforme_producteurs/providers/locale_provider.dart';
import 'package:plateforme_producteurs/providers/admin_auth_provider.dart';
import 'package:go_router/go_router.dart';

import 'overview_page.dart';
import 'users/users_page.dart';
import 'producers/producers_page.dart';
import 'administration/admin_page.dart';
import 'statistics/statistics_page.dart';
import 'my_videos/films_tab.dart';
import 'my_videos/series_tab.dart';
import 'upload/upload_page.dart';
import 'finance/finance_page.dart';
import 'claims/claims_page.dart';
import 'profile/profile_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _checkAsset();
  }

  Future<void> _checkAsset() async {
    try {
      await rootBundle.load('assets/images/logo_dark.png');
    } catch (e) {
      debugPrint("Error loading asset: $e");
    }
  }

  Future<void> _logout() async {
    await context.read<AdminAuthProvider>().logout();
    if (mounted) context.go('/');
  }

  List<Widget> _buildPages(AppLocalizations l10n) => [
    const OverviewPage(),
    const UsersPage(),
    const ProducersPage(),
    const AdminPage(),
    const StreamingStatisticsPage(),
    const FilmsTab(),
    const SeriesTab(),
    const UploadPage(),
    const FinancePage(),
    const ClaimsManagementPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(context, l10n, localeProvider),
      body: _buildBody(context, l10n),
      bottomNavigationBar: _buildBottomNavBar(l10n),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, AppLocalizations l10n, LocaleProvider localeProvider) {
    return AppBar(
      title: Image.asset(
        'assets/images/logo_dark.png',
        height: 40,
        errorBuilder: (_, __, ___) => const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.movie_filter, color: AppTheme.textPrimary, size: 32),
            SizedBox(width: 8),
            Text('EKEFLIX PRO', style: AppTheme.textTitle),
          ],
        ),
      ),
      centerTitle: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.background.withOpacity(0.9), Colors.transparent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.language),
          onPressed: localeProvider.toggleLocale,
          tooltip: l10n.changeLanguage,
        ),
        if (_selectedIndex == 0)
          IconButton(
            icon: Badge(
              backgroundColor: AppTheme.primary,
              child: const Icon(Icons.notifications_none_rounded),
            ),
            onPressed: () => _showNotifications(context, l10n),
          ),
        IconButton(
          icon: const Icon(Icons.logout_rounded),
          onPressed: _logout,
          tooltip: l10n.logout,
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n) {
    return _buildPages(l10n)[_selectedIndex];
  }

  Widget _buildBottomNavBar(AppLocalizations l10n) {
    final navItems = [
      _NavItem(Icons.dashboard_rounded, l10n.dashboardTab),
      _NavItem(Icons.people_alt_rounded, l10n.usersManagement),
      _NavItem(Icons.business_center_rounded, l10n.producersManagement),
      _NavItem(Icons.admin_panel_settings, l10n.adminManagement),
      _NavItem(Icons.analytics_rounded, l10n.statistics),
      _NavItem(Icons.movie_rounded, l10n.moviesTab),
      _NavItem(Icons.live_tv_rounded, l10n.seriesTab),
      _NavItem(Icons.cloud_upload_rounded, l10n.uploadTab),
      _NavItem(Icons.attach_money_rounded, l10n.financeTab),
      _NavItem(Icons.support_agent_rounded, l10n.supportTab),
      _NavItem(Icons.person_rounded, l10n.profileTab),
    ];

    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = navItems.length * 100.0;
          final isWide = constraints.maxWidth > totalWidth;

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
              width: isWide ? constraints.maxWidth : totalWidth,
              child: Center(
                child: Row(
                  mainAxisAlignment: isWide ? MainAxisAlignment.center : MainAxisAlignment.start,
                  children: navItems.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedIndex = index),
                      child: Container(
                        width: 100,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _selectedIndex == index
                              ? AppTheme.primary.withOpacity(0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              item.icon,
                              color: _selectedIndex == index
                                  ? AppTheme.primary
                                  : AppTheme.textSecondary,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.label,
                              style: AppTheme.textCaption.copyWith(
                                color: _selectedIndex == index
                                    ? AppTheme.primary
                                    : AppTheme.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showNotifications(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(l10n.notificationsTitle, style: AppTheme.textTitle),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              _NotificationItem(
                title: l10n.newVideoSubmitted,
                subtitle: "Documentaire: 'Les secrets de l'océan'",
                time: "15 min",
                icon: Icons.video_library,
              ),
              _NotificationItem(
                title: l10n.paymentRequest,
                subtitle: "Producteur: StudioSun - 1 250€",
                time: "1h",
                icon: Icons.payment,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close, style: TextStyle(color: AppTheme.primary)),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;

  const _NavItem(this.icon, this.label);
}

class _NotificationItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String time;
  final IconData icon;

  const _NotificationItem({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title, style: AppTheme.textBody),
      subtitle: Text(subtitle, style: AppTheme.textCaption),
      trailing: Text(time, style: AppTheme.textCaption),
      leading: Icon(icon, color: AppTheme.primary),
    );
  }
}
