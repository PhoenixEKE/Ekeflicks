import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_ekeflicks/l10n/app_localizations.dart';
import 'package:app_ekeflicks/widgets/app_bars/simple_app_bar.dart';
import 'package:app_ekeflicks/core/app_theme.dart';
import 'package:app_ekeflicks/core/app_decorations.dart';


class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Style des titres de section
    TextStyle sectionTitleStyle = theme.textTheme.headlineSmall!.copyWith(
      color: AppTheme.primaryOrange,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.5,
    );

    // Style des sous-titres
    TextStyle subSectionTitleStyle = theme.textTheme.titleLarge!.copyWith(
      fontWeight: FontWeight.w600,
      color: isDarkMode ? Colors.white.withOpacity(0.9) : Colors.black87,
    );

    // Style du contenu
    TextStyle contentStyle = theme.textTheme.bodyLarge!.copyWith(
      height: 1.8,
      color: isDarkMode ? Colors.white.withOpacity(0.8) : Colors.black87,
    );

    return Scaffold(
      appBar: SimpleAppBar(
        logoPath: isDarkMode
            ? 'assets/images/logo_dark.png'
            : 'assets/images/logo_light.png',
      ),
      body: Container(
        decoration: AppTheme.pageDecoration(context),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1200),
            margin: const EdgeInsets.symmetric(vertical: 16),
            child: Card(
              elevation: 4,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // En-tête
                    Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.privacy_tip_outlined,
                            size: 48,
                            color: AppTheme.primaryOrange,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            t.privacyPolicyTitle,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: AppTheme.primaryOrange,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 3,
                            width: 80,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryOrange.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Introduction
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryOrange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                        border: Border.all(
                          color: AppTheme.primaryOrange.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        t.privacyPolicyIntro,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    // Contenu des sections
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSection(
                            context,
                            t.section1Title,
                            [
                              _buildSubSection(t.section1_1Title, t.section1_1Text, 
                                subSectionTitleStyle, contentStyle),
                              _buildSubSection(t.section1_2Title, t.section1_2Text, 
                                subSectionTitleStyle, contentStyle),
                            ],
                            sectionTitleStyle,
                          ),

                          _buildSection(
                            context,
                            t.section2Title,
                            [
                              _buildSubSection(t.section2_1Title, t.section2_1Text, 
                                subSectionTitleStyle, contentStyle),
                              _buildSubSection(t.section2_2Title, t.section2_2Text, 
                                subSectionTitleStyle, contentStyle),
                              _buildSubSection(t.section2_3Title, t.section2_3Text, 
                                subSectionTitleStyle, contentStyle),
                            ],
                            sectionTitleStyle,
                          ),

                          _buildSection(
                            context,
                            t.section3Title,
                            [
                              _buildSubSection(t.section3_1Title, t.section3_1Text, 
                                subSectionTitleStyle, contentStyle),
                              _buildSubSection(t.section3_2Title, t.section3_2Text, 
                                subSectionTitleStyle, contentStyle),
                            ],
                            sectionTitleStyle,
                          ),

                          _buildSimpleSection(t.section4Title, t.section4Text, 
                            sectionTitleStyle, contentStyle),
                          _buildSimpleSection(t.section5Title, t.section5Text, 
                            sectionTitleStyle, contentStyle),
                          _buildSimpleSection(t.section6Title, t.section6Text, 
                            sectionTitleStyle, contentStyle),

                          // Pied de page
                          Padding(
                            padding: const EdgeInsets.only(top: 32),
                            child: Center(
                              child: Column(
                                children: [
                                  Divider(
                                    color: AppTheme.primaryOrange.withOpacity(0.2),
                                    thickness: 1,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    t.privacyPolicyThanks,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontStyle: FontStyle.italic,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '© ${DateTime.now().year} EkeFlicks',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: isDarkMode 
                                        ? Colors.white.withOpacity(0.6) 
                                        : Colors.black.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
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

  Widget _buildSection(
    BuildContext context,
    String title,
    List<Widget> children,
    TextStyle titleStyle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 24,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: AppTheme.primaryOrange,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Expanded(
              child: Text(
                title,
                style: titleStyle,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...children,
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSubSection(
    String title,
    String content,
    TextStyle titleStyle,
    TextStyle contentStyle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: titleStyle,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Text(
            content,
            style: contentStyle,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSimpleSection(
    String title,
    String content,
    TextStyle titleStyle,
    TextStyle contentStyle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: titleStyle,
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: contentStyle,
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}