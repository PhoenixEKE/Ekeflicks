import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_ekeflicks/providers/locale_provider.dart';
import 'package:app_ekeflicks/l10n/app_localizations.dart';

class LanguageSelectorDialog extends StatelessWidget {
  final VoidCallback? onLanguageChanged; // AJOUT: Paramètre optionnel pour le callback

  const LanguageSelectorDialog({super.key, this.onLanguageChanged});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? theme.colorScheme.surface : Colors.white,
      surfaceTintColor: isDark ? theme.colorScheme.surface : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            ListTile(
              leading: Icon(Icons.language, color: theme.colorScheme.primary),
              title: Text('Français', style: TextStyle(color: theme.colorScheme.onSurface)),
              onTap: () {
                localeProvider.setLocale(const Locale('fr'));
                if (onLanguageChanged != null) onLanguageChanged!(); // AJOUT: Callback
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.language, color: theme.colorScheme.primary),
              title: Text('English', style: TextStyle(color: theme.colorScheme.onSurface)),
              onTap: () {
                localeProvider.setLocale(const Locale('en'));
                if (onLanguageChanged != null) onLanguageChanged!(); // AJOUT: Callback
                Navigator.pop(context);
              },
            ),
            // SUPPRESSION: Du bouton Annuler pour éviter les doublons
            // Le bouton Annuler sera géré par le CustomLanguageDialog parent
          ],
        ),
      ),
    );
  }
}