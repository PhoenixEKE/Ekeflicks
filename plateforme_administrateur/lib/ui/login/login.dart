import 'package:flutter/material.dart';
import 'package:plateforme_producteurs/gen/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:plateforme_producteurs/core/core.dart';
import 'package:plateforme_producteurs/providers/locale_provider.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _loading = false;
  bool _obscurePassword = true;
  final ScrollController _scrollController = ScrollController();
  double _offset = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleScroll() {
    setState(() => _offset = _scrollController.offset);
  }

  void _login() {
    if (_formKey.currentState!.validate()) {
      setState(() => _loading = true);
      Future.delayed(const Duration(seconds: 2), () => context.go('/dashboard'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeProvider = context.watch<LocaleProvider>();

    return Scaffold(
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          setState(() => _offset = notification.metrics.pixels);
          return true;
        },
        child: Stack(
          children: [
            _buildAnimatedBackground(),
            SingleChildScrollView(
              controller: _scrollController,
              child: SizedBox(
                height: MediaQuery.of(context).size.height,
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.all(24),
                    child: Card(
                      elevation: 16,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            AppDecorations.borderRadiusLarge),
                      ),
                      color: AppTheme.cardBackground.withOpacity(0.8),
                      shadowColor: AppTheme.primary.withOpacity(0.3),
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildLanguageButton(localeProvider, l10n),
                              _buildHeaderIcon(),
                              const SizedBox(height: 16),
                              _buildTitle(l10n),
                              const SizedBox(height: 32),
                              _buildEmailField(l10n),
                              const SizedBox(height: 20),
                              _buildPasswordField(l10n),
                              const SizedBox(height: 24),
                              _buildLoginButton(l10n),
                              const SizedBox(height: 16),
                              _buildForgotPasswordButton(l10n),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Positioned(
      top: -_offset * 0.4,
      left: -_offset * 0.2,
      right: _offset * 0.2,
      child: Opacity(
        opacity: 0.15,
        child: Container(
          height: MediaQuery.of(context).size.height * 1.5,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.5,
              colors: [
                AppTheme.primary.withOpacity(0.8),
                AppTheme.background.withOpacity(0.1),
              ],
              stops: const [0.1, 1.0],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageButton(LocaleProvider localeProvider, AppLocalizations l10n) {
    return Align(
      alignment: Alignment.topRight,
      child: IconButton(
        icon: const Icon(Icons.language),
        onPressed: localeProvider.toggleLocale,
        tooltip: l10n.changeLanguage,
      ),
    );
  }

  Widget _buildHeaderIcon() {
    return Icon(
      Icons.movie_creation_rounded,
      size: 64,
      color: AppTheme.primary,
    );
  }

  Widget _buildTitle(AppLocalizations l10n) {
    return Text(
      l10n.loginPageTitle,
      style: AppTheme.textTitle.copyWith(
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildEmailField(AppLocalizations l10n) {
    return TextFormField(
      controller: _emailCtrl,
      style: TextStyle(color: AppTheme.textPrimary),
      decoration: AppDecorations.inputDecoration.copyWith(
        labelText: l10n.emailLabel,
        labelStyle: TextStyle(color: AppTheme.textSecondary),
        prefixIcon: Icon(Icons.email, color: AppTheme.primary),
      ),
      validator: (v) => v != null && v.contains('@') ? null : l10n.emailValidationError,
    );
  }

  Widget _buildPasswordField(AppLocalizations l10n) {
    return TextFormField(
      controller: _passwordCtrl,
      obscureText: _obscurePassword,
      style: TextStyle(color: AppTheme.textPrimary),
      decoration: AppDecorations.inputDecoration.copyWith(
        labelText: l10n.passwordLabel,
        labelStyle: TextStyle(color: AppTheme.textSecondary),
        prefixIcon: Icon(Icons.lock, color: AppTheme.primary),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility : Icons.visibility_off,
            color: AppTheme.textSecondary,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
      validator: (v) => v != null && v.length >= 6 ? null : l10n.passwordValidationError,
    );
  }

  Widget _buildLoginButton(AppLocalizations l10n) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _loading ? null : _login,
        style: AppDecorations.elevatedButtonStyle.copyWith(
          backgroundColor: MaterialStateProperty.all(AppTheme.primary),
        ),
        child: _loading
            ? const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Colors.white),
              )
            : Text(
                l10n.loginButton,
                style: AppTheme.textBodyBold.copyWith(
                  letterSpacing: 1.1,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildForgotPasswordButton(AppLocalizations l10n) {
    return TextButton(
      onPressed: () {},
      child: Text(
        l10n.forgotPassword,
        style: TextStyle(
          color: AppTheme.primary,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}