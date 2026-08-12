import 'package:flutter/material.dart';
import 'package:plateforme_administrateur/core/core.dart';
import 'package:plateforme_administrateur/gen/app_localizations.dart';
import 'privacy_policy_page.dart';

class PrivacySettingsPage extends StatefulWidget {
  const PrivacySettingsPage({super.key});

  @override
  State<PrivacySettingsPage> createState() => _PrivacySettingsPageState();
}

class _PrivacySettingsPageState extends State<PrivacySettingsPage> {
  bool _shareData = false;
  bool _showEmail = true;
  bool _twoFactorAuth = false;
  bool _acceptAnalytics = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.privacySettings),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppTheme.paddingLarge),
              child: Text(
                l10n.privacySettingsDescription,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            Card(
              margin: const EdgeInsets.all(AppTheme.paddingMedium),
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text(l10n.shareDataWithPartners),
                    subtitle: Text(l10n.shareDataWithPartnersDescription),
                    value: _shareData,
                    onChanged: (value) => setState(() => _shareData = value),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: Text(l10n.showEmailPublic),
                    subtitle: Text(l10n.showEmailPublicDescription),
                    value: _showEmail,
                    onChanged: (value) => setState(() => _showEmail = value),
                  ),
                ],
              ),
            ),
            Card(
              margin: const EdgeInsets.all(AppTheme.paddingMedium),
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text(l10n.enableTwoFactorAuth),
                    subtitle: Text(l10n.enableTwoFactorAuthDescription),
                    value: _twoFactorAuth,
                    onChanged: (value) => setState(() => _twoFactorAuth = value),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: Text(l10n.acceptAnalyticsTracking),
                    subtitle: Text(l10n.acceptAnalyticsTrackingDescription),
                    value: _acceptAnalytics,
                    onChanged: (value) => setState(() => _acceptAnalytics = value),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppTheme.paddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      _saveSettings(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.settingsSaved),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: Text(l10n.saveSettings),
                  ),
                  const SizedBox(height: AppTheme.paddingMedium),
                  TextButton(
                    onPressed: () => _openPrivacyPolicy(context),
                    child: Text(l10n.viewPrivacyPolicy),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveSettings(BuildContext context) {
    // Implémentez la sauvegarde des préférences
    // Exemple : 
    // final prefs = await SharedPreferences.getInstance();
    // prefs.setBool('shareData', _shareData);
    // prefs.setBool('showEmail', _showEmail);
    // etc.
  }

  void _openPrivacyPolicy(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PrivacyPolicyPage(),
      ),
    );
  }
}