import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:plateforme_producteurs/gen/app_localizations.dart';
import 'package:plateforme_producteurs/services/auth_service.dart';
import 'package:plateforme_producteurs/services/producer_service.dart';

import 'login/login.dart';
import 'onboarding/agreement_page.dart';
import 'onboarding/faq_page.dart';
import 'onboarding/onboarding_page.dart';
import 'onboarding/register_page.dart';
import 'onboarding/verify_email_page.dart';
import 'producers_dashboard/dashboard_page.dart';
import 'producers_dashboard/profile/profile_page.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) async {
    final auth = AuthService.instance;
    final location = state.matchedLocation;

    final isPublicPage =
        location == '/' ||
        location == '/register' ||
        location == '/verify-email' ||
        location == '/faq';

    if (!auth.isAuthenticated) {
      await auth.restoreSession();
    }

    if (!auth.isAuthenticated) {
      return isPublicPage ? null : '/';
    }

    // Les liens publics doivent pouvoir s'exécuter avant les règles
    // d'onboarding et de contrat.
    if (location == '/verify-email' || location == '/faq') {
      return null;
    }

    final account = await ProducerService.instance.getOnboarding();

    if (account.status == 'suspended' || account.status == 'rejected') {
      if (location != '/onboarding') {
        return '/onboarding';
      }
      return null;
    }

    if (!account.emailVerified || account.status == 'onboarding') {
      if (location != '/onboarding') {
        return '/onboarding';
      }
      return null;
    }

    if (account.status == 'contract_pending' ||
        account.currentAgreementStatus != 'signed') {
      if (location != '/agreement') {
        return '/agreement';
      }
      return null;
    }

    if (account.status == 'active' &&
        account.currentAgreementStatus == 'signed' &&
        account.canSubmitContent) {
      if (location == '/' ||
          location == '/register' ||
          location == '/onboarding') {
        return '/dashboard';
      }
      return null;
    }

    if (location != '/onboarding') {
      return '/onboarding';
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      pageBuilder: (context, state) =>
          MaterialPage(key: state.pageKey, child: const LoginPage()),
    ),
    GoRoute(
      path: '/register',
      pageBuilder: (context, state) =>
          MaterialPage(key: state.pageKey, child: const ProducerRegisterPage()),
    ),
    GoRoute(
      path: '/faq',
      pageBuilder: (context, state) =>
          MaterialPage(key: state.pageKey, child: const ProducerFaqPage()),
    ),
    GoRoute(
      path: '/verify-email',
      pageBuilder: (context, state) => MaterialPage(
        key: state.pageKey,
        child: ProducerVerifyEmailPage(
          token: state.uri.queryParameters['token'],
        ),
      ),
    ),
    GoRoute(
      path: '/onboarding',
      pageBuilder: (context, state) => MaterialPage(
        key: state.pageKey,
        child: const ProducerOnboardingPage(),
      ),
    ),
    GoRoute(
      path: '/agreement',
      pageBuilder: (context, state) => MaterialPage(
        key: state.pageKey,
        child: const ProducerAgreementPage(),
      ),
    ),
    GoRoute(
      path: '/dashboard',
      pageBuilder: (context, state) =>
          MaterialPage(key: state.pageKey, child: const DashboardPage()),
    ),
    GoRoute(
      path: '/profile',
      pageBuilder: (context, state) =>
          MaterialPage(key: state.pageKey, child: const ProfilePage()),
    ),
  ],
  errorPageBuilder: (context, state) => MaterialPage(
    key: state.pageKey,
    child: Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.pageNotFound)),
      body: Center(
        child: Text(AppLocalizations.of(context)!.pageNotFoundMessage),
      ),
    ),
  ),
);
