import 'package:flutter/material.dart';

import 'ui/home/splash_screen.dart';
import 'ui/pages/faq_page.dart';
import 'ui/users/login_screen.dart';
import 'ui/users/forgot_password_page.dart';
import 'ui/users/sign_up_page.dart';
import 'ui/legal/terms_of_use_page.dart';
import 'ui/legal/privacy_policy_page.dart';
import 'ui/subscription/subscription_step1_page.dart';
import 'ui/profiles/profile_selection_page.dart';

/// Configuration des routes de l'application
/// Chaque route est associée à un écran (widget) spécifique
Map<String, WidgetBuilder> getAppRoutes() {
  return {
    // Route initiale - Écran de démarrage/splash
    '/': (context) => const SplashScreen(),
    
    // Route pour les faq et centre d'aides
    '/faq': (context) => const FaqPage(), 

    // Route pour la connexion utilisateur standard
    '/login': (context) => const LoginPage(),
    
    // Route pour la récupération de mot de passe
    '/forgot-password': (context) => const ForgotPasswordPage(),
    
    // Route pour l'inscription d'un nouvel utilisateur
    '/signup': (context) => const SignupPage(),
    
    // Route pour les conditions d'utilisation
    '/terms': (context) => const TermsOfUsePage(),
    
    // Route pour la politique de confidentialité
    '/privacy': (context) => const PrivacyPolicyPage(),
    
    // Route pour la première étape d'abonnement
    '/subscription-step1': (context) => const SubscriptionStep1Page(),
    
    // Route pour la sélection de profil (interface TV)
    '/profile-selection': (context) => const ProfileSelectionPage(),
  };
}

/// Route initiale de l'application
String getInitialRoute() {
  return '/';
}