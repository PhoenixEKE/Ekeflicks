import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_links/app_links.dart';
import 'package:app_ekeflicks/l10n/app_localizations.dart';
import 'package:app_ekeflicks/widgets/app_bars/simple_app_bar.dart';
import 'package:app_ekeflicks/core/app_theme.dart';
import 'package:app_ekeflicks/core/app_decorations.dart';
import 'package:app_ekeflicks/providers/user_provider.dart';
import 'package:app_ekeflicks/src/models/password_reset_confirm.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isSubmitting = false;

  String? uid;
  String? token;

  late final AppLinks _appLinks;
  Stream<Uri?>? _uriStream;

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();
    _initDeepLinks();
  }

  /// Initialise les deep links
  Future<void> _initDeepLinks() async {
    try {
      // CORRECTION: Utiliser getInitialLink au lieu de getInitialUri
      final initialUri = await _appLinks.getInitialLink();
      _parseLink(initialUri);

      // Écoute continue des liens entrants
      _uriStream = _appLinks.uriLinkStream;
      _uriStream!.listen((uri) {
        _parseLink(uri);
      }, onError: (err) {
        print('Erreur flux deep link: $err');
      });
    } catch (e) {
      print('Erreur lors de l\'initialisation des deep links: $e');
    }
  }

  void _parseLink(Uri? uri) {
    if (uri == null) return;
    
    // Méthode 1: Vérifier les segments de chemin
    final segments = uri.pathSegments;
    if (segments.length >= 3 &&
        segments.contains('password-reset-confirm')) {
      // Trouver l'index du segment password-reset-confirm
      final confirmIndex = segments.indexOf('password-reset-confirm');
      if (confirmIndex + 2 < segments.length) {
        setState(() {
          uid = segments[confirmIndex + 1];
          token = segments[confirmIndex + 2];
        });
      }
    }
    
    // Méthode 2: Vérifier les paramètres de requête (alternative)
    final queryParams = uri.queryParameters;
    if (queryParams.containsKey('uid') && queryParams.containsKey('token')) {
      setState(() {
        uid = queryParams['uid'];
        token = queryParams['token'];
      });
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (uid == null || token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lien de réinitialisation invalide.")),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final userProvider = context.read<UserProvider>();

      // CORRECTION: Créer l'objet PasswordResetConfirm correctement
      final resetData = PasswordResetConfirm(
        (b) => b
          ..uid = uid!
          ..token = token!
          ..newPassword = _passwordController.text.trim(),
      );

      await userProvider.apiClient.getAuthApi().authPasswordResetConfirmCreate(
        data: resetData, // Passer l'objet, pas un Map
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.motDePasseChange)),
      );

      Navigator.of(context).pushReplacementNamed('/login');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de la réinitialisation: ${e.toString()}")),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    _uriStream?.drain(); // Arrêter l'écoute du flux
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
              child: uid == null || token == null
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
                            "UID: ${uid!.substring(0, 8)}... | Token: ${token!.substring(0, 8)}...",
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
                              child: _isSubmitting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
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