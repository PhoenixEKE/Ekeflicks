import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:plateforme_producteurs/gen/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:plateforme_producteurs/providers/locale_provider.dart';
import 'package:plateforme_producteurs/core/core.dart';
import 'package:plateforme_producteurs/settings/privacy_settings_page.dart';
import 'package:plateforme_producteurs/settings/help_support_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _nameCtrl = TextEditingController(text: 'Prod Média');
  final _emailCtrl = TextEditingController(text: 'prod@example.com');
  final _phoneCtrl = TextEditingController(text: '+33 6 00 00 00 00');
  final _passwordCtrl = TextEditingController();

  bool _obscurePassword = true;
  File? _profileImage;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: Text(l10n.profilePageTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettings(context),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.paddingMedium),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Card(
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.paddingLarge),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildLanguageSelector(context),
                    const SizedBox(height: AppTheme.paddingLarge),
                    _buildAvatar(),
                    const SizedBox(height: AppTheme.paddingLarge),
                    _buildNameField(l10n),
                    const SizedBox(height: AppTheme.paddingMedium),
                    _buildPhoneField(l10n),
                    const SizedBox(height: AppTheme.paddingMedium),
                    _buildEmailField(l10n),
                    const SizedBox(height: AppTheme.paddingMedium),
                    _buildPasswordField(l10n),
                    const SizedBox(height: AppTheme.paddingLarge),
                    _buildUpdateButton(l10n),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageSelector(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final currentLocale = Localizations.localeOf(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.language, color: AppTheme.textWhite70),
        const SizedBox(width: 12),
        DropdownButton<String>(
          dropdownColor: AppTheme.cardBackground,
          value: currentLocale.languageCode,
          iconEnabledColor: AppTheme.primaryOrange,
          items: [
            DropdownMenuItem(value: 'fr', child: Text(l10n.french)),
            DropdownMenuItem(value: 'en', child: Text(l10n.english)),
          ],
          onChanged: (value) {
            if (value != null) {
              localeProvider.setLocale(Locale(value));
            }
          },
        ),
      ],
    );
  }

  Widget _buildAvatar() {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: AppTheme.primaryOrange.withValues(alpha: 0.2),
          backgroundImage: _profileImage != null
              ? FileImage(_profileImage!)
              : null,
          child: _profileImage == null
              ? const Icon(
                  Icons.person_rounded,
                  size: 60,
                  color: AppTheme.textWhite,
                )
              : null,
        ),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.primaryOrange,
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.darkBackground, width: 2),
          ),
          child: IconButton(
            icon: const Icon(Icons.edit, size: 20),
            onPressed: _changePhoto,
          ),
        ),
      ],
    );
  }

  Widget _buildNameField(AppLocalizations l10n) {
    return _buildTextField(
      controller: _nameCtrl,
      label: l10n.nameOrCompany,
      icon: Icons.business,
    );
  }

  Widget _buildPhoneField(AppLocalizations l10n) {
    return _buildTextField(
      controller: _phoneCtrl,
      label: l10n.phoneNumber,
      icon: Icons.phone,
      keyboardType: TextInputType.phone,
    );
  }

  Widget _buildEmailField(AppLocalizations l10n) {
    return _buildTextField(
      controller: _emailCtrl,
      label: l10n.email,
      icon: Icons.email_rounded,
      readOnly: true,
    );
  }

  Widget _buildPasswordField(AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: _buildTextField(
            controller: _passwordCtrl,
            label: l10n.password,
            icon: Icons.lock_rounded,
            obscureText: _obscurePassword,
            readOnly: true,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: AppTheme.textWhite70,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () => _changePasswordDialog(l10n),
          child: Text(l10n.change),
        ),
      ],
    );
  }

  Widget _buildUpdateButton(AppLocalizations l10n) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _saveProfile,
        icon: const Icon(Icons.save_rounded, size: 24),
        label: Text(l10n.updateButton),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    bool readOnly = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      readOnly: readOnly,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppTheme.textWhite),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.textWhite70),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        ),
      ),
    );
  }

  Future<void> _changePhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  void _changePasswordDialog(AppLocalizations l10n) {
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    bool obscureNew = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(l10n.changePassword),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: newPassCtrl,
                    obscureText: obscureNew,
                    decoration: InputDecoration(
                      labelText: l10n.newPassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureNew ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () =>
                            setStateDialog(() => obscureNew = !obscureNew),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmPassCtrl,
                    obscureText: obscureConfirm,
                    decoration: InputDecoration(
                      labelText: l10n.confirmPassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureConfirm
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () => setStateDialog(
                          () => obscureConfirm = !obscureConfirm,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.cancel),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (newPassCtrl.text.isEmpty ||
                        confirmPassCtrl.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.fillAllFields)),
                      );
                      return;
                    }
                    if (newPassCtrl.text != confirmPassCtrl.text) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.passwordsDoNotMatch)),
                      );
                      return;
                    }
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.passwordUpdated)),
                    );
                  },
                  child: Text(l10n.save),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _saveProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.profileUpdated)),
    );
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.privacy_tip),
                title: Text(AppLocalizations.of(context)!.privacySettings),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PrivacySettingsPage(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.help),
                title: Text(AppLocalizations.of(context)!.helpSupport),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HelpSupportPage()),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
