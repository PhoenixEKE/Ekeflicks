import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:plateforme_producteurs/gen/app_localizations.dart';

import 'ui/login/login.dart';
import 'ui/producers_dashboard/dashboard_page.dart';
import 'ui/producers_dashboard/profile/profile_page.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      pageBuilder: (context, state) => MaterialPage(
        key: state.pageKey,
        child: const LoginPage(),
      ),
    ),
    GoRoute(
      path: '/dashboard',
      pageBuilder: (context, state) => MaterialPage(
        key: state.pageKey,
        child: const AdminDashboardPage(),
      ),
    ),
    GoRoute(
      path: '/profile',
      pageBuilder: (context, state) => MaterialPage(
        key: state.pageKey,
        child: const ProfilePage(),
      ),
    ),
  ],
  errorPageBuilder: (context, state) => MaterialPage(
    key: state.pageKey,
    child: Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.pageNotFound),
      ),
      body: Center(
        child: Text(AppLocalizations.of(context)!.pageNotFoundMessage),
      ),
    ),
  ),
);