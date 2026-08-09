import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

import 'package:app_ekeflicks/core/app_theme.dart';
import 'package:app_ekeflicks/providers/locale_provider.dart';
import 'package:app_ekeflicks/providers/profile_provider.dart';
import 'package:app_ekeflicks/providers/theme_provider.dart';
import 'package:app_ekeflicks/providers/user_provider.dart';
import 'package:app_ekeflicks/src/models/profile.dart';
import 'package:app_ekeflicks/utils/api_error_message.dart';

class AccountSettingsDialog extends StatefulWidget {
  const AccountSettingsDialog({super.key, required this.profile});

  final Profile profile;

  @override
  State<AccountSettingsDialog> createState() => _AccountSettingsDialogState();
}

class _AccountSettingsDialogState extends State<AccountSettingsDialog> {
  final _pinController = TextEditingController();
  final _oldPinController = TextEditingController();
  bool _adultProfilesLocked = false;
  bool _childHistoryEnabled = true;
  bool _safeSearchEnabled = true;
  bool _notificationsEnabled = true;
  int _maximumAge = 13;
  String _territory = 'FR';
  bool _saving = false;
  bool _hasPin = false;

  @override
  void initState() {
    super.initState();
    _maximumAge = widget.profile.age ?? 13;
    _territory = widget.profile.country?.name ?? 'FR';
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> parental = const {};
    try {
      final response = await context
          .read<ProfileProvider>()
          .apiClient
          .dio
          .get<Object>('/profiles/${widget.profile.id}/');
      if (response.data is Map) {
        parental = Map<String, dynamic>.from(response.data! as Map);
      }
    } catch (_) {
      // The form remains usable with safe defaults when the API is unavailable.
    }
    if (!mounted) return;
    setState(() {
      _adultProfilesLocked = parental['adult_profiles_locked'] == true;
      _hasPin = parental['has_parental_pin'] == true;
      _childHistoryEnabled = parental['child_history_enabled'] != false;
      _safeSearchEnabled = parental['safe_search_enabled'] != false;
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    });
  }

