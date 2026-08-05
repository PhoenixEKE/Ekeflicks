import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:app_ekeflicks/l10n/app_localizations.dart';
import 'package:app_ekeflicks/widgets/app_bars/simple_app_bar.dart';
import 'package:app_ekeflicks/core/app_theme.dart';
import 'package:app_ekeflicks/core/app_decorations.dart';
import 'package:app_ekeflicks/providers/user_provider.dart';
import 'package:app_ekeflicks/providers/profile_provider.dart';
import 'package:app_ekeflicks/providers/device_info_provider.dart';
import 'package:app_ekeflicks/ui/profiles/profile_selection_page.dart';
import 'package:app_ekeflicks/widgets/dialog/language_selector_dialog.dart';
import 'package:app_ekeflicks/utils/keyboard_text_manager.dart';
import 'package:app_ekeflicks/utils/keyboard_navigation_utils.dart';
import 'package:app_ekeflicks/widgets/dialog/custom_error_dialog.dart';
import 'package:app_ekeflicks/widgets/dialog/custom_language_dialog.dart';
import 'package:app_ekeflicks/ui/users/post_login_page.dart';
import 'package:app_ekeflicks/services/subscription_progress_service.dart';
import 'package:app_ekeflicks/ui/subscription/subscription_step1_page.dart';
import 'package:app_ekeflicks/ui/subscription/subscription_step2_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with KeyboardNavigationMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _showVirtualKeyboard = false;
  TextEditingController? _focusedController;

  late KeyboardTextManager _emailManager;
  late KeyboardTextManager _passwordManager;

  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _loginButtonFocus = FocusNode();
  final FocusNode _languageFocus = FocusNode();
  final FocusNode _keyboardFocus = FocusNode();
  final FocusNode _keyboardToggleFocus = FocusNode();
  final FocusNode _signupButtonFocus = FocusNode();
  final FocusNode _forgotPasswordFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _emailManager = KeyboardTextManager(_emailController);
    _passwordManager = KeyboardTextManager(_passwordController);

    addKeyHandler(LogicalKeyboardKey.enter, _handleEnterKey);
    addKeyHandler(LogicalKeyboardKey.select, _handleEnterKey);

    _emailFocus.addListener(_onEmailFocusChange);
    _passwordFocus.addListener(_onPasswordFocusChange);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final deviceInfo = Provider.of<DeviceInfoProvider>(context, listen: false);
    if (deviceInfo.isTV) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FocusScope.of(context).requestFocus(_emailFocus);
        _focusedController = _emailController;
        _emailManager.updateCursorPosition();
      });
    }
  }

  KeyboardTextManager? get _currentManager {
    if (_focusedController == _emailController) return _emailManager;
    if (_focusedController == _passwordController) return _passwordManager;
    return null;
  }

  void _onEmailFocusChange() {
    if (_emailFocus.hasFocus) {
      setState(() {
        _focusedController = _emailController;
        _emailManager.updateCursorPosition();
        _showVirtualKeyboard = true;
      });
    }
  }

  void _onPasswordFocusChange() {
    if (_passwordFocus.hasFocus) {
      setState(() {
        _focusedController = _passwordController;
        _passwordManager.updateCursorPosition();
        _showVirtualKeyboard = true;
      });
    }
  }

  void _handleEnterKey() {
    final deviceInfo = Provider.of<DeviceInfoProvider>(context, listen: false);
    if (!deviceInfo.isTV) return;

    if (_loginButtonFocus.hasFocus) {
      _submit();
    } else if (_languageFocus.hasFocus) {
      _showLanguageDialog();
    } else if (_keyboardToggleFocus.hasFocus) {
      _toggleVirtualKeyboard();
    } else if (_emailFocus.hasFocus) {
      FocusScope.of(context).requestFocus(_passwordFocus);
    } else if (_passwordFocus.hasFocus) {
      _submit();
    } else if (_signupButtonFocus.hasFocus) {
      Navigator.pushNamed(context, '/signup');
    } else if (_forgotPasswordFocus.hasFocus) {
      Navigator.pushNamed(context, '/forgot-password');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _loginButtonFocus.dispose();
    _languageFocus.dispose();
    _keyboardFocus.dispose();
    _keyboardToggleFocus.dispose();
    _signupButtonFocus.dispose();
    _forgotPasswordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);

      // Tentative de connexion avec la nouvelle version
      final loginResult = await userProvider.login(
        email: _emailController.text.trim().toLowerCase(),
        password: _passwordController.text.trim(),
      );

      if (loginResult['success'] == true && mounted) {
        await _handleSuccessfulLogin(profileProvider);
      } else if (mounted) {
        // Afficher le message d'erreur spécifique
        CustomErrorDialog.show(
          context: context,
          message: loginResult['message'] ?? 'Erreur de connexion',
        );
      }
    } catch (e) {
      // Gestion des exceptions réseau ou autres erreurs
      if (mounted) {
        _handleExceptionError(e);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSuccessfulLogin(ProfileProvider profileProvider) async {
    try {
      final email = context.read<UserProvider>().currentUser?.email;
      final subscriptionProgress = email == null
          ? null
          : await SubscriptionProgressService().load(email);

      if (subscriptionProgress != null && mounted) {
        final destination = subscriptionProgress.step ==
                SubscriptionStep.payment
            ? SubscriptionStep2Page(
                offerTitle: subscriptionProgress.offerTitle!,
                offerPrice: subscriptionProgress.offerPrice!,
                accountEmail: email,
              )
            : SubscriptionStep1Page(accountEmail: email);
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => destination),
          (route) => false,
        );
        return;
      }

      await profileProvider.loadProfiles();

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) =>
          profileProvider.availableProfiles.length > 1
            ? ProfileSelectionPage() // Sans const
            : PostLoginPage() // Sans const
        ),
        (route) => false,
      );
    } catch (e) {
      CustomErrorDialog.show(
        context: context,
        message: AppLocalizations.of(context)?.genericError ??
            'Une erreur est survenue lors du chargement des profils.',
      );
    }
  }

  void _handleExceptionError(dynamic e) {
    final message = e.toString();
    if (message.contains('network') || message.contains('SocketException')) {
      CustomErrorDialog.show(
        context: context,
        message: AppLocalizations.of(context)?.networkError ??
            'Erreur de connexion. Vérifiez votre accès internet',
      );
    } else if (message.contains('timeout')) {
      CustomErrorDialog.show(
        context: context,
        message: AppLocalizations.of(context)?.timeoutError ??
            'La connexion a expiré. Veuillez réessayer',
      );
    } else {
      CustomErrorDialog.show(
        context: context,
        message: AppLocalizations.of(context)?.genericError ??
            'Une erreur est survenue, veuillez réessayer plus tard.',
      );
    }
  }

  void _showErrorDialog(String message) {
    CustomErrorDialog.show(
      context: context,
      message: message,
    );
  }

  void _showLanguageDialog() {
    // Implémentation de la boîte de dialogue de langue
    // (à adapter selon votre implémentation existante)
    showDialog(
      context: context,
      builder: (context) => const LanguageSelectorDialog(),
    );
  }

  void _handleKeyboardInput(String text) => _currentManager?.insertText(text);
  void _handleKeyboardBackspace() => _currentManager?.backspace();
  void _handleKeyboardEnter() => _submit();

  void _toggleVirtualKeyboard() {
    setState(() {
      _showVirtualKeyboard = !_showVirtualKeyboard;
      if (!_showVirtualKeyboard) {
        if (_emailFocus.hasFocus) FocusScope.of(context).requestFocus(_emailFocus);
        if (_passwordFocus.hasFocus) FocusScope.of(context).requestFocus(_passwordFocus);
      } else {
        FocusScope.of(context).requestFocus(_keyboardFocus);
      }
    });
  }

  Widget _buildMobileDesktopUI(
    BuildContext context,
    AppLocalizations loc,
    ThemeData theme,
    bool isWide,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Container(
        width: isWide ? 450 : double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: AppTheme.cardDecoration(context),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                loc.connexionTitre,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryOrange,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                loc.bienvenueRetour,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                enableSuggestions: false,
                decoration: AppDecorations.inputDecoration(
                  context,
                  label: loc.email,
                  icon: Icons.email_outlined,
                ),
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (email.isEmpty) {
                    return loc.emailObligatoire;
                  }
                  final regex = RegExp(
                    r"^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+$",
                  );
                  if (!regex.hasMatch(email)) {
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
                  onToggleVisibility: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return loc.motDePasseObligatoire;
                  }
                  if (value.length < 8) {
                    return loc.motDePasseTropCourt;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/forgot-password'),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.textTheme.bodyMedium?.color,
                  ),
                  child: Text(
                    loc.motDePasseOublie,
                    style: AppDecorations.linkTextStyle(context),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: AppTheme.lightTheme.elevatedButtonTheme.style,
                child: _isLoading
                    ? AppDecorations.loadingIndicator(context)
                    : Text(
                        loc.seConnecter,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 4,
                children: [
                  Text(loc.pasEncoreCompte, style: theme.textTheme.bodyMedium),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/signup'),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.textTheme.bodyMedium?.color,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      loc.sinscrire,
                      style: AppDecorations.linkTextStyle(context).copyWith(
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 900;
    final deviceInfo = Provider.of<DeviceInfoProvider>(context);

    return Scaffold(
      appBar: SimpleAppBar(
        logoPath: theme.brightness == Brightness.dark
            ? 'assets/images/logo_dark.png'
            : 'assets/images/logo_light.png',
        onLanguagePressed: deviceInfo.isTV ? _showLanguageDialog : null,
        languageFocusNode: deviceInfo.isTV ? _languageFocus : null,
      ),
      body: Container(
        decoration: AppTheme.pageDecoration(context),
        child: Center(
          child: _buildMobileDesktopUI(context, loc, theme, isWide),
        ),
      ),
    );
  }
}
