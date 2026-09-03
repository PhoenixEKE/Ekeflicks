import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:plateforme_producteurs/onboarding/widgets/producer_auth_shell.dart';
import 'package:plateforme_producteurs/services/api_client.dart';
import 'package:plateforme_producteurs/services/auth_service.dart';
import 'package:plateforme_producteurs/services/producer_service.dart';

class ProducerVerifyEmailPage extends StatefulWidget {
  const ProducerVerifyEmailPage({super.key, required this.token});

  final String? token;

  @override
  State<ProducerVerifyEmailPage> createState() =>
      _ProducerVerifyEmailPageState();
}

class _ProducerVerifyEmailPageState extends State<ProducerVerifyEmailPage> {
  bool _loading = true;
  bool _success = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _verify();
  }

  Future<void> _verify() async {
    final token = widget.token;

    if (token == null || token.trim().isEmpty) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Lien de vérification incomplet.';
        });
      }
      return;
    }

    try {
      await ProducerService.instance.verifyEmail(token);

      if (!AuthService.instance.isAuthenticated) {
        await AuthService.instance.restoreSession();
      }

      if (!mounted) return;

      setState(() {
        _success = true;
        _loading = false;
      });

      if (AuthService.instance.isAuthenticated) {
        try {
          final account = await ProducerService.instance.getOnboarding();

          if (!mounted) return;

          await Future<void>.delayed(const Duration(milliseconds: 700));

          if (!mounted) return;

          if (account.status == 'contract_pending') {
            context.go('/agreement');
            return;
          }

          if (account.status == 'active' &&
              account.currentAgreementStatus == 'signed') {
            context.go('/dashboard');
            return;
          }

          context.go('/onboarding');
        } on ApiException {
          // La vérification est bien effectuée.
          // L'utilisateur peut poursuivre manuellement.
        }
      }
    } on ApiException catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFF67F00);

    return ProducerAuthShell(
      maxWidth: 560,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProducerFormHeader(
            title: _loading
                ? 'Vérification en cours'
                : _success
                ? 'Email vérifié'
                : 'Vérification impossible',
            subtitle: _loading
                ? 'EKEFLICKS vérifie votre adresse email.'
                : _success
                ? 'Votre adresse email a été vérifiée avec succès.'
                : (_error ?? 'Le lien est invalide ou a expiré.'),
            icon: _success
                ? Icons.verified_outlined
                : Icons.mark_email_read_outlined,
          ),

          const SizedBox(height: 32),

          if (_loading) const Center(child: CircularProgressIndicator()),

          if (_success)
            const Icon(Icons.check_circle, size: 72, color: Colors.green),

          if (!_loading && !_success) ...[
            const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/'),
              style: ElevatedButton.styleFrom(
                backgroundColor: orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retour à la connexion'),
            ),
          ],

          if (_success && !AuthService.instance.isAuthenticated) ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/'),
              style: ElevatedButton.styleFrom(
                backgroundColor: orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Se connecter au portail Producteurs'),
            ),
          ],
        ],
      ),
    );
  }
}
