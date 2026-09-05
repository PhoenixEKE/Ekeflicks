import 'package:flutter/material.dart';
import 'package:plateforme_producteurs/core/core.dart';
import 'package:plateforme_producteurs/gen/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    Widget buildSectionTitle(String title) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.paddingMedium),
        child: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    Widget buildBulletPoint(String text) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.paddingSmall),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('• '),
            Expanded(child: Text(text)),
          ],
        ),
      );
    }

    Future<void> launchEmail(String email) async {
      final messenger = ScaffoldMessenger.of(context);
      final uri = Uri(scheme: 'mailto', path: email);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return;
      }

      messenger.showSnackBar(SnackBar(content: Text(l10n.emailLaunchError)));
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.privacyPolicy)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.privacyPolicyTitle,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.paddingLarge),

            // Section 1 - Introduction
            buildSectionTitle(l10n.privacyPolicyIntroductionTitle),
            Text(
              l10n.privacyPolicyIntroductionContent,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppTheme.paddingMedium),

            // Section 2 - Données collectées
            buildSectionTitle(l10n.privacyPolicyDataCollectedTitle),
            Text(
              l10n.privacyPolicyDataCollectedContent,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppTheme.paddingSmall),
            buildBulletPoint(l10n.privacyPolicyDataCollectedItem1),
            buildBulletPoint(l10n.privacyPolicyDataCollectedItem2),
            buildBulletPoint(l10n.privacyPolicyDataCollectedItem3),

            // Section 3 - Utilisation des données
            buildSectionTitle(l10n.privacyPolicyDataUsageTitle),
            Text(
              l10n.privacyPolicyDataUsageContent,
              style: theme.textTheme.bodyMedium,
            ),

            // Section 4 - Partage des données
            buildSectionTitle(l10n.privacyPolicyDataSharingTitle),
            Text(
              l10n.privacyPolicyDataSharingContent,
              style: theme.textTheme.bodyMedium,
            ),

            // Section 5 - Droits des utilisateurs
            buildSectionTitle(l10n.privacyPolicyUserRightsTitle),
            Text(
              l10n.privacyPolicyUserRightsContent,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppTheme.paddingSmall),
            buildBulletPoint(l10n.privacyPolicyUserRightsItem1),
            buildBulletPoint(l10n.privacyPolicyUserRightsItem2),
            buildBulletPoint(l10n.privacyPolicyUserRightsItem3),

            // Section 6 - Cookies
            buildSectionTitle(l10n.privacyPolicyCookiesTitle),
            Text(
              l10n.privacyPolicyCookiesContent,
              style: theme.textTheme.bodyMedium,
            ),

            // Section 7 - Sécurité
            buildSectionTitle(l10n.privacyPolicySecurityTitle),
            Text(
              l10n.privacyPolicySecurityContent,
              style: theme.textTheme.bodyMedium,
            ),

            // Section 8 - Modifications
            buildSectionTitle(l10n.privacyPolicyChangesTitle),
            Text(
              l10n.privacyPolicyChangesContent,
              style: theme.textTheme.bodyMedium,
            ),

            // Section 9 - Contact
            buildSectionTitle(l10n.privacyPolicyContactTitle),
            Text(
              l10n.privacyPolicyContactContent,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppTheme.paddingSmall),
            InkWell(
              onTap: () => launchEmail('contact@votreplateforme.com'),
              child: Text(
                'contact@ephrata.com',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),

            const SizedBox(height: AppTheme.paddingLarge),
            Text(
              l10n.privacyPolicyLastUpdate('01/01/2023'),
              style: theme.textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
