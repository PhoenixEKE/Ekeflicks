import 'package:flutter/material.dart';

import 'ui/home/splash_screen.dart';
import 'ui/legal/privacy_policy_page.dart';
import 'ui/legal/terms_of_use_page.dart';
import 'ui/pages/faq_page.dart';
import 'ui/profiles/profile_selection_page.dart';
import 'ui/profiles/reset_parental_pin_page.dart';
import 'ui/subscription/subscription_step1_page.dart';
import 'ui/users/forgot_password_page.dart';
import 'ui/users/login_screen.dart';
import 'ui/users/reset_password_page.dart';
import 'ui/users/sign_up_page.dart';

/// Configuration des routes de l'application.
Map<String, WidgetBuilder> getAppRoutes() {
  return {
    '/': (context) => const SplashScreen(),
    '/faq': (context) => const FaqPage(),
    '/login': (context) => const LoginPage(),
    '/forgot-password': (context) => const ForgotPasswordPage(),
    '/reset-password': (context) => const ResetPasswordPage(),
    '/password-reset-confirm': (context) => const ResetPasswordPage(),
    '/reset-parental-pin': (context) => const ResetParentalPinPage(),
    '/signup': (context) => const SignupPage(),
    '/terms': (context) => const TermsOfUsePage(),
    '/privacy': (context) => const PrivacyPolicyPage(),
    '/subscription-step1': (context) => const SubscriptionStep1Page(),
    '/profile-selection': (context) => const ProfileSelectionPage(),
  };
}

/// Route initiale de l'application.
String getInitialRoute() => '/';
