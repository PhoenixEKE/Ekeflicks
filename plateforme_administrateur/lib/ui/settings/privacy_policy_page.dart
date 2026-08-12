import 'package:flutter/material.dart';
import 'package:plateforme_administrateur/core/core.dart';
import 'package:plateforme_administrateur/gen/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    Widget _buildSectionTitle(String title) {
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

    Widget _buildBulletPoint(String text) {
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

    Future<void> _launchEmail(String email) async {
      final Uri uri = Uri(
        scheme: 'mailto',
        path: email,
      );
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.emailLaunchError)),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.privacyPolicy),
      ),
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
            _buildSectionTitle(l10n.privacyPolicyIntroductionTitle),
            Text(
              l10n.privacyPolicyIntroductionContent,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppTheme.paddingMedium),
            
            // Section 2 - Données collectées
            _buildSectionTitle(l10n.privacyPolicyDataCollectedTitle),
            Text(
              l10n.privacyPolicyDataCollectedContent,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppTheme.paddingSmall),
            _buildBulletPoint(l10n.privacyPolicyDataCollectedItem1),
            _buildBulletPoint(l10n.privacyPolicyDataCollectedItem2),
            _buildBulletPoint(l10n.privacyPolicyDataCollectedItem3),
            
            // Section 3 - Utilisation des données
            _buildSectionTitle(l10n.privacyPolicyDataUsageTitle),
            Text(
              l10n.privacyPolicyDataUsageContent,
              style: theme.textTheme.bodyMedium,
            ),
            
            // Section 4 - Partage des données
            _buildSectionTitle(l10n.privacyPolicyDataSharingTitle),
            Text(
              l10n.privacyPolicyDataSharingContent,
              style: theme.textTheme.bodyMedium,
            ),
            
            // Section 5 - Droits des utilisateurs
            _buildSectionTitle(l10n.privacyPolicyUserRightsTitle),
            Text(
              l10n.privacyPolicyUserRightsContent,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppTheme.paddingSmall),
            _buildBulletPoint(l10n.privacyPolicyUserRightsItem1),
            _buildBulletPoint(l10n.privacyPolicyUserRightsItem2),
            _buildBulletPoint(l10n.privacyPolicyUserRightsItem3),
            
            // Section 6 - Cookies
            _buildSectionTitle(l10n.privacyPolicyCookiesTitle),
            Text(
              l10n.privacyPolicyCookiesContent,
              style: theme.textTheme.bodyMedium,
            ),
            
            // Section 7 - Sécurité
            _buildSectionTitle(l10n.privacyPolicySecurityTitle),
            Text(
              l10n.privacyPolicySecurityContent,
              style: theme.textTheme.bodyMedium,
            ),
            
            // Section 8 - Modifications
            _buildSectionTitle(l10n.privacyPolicyChangesTitle),
            Text(
              l10n.privacyPolicyChangesContent,
              style: theme.textTheme.bodyMedium,
            ),
            
            // Section 9 - Contact
            _buildSectionTitle(l10n.privacyPolicyContactTitle),
            Text(
              l10n.privacyPolicyContactContent,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppTheme.paddingSmall),
            InkWell(
              onTap: () => _launchEmail('contact@votreplateforme.com'),
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