  Future<void> _save() async {
    final pin = _pinController.text.trim();
    if (_adultProfilesLocked && !_hasPin && !RegExp(r'^\d{4,6}$').hasMatch(pin)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le PIN doit contenir entre 4 et 6 chiffres.'),
          duration: Duration(seconds: 7),
        ),
      );
      return;
    }
    if (_hasPin && pin.isNotEmpty && !RegExp(r'^\d{4,6}$').hasMatch(_oldPinController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saisissez votre ancien PIN pour le modifier.'),
          duration: Duration(seconds: 7),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_enabled', _notificationsEnabled);
      await context.read<ProfileProvider>().apiClient.dio.patch<Object>(
        '/profiles/${widget.profile.id}/',
        data: {
          'age': _maximumAge,
          'country_code': _territory,
          if (pin.isNotEmpty) 'pin_code': pin,
          if (pin.isNotEmpty && _hasPin) 'old_pin': _oldPinController.text,
          'adult_profiles_locked': _adultProfilesLocked,
          'child_history_enabled': _childHistoryEnabled,
          'safe_search_enabled': _safeSearchEnabled,
        },
      );
      if (mounted) Navigator.of(context).pop(true);
    } on DioException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              firstApiErrorMessage(error.response?.data) ??
                  'Impossible d’enregistrer les paramètres. Vérifiez les informations saisies.',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 8),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d’enregistrer les paramètres. Veuillez réessayer.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 8),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _forgotPin() async {
    final userProvider = context.read<UserProvider>();
    var email = userProvider.currentUser?.email ?? '';
    if (email.isEmpty) {
      final controller = TextEditingController();
      email = await showDialog<String>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Adresse e-mail obligatoire'),
              content: TextField(
                controller: controller,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Votre adresse e-mail'),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Annuler'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
                  child: const Text('Continuer'),
                ),
              ],
            ),
          ) ??
          '';
      controller.dispose();
      if (email.isEmpty || !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Adresse e-mail invalide.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 7),
            ),
          );
        }
        return;
      }
      try {
        await userProvider.updatePersonalInfo(
          email: email,
          phone: userProvider.accountPhone,
        );
      } on DioException catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                firstApiErrorMessage(error.response?.data) ??
                    'Cette adresse e-mail ne peut pas être utilisée.',
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 8),
            ),
          );
        }
        return;
      }
    }
    try {
      await context.read<ProfileProvider>().apiClient.dio.post<Object>(
        '/profiles/${widget.profile.id}/request-pin-reset/',
        data: {'email': email},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Un lien de modification du PIN a été envoyé à $email.'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 7),
          ),
        );
      }
    } on DioException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              firstApiErrorMessage(error.response?.data) ??
                  "Impossible d'envoyer le lien de modification du PIN.",
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 8),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    _oldPinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620, maxHeight: 720),
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Paramètres'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                )
              ],
            ),
            body: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _title('Contrôle parental', Icons.family_restroom),
                TextField(
                  controller: _oldPinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  enabled: _hasPin,
                  decoration: const InputDecoration(
                    labelText: 'Ancien PIN',
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _pinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: 'Nouveau PIN (4 à 6 chiffres)',
                    prefixIcon: Icon(Icons.pin),
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_hasPin)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _forgotPin,
                      child: const Text('PIN oublié ? Recevoir un lien par e-mail'),
                    ),
                  ),
                SwitchListTile(
                  value: _adultProfilesLocked,
                  onChanged: (value) => setState(() => _adultProfilesLocked = value),
                  title: const Text('Verrouiller les profils adultes'),
                  subtitle: const Text('Le PIN sera demandé pour quitter un espace enfant.'),
                ),
                DropdownButtonFormField<int>(
                  value: [3, 7, 10, 13, 16, 18].contains(_maximumAge) ? _maximumAge : 13,
                  decoration: const InputDecoration(
                    labelText: 'Classification maximale',
                    border: OutlineInputBorder(),
                  ),
                  items: [3, 7, 10, 13, 16, 18]
                      .map((age) => DropdownMenuItem(
                            value: age,
                            child: Text('$age ans'),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => _maximumAge = value ?? 13),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: ['FR', 'CI', 'SN', 'CM', 'US'].contains(_territory) ? _territory : 'FR',
                  decoration: const InputDecoration(
                    labelText: 'Territoire de classification',
                    border: OutlineInputBorder(),
                  ),
                  items: const {
                    'FR': 'France',
                    'CI': 'Côte d’Ivoire',
                    'SN': 'Sénégal',
                    'CM': 'Cameroun',
                    'US': 'États-Unis'
                  }.entries
                      .map((entry) => DropdownMenuItem(
                            value: entry.key,
                            child: Text(entry.value),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => _territory = value ?? 'FR'),
                ),
                SwitchListTile(
                  value: _childHistoryEnabled,
                  onChanged: (v) => setState(() => _childHistoryEnabled = v),
                  title: const Text('Historique enfant'),
                ),
                SwitchListTile(
                  value: _safeSearchEnabled,
                  onChanged: (v) => setState(() => _safeSearchEnabled = v),
                  title: const Text('Recherche adaptée aux enfants'),
                  subtitle: const Text('Masque les résultats dépassant la classification autorisée.'),
                ),
                const Divider(height: 32),
                _title('Application', Icons.tune),
                SwitchListTile(
                  value: context.watch<ThemeProvider>().themeMode == ThemeMode.light,
                  onChanged: (_) => context.read<ThemeProvider>().toggleTheme(),
                  title: const Text('Thème clair'),
                ),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: const Text('Langue'),
                  subtitle: Text(
                    Localizations.localeOf(context).languageCode == 'fr' ? 'Français' : 'English',
                  ),
                  trailing: const Icon(Icons.swap_horiz),
                  onTap: () => context.read<LocaleProvider>().toggleLocale(),
                ),
                SwitchListTile(
                  value: _notificationsEnabled,
                  onChanged: (v) => setState(() => _notificationsEnabled = v),
                  title: const Text('Notifications'),
                ),
              ],
            ),
            bottomNavigationBar: Padding(
              padding: const EdgeInsets.all(20),
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryOrange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: _saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save),
                label: const Text('Enregistrer les paramètres'),
              ),
            ),
          ),
        ),
      );

  Widget _title(String label, IconData icon) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryOrange),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      );
}
