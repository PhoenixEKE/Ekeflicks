import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_ekeflicks/l10n/app_localizations.dart';
import 'package:app_ekeflicks/core/app_theme.dart';
import 'package:app_ekeflicks/core/app_decorations.dart';
import 'package:app_ekeflicks/providers/user_provider.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  Future<void> _changePassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showErrorSnackbar('Les mots de passe ne correspondent pas');
      return;
    }

    if (_newPasswordController.text.length < 8) {
      _showErrorSnackbar('Le mot de passe doit contenir au moins 8 caractères');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      await userProvider.changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      if (!mounted) return;

      _showSuccessSnackbar('Mot de passe modifié avec succès');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      final message =
          e is StateError
              ? e.message
              : 'Impossible de modifier le mot de passe pour le moment.';

      _showErrorSnackbar(message);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc?.modifierMotDePasse ?? 'Modifier le mot de passe'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _currentPasswordController,
                      obscureText: _obscureCurrentPassword,
                      decoration: AppDecorations.inputDecoration(
                        context,
                        label: loc?.motDePasseActuel ?? 'Mot de passe actuel',
                        icon: Icons.lock,
                        isPassword: true,
                        onToggleVisibility:
                            () => setState(
                              () =>
                                  _obscureCurrentPassword =
                                      !_obscureCurrentPassword,
                            ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _newPasswordController,
                      obscureText: _obscureNewPassword,
                      decoration: AppDecorations.inputDecoration(
                        context,
                        label: loc?.nouveauMotDePasse ?? 'Nouveau mot de passe',
                        icon: Icons.lock_outline,
                        isPassword: true,
                        onToggleVisibility:
                            () => setState(
                              () => _obscureNewPassword = !_obscureNewPassword,
                            ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      decoration: AppDecorations.inputDecoration(
                        context,
                        label:
                            loc?.confirmerMotDePasse ??
                            'Confirmer le mot de passe',
                        icon: Icons.lock_reset,
                        isPassword: true,
                        onToggleVisibility:
                            () => setState(
                              () =>
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword,
                            ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _changePassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child:
                            _isLoading
                                ? CircularProgressIndicator(color: Colors.white)
                                : Text(loc?.modifier ?? 'Modifier'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
