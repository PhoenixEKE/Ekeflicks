import 'package:flutter/material.dart';
import 'package:app_ekeflicks/l10n/app_localizations.dart';
import 'package:app_ekeflicks/widgets/dialog/home_menu_dialog.dart';
import 'base_app_bar.dart';
import 'package:app_ekeflicks/core/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:app_ekeflicks/providers/theme_provider.dart';
import 'package:app_ekeflicks/widgets/dialog/custom_language_dialog.dart';
import 'package:app_ekeflicks/widgets/dialog/language_selector_dialog.dart';

/// AppBar responsive avec gestion de thème et internationalisation
class CustomAppBar extends BaseAppBar {
  final VoidCallback? onLanguageChanged;

  const CustomAppBar({super.key, this.onLanguageChanged});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      elevation: 0,
      titleSpacing: isMobile(context) ? 4 : 12,
      title: Row(
        children: [
          buildLogo(context, height: 40),
          // Pousse tous les autres éléments à droite
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: _AppBarActions(onLanguageChanged: onLanguageChanged),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 900; // seuil responsive
}

class _AppBarActions extends StatelessWidget {
  final VoidCallback? onLanguageChanged;

  const _AppBarActions({this.onLanguageChanged});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isMobile) const _FaqButton(), // 🔄 REMPLACÉ : Tutorials → FAQ
        if (!isMobile) _LanguageSelector(onLanguageChanged: onLanguageChanged),
        const _ThemeToggle(),
        const _AuthActions(),
      ],
    );
  }
}

// 🔄 REMPLACÉ : TutorialsButton → FaqButton
class _FaqButton extends StatelessWidget {
  const _FaqButton();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return IconButton(
      icon: Icon(
        Icons.help_outline,
        color: Theme.of(context).iconTheme.color,
      ), // 🔄 Icône changée
      tooltip: loc.faq, // 🔄 Tooltip changé
      onPressed:
          () => Navigator.of(context).pushNamed('/faq'), // 🔄 Route changée
    );
  }
}

class _LanguageSelector extends StatelessWidget {
  final VoidCallback? onLanguageChanged;

  const _LanguageSelector({this.onLanguageChanged});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return IconButton(
      icon: Icon(Icons.language, color: Theme.of(context).iconTheme.color),
      tooltip: loc.changeLanguage,
      onPressed: () => _showLanguageDialog(context),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    // CORRECTION: Appel simple sans .then()
    CustomLanguageDialog.show(
      context: context,
      languageSelector: const LanguageSelectorDialog(),
      title: AppLocalizations.of(context)?.selectLanguage,
    );

    // Le callback onLanguageChanged sera géré par le LanguageSelectorDialog lui-même
    // lorsqu'une langue est sélectionnée
  }
}

class _ThemeToggle extends StatelessWidget {
  const _ThemeToggle();

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final loc = AppLocalizations.of(context)!;

    return IconButton(
      icon: Icon(
        isDark ? Icons.light_mode : Icons.dark_mode,
        color: Theme.of(context).iconTheme.color,
      ),
      tooltip: isDark ? loc.lightTheme : loc.darkTheme,
      onPressed: () {
        themeProvider.toggleTheme();
      },
    );
  }
}

class _AuthActions extends StatelessWidget {
  const _AuthActions();

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    if (isMobile) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pushNamed('/login'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
            ),
            child: Text(loc.connexion, style: theme.textTheme.labelLarge),
          ),
          IconButton(
            icon: Icon(
              Icons.more_vert,
              size: 20,
              color: Theme.of(context).iconTheme.color,
            ),
            tooltip: loc.menu,
            onPressed: () => showCustomMenuDialog(context, loc),
          ),
        ],
      );
    } else {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pushNamed('/signup'),
            icon: Icon(
              Icons.person_add,
              size: 18,
              color: isDark ? Colors.white70 : theme.colorScheme.secondary,
            ),
            label: Text(
              loc.sinscrire,
              style: TextStyle(
                color: isDark ? Colors.white70 : theme.colorScheme.secondary,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor:
                  isDark ? Colors.white70 : theme.colorScheme.secondary,
              side: BorderSide(
                color: isDark ? Colors.white70 : theme.colorScheme.secondary,
                width: 1.5,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              textStyle: theme.textTheme.labelLarge,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pushNamed('/login'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              textStyle: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
              ),
              elevation: 2,
            ),
            child: Text(loc.connexion),
          ),
        ],
      );
    }
  }
}
