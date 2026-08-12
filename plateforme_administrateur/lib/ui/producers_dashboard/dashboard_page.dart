import 'package:flutter/material.dart';
import 'package:plateforme_administrateur/gen/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:plateforme_administrateur/core/core.dart';
import 'package:plateforme_administrateur/providers/locale_provider.dart';
import 'package:plateforme_administrateur/providers/admin_auth_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:plateforme_administrateur/api/admin_api_client.dart';

import 'overview_page.dart';
import 'users/users_page.dart';
import 'producers/producers_page.dart';
import 'administration/admin_page.dart';
import 'moderation/moderation_page.dart';
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

  List<_Destination> _destinations(AppLocalizations l10n) {
    final auth = context.read<AdminAuthProvider>();
    return [
      _Destination(_NavItem(Icons.dashboard_rounded, l10n.dashboardTab), const OverviewPage()),
      if (auth.can('core.view_user'))
        _Destination(_NavItem(Icons.people_alt_rounded, l10n.usersManagement), const UsersPage()),
      if (auth.can('core.view_user'))
        _Destination(_NavItem(Icons.business_center_rounded, l10n.producersManagement), const ProducersPage()),
      if (auth.isSuperuser)
        _Destination(_NavItem(Icons.admin_panel_settings, l10n.adminManagement), const AdminPage()),
      if (auth.can('core.view_content')) ...[
        _Destination(_NavItem(Icons.fact_check_rounded, 'Modération'), const ModerationPage()),
      ],
      if (auth.can('core.view_payment'))
        _Destination(_NavItem(Icons.attach_money_rounded, l10n.financeTab), const FinancePage()),
      if (auth.can('core.view_accountclosurerequest') || auth.can('core.view_emailchangesupportrequest'))
        _Destination(_NavItem(Icons.support_agent_rounded, l10n.supportTab), const ClaimsManagementPage()),
      _Destination(_NavItem(Icons.person_rounded, l10n.profileTab), const ProfilePage()),
    ];
  }

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
            Text('EKEFLICKS ADMIN', style: AppTheme.textTitle),
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
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () => _showNotifications(context),
            tooltip: 'Notifications administrateur',
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
    final destinations = _destinations(l10n);
    if (_selectedIndex >= destinations.length) _selectedIndex = 0;
    return destinations[_selectedIndex].page;
  }

  Widget _buildBottomNavBar(AppLocalizations l10n) {
    final navItems = _destinations(l10n).map((destination) => destination.nav).toList();

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

  Future<void> _showNotifications(BuildContext context) async {
    final api = context.read<AdminApiClient>();
    final payload = await api.notifications();
    final rows = List<Map<String, dynamic>>.from(payload['results'] ?? []);
    if (!context.mounted) return;
    await showDialog<void>(context: context, builder: (dialogContext) => AlertDialog(
      backgroundColor: AppTheme.cardBackground,
      title: Row(children: [
        const Expanded(child: Text('Notifications')),
        if ((payload['unread'] ?? 0) > 0)
          Badge(label: Text('${payload['unread']}')),
      ]),
      content: SizedBox(width: 620, height: 480, child: rows.isEmpty
        ? const Center(child: Text('Aucune notification.'))
        : ListView.separated(
            itemCount: rows.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (_, index) {
              final row = rows[index];
              return ListTile(
                dense: true,
                leading: Icon(
                  row['is_read'] == true ? Icons.notifications_none : Icons.notifications_active,
                  color: AppTheme.primary,
                ),
                title: Text(row['title']?.toString() ?? ''),
                subtitle: Text(row['message']?.toString() ?? ''),
                trailing: row['is_read'] == true ? null : const Icon(Icons.circle, size: 9),
              );
            },
          ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            await api.markNotificationsRead();
            if (dialogContext.mounted) Navigator.pop(dialogContext);
          },
          child: const Text('Tout marquer comme lu'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Fermer'),
        ),
      ],
    ));
  }
}

class _NavItem {
  final IconData icon;
  final String label;

  const _NavItem(this.icon, this.label);
}

class _Destination {
  final _NavItem nav;
  final Widget page;

  const _Destination(this.nav, this.page);
}
