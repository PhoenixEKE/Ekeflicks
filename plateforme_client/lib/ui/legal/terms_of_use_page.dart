import 'package:flutter/material.dart';
import 'package:app_ekeflicks/l10n/app_localizations.dart';
import 'package:app_ekeflicks/widgets/app_bars/simple_app_bar.dart';

class TermsOfUsePage extends StatelessWidget {
  const TermsOfUsePage({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Fonction pour construire une section avec titre et contenu
    Widget buildSection(String title, String content) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre avec décorations
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 4,
                  height: 24,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Contenu avec style amélioré
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color:
                    isDarkMode
                        ? Colors.grey[900]!.withValues(alpha: 0.3)
                        : Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
                  width: 1,
                ),
              ),
              child: Text(
                content,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Choix du logo selon le thème
    final logoPath =
        theme.brightness == Brightness.light
            ? 'assets/images/logo_light.png'
            : 'assets/images/logo_dark.png';

    return Scaffold(
      appBar: SimpleAppBar(logoPath: logoPath),
      body: Container(
        decoration: BoxDecoration(
          gradient:
              isDarkMode
                  ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.grey[900]!, Colors.black],
                  )
                  : LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      theme.colorScheme.primary.withValues(alpha: 0.03),
                      theme.colorScheme.primary.withValues(alpha: 0.01),
                    ],
                  ),
        ),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1200),
            margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDarkMode ? 0.4 : 0.1),
                  blurRadius: 25,
                  spreadRadius: 5,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // En-tête avec icône
                    Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.assignment,
                            size: 48,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            loc.termsOfUseTitle,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                              letterSpacing: 0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 3,
                            width: 80,
                            margin: const EdgeInsets.only(bottom: 24),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.5,
                              ),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Introduction avec style spécial
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 32),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.3,
                          ),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        loc.termsIntro,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontStyle: FontStyle.italic,
                          height: 1.6,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    // Liste des sections
                    buildSection(loc.terms1Title, loc.terms1Content),
                    buildSection(loc.terms2Title, loc.terms2Content),
                    buildSection(
                      loc.terms3Title,
                      loc.terms3Content.replaceAll(r'\n', '\n'),
                    ),
                    buildSection(
                      loc.terms4Title,
                      loc.terms4Content.replaceAll(r'\n', '\n'),
                    ),
                    buildSection(
                      loc.terms5Title,
                      loc.terms5Content.replaceAll(r'\n', '\n'),
                    ),
                    buildSection(
                      loc.terms6Title,
                      loc.terms6Content.replaceAll(r'\n', '\n'),
                    ),
                    buildSection(
                      loc.terms7Title,
                      loc.terms7Content.replaceAll(r'\n', '\n'),
                    ),
                    buildSection(
                      loc.terms8Title,
                      loc.terms8Content.replaceAll(r'\n', '\n'),
                    ),
                    buildSection(loc.terms9Title, loc.terms9Content),
                    buildSection(loc.terms10Title, loc.terms10Content),
                    buildSection(
                      loc.terms11Title,
                      '${loc.terms11Content} ${loc.terms12Content}',
                    ),

                    // Pied de page
                    const SizedBox(height: 32),
                    Center(
                      child: Text(
                        '© ${DateTime.now().year} EkeFlicks. ${loc.allRightsReserved}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
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
