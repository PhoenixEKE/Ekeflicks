import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_ekeflicks/l10n/app_localizations.dart';
import 'package:app_ekeflicks/widgets/app_bars/simple_app_bar.dart';
import 'package:app_ekeflicks/core/app_theme.dart';
import 'package:app_ekeflicks/core/app_decorations.dart';
import 'package:app_ekeflicks/providers/user_provider.dart';
import 'package:app_ekeflicks/utils/api_error_message.dart';
import 'package:dio/dio.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key, this.token});

  final String? token;

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isSubmitting = false;

  String? token;

  @override
  void initState() {
    super.initState();
    token = widget.token ?? Uri.base.queryParameters['token'];
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Lien de réinitialisation invalide."),
          duration: Duration(seconds: 7),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final userProvider = context.read<UserProvider>();

      // Appel direct à l'API pour confirmer la réinitialisation
      await userProvider.apiClient.dio.post<Object>(
        '/auth/password-reset/confirm/',
        data: {
          'token': token,
          'password': _passwordController.text.trim(),
        },
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppLocalizations.of(context)!.motDePasseChange} '
            'Un e-mail de confirmation vous a été envoyé.',
          ),
          duration: const Duration(seconds: 7),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );

      // Rediriger vers la page de connexion
      Navigator.of(context).pushReplacementNamed('/login');
    } on DioException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            firstApiErrorMessage(error.response?.data) ??
                'Impossible de modifier le mot de passe. Vérifiez que le lien est encore valide.',
          ),
          duration: const Duration(seconds: 8),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Impossible de modifier le mot de passe. Veuillez réessayer.'),
          duration: const Duration(seconds: 8),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: SimpleAppBar(
        logoPath: theme.brightness == Brightness.dark
            ? 'assets/images/logo_dark.png'
            : 'assets/images/logo_light.png',
      ),
      body: Container(
        decoration: AppTheme.pageDecoration(context),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: AppDecorations.contentContainerDecoration(context),
              child: token == null
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          "Chargement du lien de réinitialisation...",
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Si cela prend trop de temps, vérifiez que vous avez cliqué sur le bon lien",
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    )
                  : Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          Icon(Icons.lock_reset, size: 48, color: AppTheme.primaryOrange),
                          const SizedBox(height: 16),
                          Text(
                            loc.reinitialiserMotDePasse,
                            style: theme.textTheme.headlineSmall,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Lien sécurisé prêt à être utilisé",
                            style: theme.textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: AppDecorations.inputDecoration(
                              context,
                              label: loc.nouveauMotDePasse,
                              icon: Icons.lock_outline,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return loc.motDePasseObligatoire;
                              }
                              if (value.length < 8) return loc.motDePasseCourt;
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _confirmController,
                            obscureText: true,
                            decoration: AppDecorations.inputDecoration(
                              context,
                              label: loc.confirmerMotDePasse,
                              icon: Icons.lock_reset,
                            ),
                            validator: (value) {
                              if (value != _passwordController.text) {
                                return loc.motsDePasseDifferents;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isSubmitting ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryOrange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isSubmitting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(loc.valider),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
