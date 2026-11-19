import 'dart:async';

import 'package:flutter/material.dart';
import 'package:plateforme_producteurs/producers_dashboard/technical_specification_page.dart';
import 'package:go_router/go_router.dart';
import 'package:plateforme_producteurs/gen/app_localizations.dart';
import 'package:plateforme_producteurs/models/producer_notification.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:plateforme_producteurs/core/core.dart';
import 'package:plateforme_producteurs/providers/locale_provider.dart';
import 'package:plateforme_producteurs/services/auth_service.dart';
import 'package:plateforme_producteurs/services/producer_notification_service.dart';
import 'package:plateforme_producteurs/widgets/producer_page_shell.dart';
import 'package:plateforme_producteurs/widgets/producer_notifications_dialog.dart';

import 'overview_page.dart';
import 'analytics/analytics_page.dart';
import 'my_videos/films_tab.dart';
import 'my_videos/series_tab.dart';
import 'upload/upload_page.dart';
import 'finance/finance_page.dart';
import 'package:plateforme_producteurs/settings/help_support_page.dart';
import 'profile/profile_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  int _unreadNotificationCount = 0;
  List<ProducerNotification> _notifications = const [];
  Timer? _notificationRefreshTimer;

  String? _editingContentId;
  int? _editingOriginIndex;

  @override
  void initState() {
    super.initState();
    _checkAsset();
    _refreshNotificationCount();
    _notificationRefreshTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _refreshNotificationCount(),
    );
  }

  @override
  void dispose() {
    _notificationRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshNotificationCount() async {
    try {
      final inbox = await ProducerNotificationService.instance.getInbox();
      _acceptNotificationInbox(inbox);
    } catch (_) {
      // The dashboard remains usable if notification delivery is unavailable.
    }
  }

  Future<void> _acceptNotificationInbox(
    ProducerNotificationInbox inbox,
  ) async {
    if (!mounted) return;
    setState(() {
      _unreadNotificationCount = inbox.unreadCount;
      _notifications = inbox.notifications;
    });
  }

  Future<void> _checkAsset() async {
    try {
      await rootBundle.load('assets/images/logo_dark.png');
      debugPrint("Asset loaded successfully");
    } catch (e) {
      debugPrint("Asset loading error: $e");
    }
  }

  Future<void> _logout() async {
    await AuthService.instance.logout();

    if (!mounted) {
      return;
    }

    context.go('/');
  }

  void _openContentEditor(String contentId, int originIndex) {
    setState(() {
      _editingContentId = contentId;
      _editingOriginIndex = originIndex;
      _selectedIndex = 4;
    });
  }

  void _leaveContentEditor() {
    final origin = _editingOriginIndex ?? 1;

    setState(() {
      _editingContentId = null;
      _editingOriginIndex = null;
      _selectedIndex = origin;
    });
  }

  void _selectDashboardTab(int index) {
    setState(() {
      if (index == 4 && _selectedIndex != 4) {
        _editingContentId = null;
        _editingOriginIndex = null;
      }

      _selectedIndex = index;
    });
  }

  List<Widget> _buildPages() {
    return [
      OverviewPage(
        notifications: _notifications,
        onRefreshNotifications: _refreshNotificationCount,
      ),
      const AnalyticsPage(),
      FilmsTab(
        onEditContent: (contentId) {
          _openContentEditor(contentId, 2);
        },
      ),
      SeriesTab(
        onEditContent: (contentId) {
          _openContentEditor(contentId, 3);
        },
      ),
      UploadPage(
        key: ValueKey(_editingContentId ?? 'new-content'),
        contentId: _editingContentId,
        onExit: _leaveContentEditor,
      ),
      const FinancePage(),
      const HelpSupportPage(embedded: true),
      const ProfilePage(),
    ];
  }

  List<String> _buildPageTitles(AppLocalizations l10n) {
    return [
      l10n.dashboardTab,
      'Analytics',
      l10n.moviesTab,
      l10n.seriesTab,
      l10n.uploadTab,
      l10n.financeTab,
      l10n.supportTab,
      l10n.profileTab,
    ];
  }

  List<BottomNavigationBarItem> _buildNavItems(AppLocalizations l10n) {
    final icons = [
      Icons.dashboard_rounded,
      Icons.analytics_rounded,
      Icons.movie_rounded,
      Icons.live_tv_rounded,
      Icons.cloud_upload_rounded,
      Icons.attach_money_rounded,
      Icons.support_agent_rounded,
      Icons.person_rounded,
    ];

    final labels = [
      l10n.dashboardTab,
      'Analytics',
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
      backgroundColor: const Color(0xFF121212),
      body: ProducerPageShell(
        title: _buildPageTitles(l10n)[_selectedIndex],
        padding: EdgeInsets.zero,
        actions: [
          if (_selectedIndex == 0)
            IconButton(
              tooltip: l10n.notificationsTitle,
              icon: Badge(
                isLabelVisible: _unreadNotificationCount > 0,
                label: Text(
                  _unreadNotificationCount > 99
                      ? '99+'
                      : '$_unreadNotificationCount',
                ),
                backgroundColor: AppTheme.primary,
                child: const Icon(Icons.notifications_none_rounded),
              ),
              onPressed: () => _showNotifications(context),
            ),
          PopupMenuButton<int>(
            tooltip: 'Options',
            onSelected: (choice) {
              if (choice == 0) localeProvider.toggleLocale();
              if (choice == 1) {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const TechnicalSpecificationPage(),
                  ),
                );
              }
              if (choice == 2) _logout();
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 0, child: Text(l10n.changeLanguage)),
              const PopupMenuItem(value: 1, child: Text('Cahier des charges technique')),
              PopupMenuItem(value: 2, child: Text(l10n.logout)),
            ],
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Icon(Icons.more_vert),
            ),
          ),
        ],
        child: _buildPages()[_selectedIndex],
      ),
      bottomNavigationBar: _buildBottomNavBar(l10n),
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
        onTap: _selectDashboardTab,
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

  void _showNotifications(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => ProducerNotificationsDialog(
        onChanged: _acceptNotificationInbox,
      ),
    );
  }
}
