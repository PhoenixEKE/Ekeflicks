import 'package:flutter/material.dart';
import 'package:plateforme_producteurs/gen/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:plateforme_producteurs/core/core.dart';
import 'package:plateforme_producteurs/providers/locale_provider.dart';

import 'overview_page.dart';
import 'my_videos/films_tab.dart';
import 'my_videos/series_tab.dart';
import 'upload/upload_page.dart';
import 'finance/finance_page.dart';
import 'claims/claims_page.dart';
import 'profile/profile_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _checkAsset();
  }

  Future<void> _checkAsset() async {
    try {
      await rootBundle.load('assets/images/logo_dark.png');
      debugPrint("Asset loaded successfully");
    } catch (e) {
      debugPrint("Asset loading error: $e");
    }
  }

  void _logout() {
    debugPrint("Logout requested");
  }

  List<Widget> _buildPages(AppLocalizations l10n) {
    return [
      const OverviewPage(),
      const FilmsTab(),
      const SeriesTab(),
      const UploadPage(),
      const FinancePage(),
      const ClaimsPage(),
      const ProfilePage(),
    ];
  }

  List<BottomNavigationBarItem> _buildNavItems(AppLocalizations l10n) {
    final icons = [
      Icons.dashboard_rounded,
      Icons.movie_rounded,
      Icons.live_tv_rounded,
      Icons.cloud_upload_rounded,
      Icons.attach_money_rounded,
      Icons.support_agent_rounded,
      Icons.person_rounded,
    ];

    final labels = [
      l10n.dashboardTab,
      l10n.moviesTab,
      l10n.seriesTab,
      l10n.uploadTab,
      l10n.financeTab,
      l10n.supportTab,
      l10n.profileTab,
    ];

    return List.generate(icons.length, (index) {
      return BottomNavigationBarItem(
        icon: _buildNavIcon(icons[index], index),
        label: labels[index],
      );
    });
  }

  Widget _buildNavIcon(IconData icon, int index) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: _selectedIndex == index
          ? BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(
                AppDecorations.borderRadiusSmall,
              ),
            )
          : null,
      child: Icon(icon),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(context, l10n, localeProvider),
      body: _buildPages(l10n)[_selectedIndex],
      bottomNavigationBar: _buildBottomNavBar(l10n),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    AppLocalizations l10n,
    LocaleProvider localeProvider,
  ) {
    return AppBar(
      title: Image.asset(
        'assets/images/logo_dark.png',
        height: 40,
        errorBuilder: (context, error, stackTrace) => const Row(
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
            colors: [
              AppTheme.background.withValues(alpha: 0.9),
              Colors.transparent,
            ],
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
          tooltip: l10n.logout,
          onPressed: _logout,
        ),
      ],
    );
  }

  Widget _buildBottomNavBar(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDecorations.borderRadiusLarge),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: AppTheme.textSecondary,
        selectedLabelStyle: AppTheme.textBodyBold,
        items: _buildNavItems(l10n),
      ),
    );
  }

  void _showNotifications(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDecorations.borderRadiusLarge),
        ),
        title: Text(l10n.notificationsTitle, style: AppTheme.textTitle),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                title: Text(
                  l10n.notificationNewComment,
                  style: AppTheme.textBody,
                ),
                subtitle: Text(
                  l10n.notificationOnContent("Mon Film - Episode 2"),
                  style: AppTheme.textCaption,
                ),
                trailing: Text('12:30', style: AppTheme.textCaption),
              ),
              ListTile(
                title: Text(l10n.notificationPayment, style: AppTheme.textBody),
                subtitle: Text('+ 120,00 €', style: AppTheme.textCaption),
                trailing: Text(l10n.yesterday, style: AppTheme.textCaption),
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
