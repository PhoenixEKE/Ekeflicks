import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_ekeflicks/l10n/app_localizations.dart';
import 'package:app_ekeflicks/widgets/app_bars/simple_app_bar.dart';
import 'package:app_ekeflicks/ui/legal/terms_of_use_page.dart';
import 'package:app_ekeflicks/ui/legal/privacy_policy_page.dart';
import 'package:app_ekeflicks/ui/subscription/subscription_step1_page.dart';
import 'package:app_ekeflicks/providers/user_provider.dart';
import 'package:app_ekeflicks/providers/profile_provider.dart';
import 'package:app_ekeflicks/core/app_theme.dart';
import 'package:app_ekeflicks/core/app_decorations.dart';
import 'package:dio/dio.dart';
import 'package:app_ekeflicks/utils/api_error_message.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _acceptTerms = false;

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_acceptTerms) {
      _showErrorDialog(AppLocalizations.of(context)!.acceptTermsError);
      return;
    }

    setState(() => _isLoading = true);

    // Stocker les valeurs avant la création
    final identifier = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final firstname = _prenomController.text.trim();
    final lastname = _nomController.text.trim();

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final profileProvider = Provider.of<ProfileProvider>(
        context,
        listen: false,
      );

      // Création de l'utilisateur
      final registered = await userProvider.register(
        identifier: identifier,
        password: password,
        firstname: firstname,
        lastname: lastname,
      );
      if (!registered) {
        if (!mounted) return;
        throw Exception(AppLocalizations.of(context)!.genericError);
      }

      // Charger les profils et sélectionner le profil principal
      await profileProvider.loadProfiles();
      if (profileProvider.hasProfiles) {
        profileProvider.selectProfile(
          profileProvider.mainProfile ??
              profileProvider.availableProfiles.first,
        );
      }

      // Navigation vers la page d'abonnement
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SubscriptionStep1Page()),
        );
      }
    } on DioException catch (dioError) {
      _handleDioError(dioError);
    } catch (e) {
      debugPrint('Erreur finale: $e');
      if (mounted) _showErrorDialog(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleDioError(DioException dioError) {
    String message = AppLocalizations.of(context)!.genericError;

    if (dioError.response != null) {
      final status = dioError.response?.statusCode;
      final data = dioError.response?.data;

      if (status == 400) {
        message = firstApiErrorMessage(data) ?? message;
      } else if (status == 500) {
        message = AppLocalizations.of(context)!.serverError;
      } else {
        message = AppLocalizations.of(context)!.connectionError;
      }
    }

    if (mounted) _showErrorDialog(message);
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: Text(
            AppLocalizations.of(context)!.error,
            style: theme.textTheme.titleLarge,
          ),
          content: Text(message, style: theme.textTheme.bodyMedium),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.of(context)!.ok),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final isWide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      appBar: SimpleAppBar(
        logoPath:
            isDarkMode
                ? 'assets/images/logo_dark.png'
                : 'assets/images/logo_light.png',
      ),
      body: Container(
        decoration: AppTheme.pageDecoration(context),
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? 0 : 24,
              vertical: 32,
            ),
            child: Container(
              width: isWide ? 500 : double.infinity,
              margin: isWide ? const EdgeInsets.all(24) : EdgeInsets.zero,
              padding: const EdgeInsets.all(32),
              decoration: AppDecorations.contentContainerDecoration(context),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      loc.inscriptionTitre,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      loc.inscriptionSousTitre,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _prenomController,
                      decoration: AppDecorations.inputDecoration(
                        context,
                        label: loc.prenom,
                        icon: Icons.person_outline,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return loc.prenomObligatoire;
                        }
                        if (value.length < 2) return loc.prenomTropCourt;
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nomController,
                      decoration: AppDecorations.inputDecoration(
                        context,
                        label: loc.nom,
                        icon: Icons.person_outline,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return loc.nomObligatoire;
                        }
                        if (value.length < 2) return loc.nomTropCourt;
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: AppDecorations.inputDecoration(
                        context,
                        label: '${loc.email} / ${loc.telephone}',
                        icon: Icons.alternate_email,
                      ),
                      validator: (value) {
                        final identifier = value?.trim() ?? '';
                        if (identifier.isEmpty) return loc.emailObligatoire;
                        final phone = identifier.replaceAll(
                          RegExp(r'[^0-9+]'),
                          '',
                        );
                        if (!identifier.contains('@')) {
                          if (!RegExp(
                            r'^\+[1-9][0-9]{7,14}$',
                          ).hasMatch(phone)) {
                            return 'Ajoutez l\'indicatif du pays, par exemple '
                                '+2250102030405';
                          }
                          return null;
                        }
                        final emailRegex = RegExp(
                          r"^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+$",
                        );
                        if (!emailRegex.hasMatch(identifier)) {
                          return loc.emailInvalide;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: AppDecorations.inputDecoration(
                        context,
                        label: loc.motDePasse,
                        icon: Icons.lock_outline,
                        isPassword: true,
                        onToggleVisibility:
                            () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return loc.motDePasseObligatoire;
                        }
                        if (value.length < 8) return loc.motDePasseTropCourt;
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: _acceptTerms,
                          onChanged:
                              (value) =>
                                  setState(() => _acceptTerms = value ?? false),
                          fillColor: WidgetStateProperty.resolveWith<Color>(
                            (states) =>
                                states.contains(WidgetState.selected)
                                    ? AppTheme.primaryOrange
                                    : theme.colorScheme.onSurface.withValues(
                                      alpha: 0.2,
                                    ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              text: '${loc.acceptationTexte1} ',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.8,
                                ),
                              ),
                              children: [
                                TextSpan(
                                  text: loc.conditionsUtilisation,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.primaryOrange,
                                    decoration: TextDecoration.underline,
                                  ),
                                  recognizer:
                                      TapGestureRecognizer()
                                        ..onTap =
                                            () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (_) =>
                                                        const TermsOfUsePage(),
                                              ),
                                            ),
                                ),
                                TextSpan(text: ' ${loc.et} '),
                                TextSpan(
                                  text: loc.politiqueConfidentialite,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.primaryOrange,
                                    decoration: TextDecoration.underline,
                                  ),
                                  recognizer:
                                      TapGestureRecognizer()
                                        ..onTap =
                                            () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (_) =>
                                                        const PrivacyPolicyPage(),
                                              ),
                                            ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: AppDecorations.primaryButtonStyle(context),
                      child:
                          _isLoading
                              ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              )
                              : Text(
                                loc.sinscrire,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: theme.colorScheme.onPrimary,
                                ),
                              ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton(
                        onPressed:
                            () => Navigator.pushReplacementNamed(
                              context,
                              '/login',
                            ),
                        child: RichText(
                          text: TextSpan(
                            text: loc.dejaUnCompte,
                            style: theme.textTheme.bodyMedium,
                            children: [
                              TextSpan(
                                text: ' ${loc.connectezVous}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.primaryOrange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
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
