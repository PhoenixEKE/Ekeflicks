import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/profile_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/subscription_progress_service.dart';
import '../profiles/profile_selection_page.dart';
import '../users/login_screen.dart';
import '../users/post_login_page.dart';
import 'subscription_step1_page.dart';

class PaymentReturnPage extends StatefulWidget {
  const PaymentReturnPage({super.key});

  @override
  State<PaymentReturnPage> createState() => _PaymentReturnPageState();
}

class _PaymentReturnPageState extends State<PaymentReturnPage> {
  bool _checking = true;
  bool _success = false;
  bool _cancelled = false;

  String _message = 'Vérification de votre paiement...';

  String get _status => Uri.base.queryParameters['status']?.toLowerCase() ?? '';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleReturn();
    });
  }

  Future<void> _handleReturn() async {
    if (_status == 'cancelled') {
      if (!mounted) return;

      setState(() {
        _checking = false;
        _cancelled = true;
        _success = false;
        _message =
            'Votre paiement a été annulé. Aucun abonnement n’a été activé.';
      });
      return;
    }

    if (_status != 'success') {
      if (!mounted) return;

      setState(() {
        _checking = false;
        _success = false;
        _cancelled = false;
        _message =
            'Le paiement n’a pas pu être confirmé. Votre abonnement n’a pas été activé.';
      });
      return;
    }

    if (!mounted) return;

    setState(() {
      _checking = true;
      _success = true;
      _message =
          'Paiement réussi. Nous activons maintenant votre abonnement...';
    });

    await _verifySubscription();
  }

  Future<void> _verifySubscription() async {
    final userProvider = context.read<UserProvider>();
    final profileProvider = context.read<ProfileProvider>();

    //
    // Après Stripe, Flutter Web a été rechargé.
    // checkAuthStatus restaure maintenant le refresh token sauvegardé
    // et obtient automatiquement un nouvel access token.
    //
    final authenticated = await userProvider.checkAuthStatus();

    if (!authenticated) {
      if (!mounted) return;

      setState(() {
        _checking = false;
        _success = true;
        _message =
            'Votre paiement a été reçu. Reconnectez-vous pour terminer l’activation de votre abonnement.';
      });
      return;
    }

    //
    // Le retour navigateur peut arriver avant le webhook Stripe.
    // On interroge donc le backend pendant quelques secondes.
    //
    for (var attempt = 0; attempt < 10; attempt++) {
      await userProvider.refreshCurrentUser();

      if (userProvider.hasActiveSubscription) {
        final email = userProvider.currentUser?.email;

        if (email != null && email.isNotEmpty) {
          await SubscriptionProgressService().complete(email);
        }

        await profileProvider.loadProfiles();

        if (!mounted) return;

        setState(() {
          _checking = false;
          _success = true;
          _message = 'Paiement confirmé. Votre abonnement EKEFLICKS est actif.';
        });

        //
        // Laisser brièvement le message de succès visible.
        //
        await Future<void>.delayed(const Duration(seconds: 2));

        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder:
                (_) =>
                    profileProvider.availableProfiles.length > 1
                        ? const ProfileSelectionPage()
                        : const PostLoginPage(),
          ),
          (route) => false,
        );
        return;
      }

      if (attempt < 9) {
        await Future<void>.delayed(const Duration(seconds: 2));
      }
    }

    if (!mounted) return;

    setState(() {
      _checking = false;
      _success = true;
      _message =
          'Votre paiement a été reçu, mais l’activation prend un peu plus de temps que prévu.';
    });
  }

  void _retryVerification() {
    setState(() {
      _checking = true;
      _success = true;
      _cancelled = false;
      _message = 'Vérification de votre abonnement...';
    });

    _verifySubscription();
  }

  void _goToSubscriptions() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const SubscriptionStep1Page()),
      (route) => false,
    );
  }

  void _goToLogin() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final icon =
        _checking
            ? null
            : _success
            ? Icons.check_circle
            : _cancelled
            ? Icons.info
            : Icons.error;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_checking)
                  const CircularProgressIndicator()
                else if (icon != null)
                  Icon(icon, size: 72),
                const SizedBox(height: 24),
                Text(
                  _success
                      ? 'Paiement réussi'
                      : _cancelled
                      ? 'Paiement annulé'
                      : 'Paiement échoué',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                Text(_message, textAlign: TextAlign.center),
                if (!_checking) ...[
                  const SizedBox(height: 28),

                  if (_success) ...[
                    ElevatedButton(
                      onPressed: _retryVerification,
                      child: const Text('Vérifier mon abonnement'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _goToLogin,
                      child: const Text('Se reconnecter'),
                    ),
                  ] else ...[
                    ElevatedButton(
                      onPressed: _goToSubscriptions,
                      child: const Text('Réessayer'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _goToLogin,
                      child: const Text('Retour à la connexion'),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
