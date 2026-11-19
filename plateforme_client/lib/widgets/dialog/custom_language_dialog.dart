import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_ekeflicks/l10n/app_localizations.dart';
import 'package:app_ekeflicks/providers/device_info_provider.dart';

class CustomLanguageDialog {
  // Méthode pour afficher un dialogue de langue responsive
  static void show({
    required BuildContext context,
    required Widget languageSelector,
    String? title,
  }) {
    final loc = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) {
        return _buildResponsiveDialog(
          context: context,
          title: title ?? loc?.selectLanguage ?? 'Sélectionner la langue',
          content: languageSelector,
          icon: Icons.language,
          actions: [
            _buildDialogButton(
              context: context,
              text: loc?.cancel ?? 'Annuler',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  // Construction du dialogue responsive
  static Widget _buildResponsiveDialog({
    required BuildContext context,
    required String title,
    required Widget content,
    required IconData icon,
    required List<Widget> actions,
  }) {
    final deviceInfo = Provider.of<DeviceInfoProvider>(context, listen: false);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Adaptation pour TV (taille optimisée)
    if (deviceInfo.isTV) {
      return Dialog(
        backgroundColor: isDark ? theme.colorScheme.surface : Colors.white,
        surfaceTintColor: isDark ? theme.colorScheme.surface : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Container(
          width: screenWidth * 0.6, // 60% de la largeur de l'écran
          height: screenHeight * 0.5, // 50% de la hauteur de l'écran
          constraints: const BoxConstraints(
            maxWidth: 600, // Maximum pour les très grands écrans
            maxHeight: 500, // Maximum pour la hauteur
          ),
          padding: const EdgeInsets.all(24.0), // Réduit de 32 à 24
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDialogHeader(context, title, icon, isTV: true),
              const SizedBox(height: 20), // Réduit de 24 à 20
              Expanded(child: content),
              const SizedBox(height: 20), // Réduit de 32 à 20
              _buildTVActions(actions),
            ],
          ),
        ),
      );
    }

    // Adaptation pour desktop (taille optimisée)
    if (deviceInfo.isDesktop) {
      return Dialog(
        backgroundColor: isDark ? theme.colorScheme.surface : Colors.white,
        surfaceTintColor: isDark ? theme.colorScheme.surface : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: screenWidth * 0.4, // 40% de la largeur écran
            maxHeight: screenHeight * 0.6, // 60% de la hauteur écran
          ),
          child: Container(
            padding: const EdgeInsets.all(20.0), // Réduit de 24 à 20
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDialogHeader(context, title, icon),
                const SizedBox(height: 16), // Réduit de 20 à 16
                Expanded(child: content),
                const SizedBox(height: 16), // Réduit de 24 à 16
                _buildDesktopActions(actions),
              ],
            ),
          ),
        ),
      );
    }

    // Version mobile (taille optimisée)
    return AlertDialog(
      backgroundColor: isDark ? theme.colorScheme.surface : Colors.white,
      surfaceTintColor: isDark ? theme.colorScheme.surface : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      title: _buildDialogHeader(context, title, icon),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: screenHeight * 0.4, // 40% de la hauteur écran
        ),
        child: SingleChildScrollView(
          // Ajout du scroll si nécessaire
          child: content,
        ),
      ),
      actions: actions,
    );
  }

  // En-tête du dialogue (déjà bien dimensionné)
  static Widget _buildDialogHeader(
    BuildContext context,
    String title,
    IconData icon, {
    bool isTV = false,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isTV ? 14 : 10, // Légère réduction
        horizontal: isTV ? 18 : 14, // Légère réduction
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(
          isTV ? 14.0 : 10.0,
        ), // Coins légèrement moins arrondis
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: theme.colorScheme.onPrimary,
            size: isTV ? 26 : 22, // Légère réduction
          ),
          SizedBox(width: isTV ? 14 : 10), // Légère réduction
          Expanded(
            // Ajout de Expanded pour les textes longs
            child: Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
                fontSize: isTV ? 20 : 18, // Légère réduction
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Bouton de dialogue (déjà bien dimensionné)
  static Widget _buildDialogButton({
    required BuildContext context,
    required String text,
    required VoidCallback onPressed,
  }) {
    final theme = Theme.of(context);

    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: theme.colorScheme.primary,
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 6,
        ), // Légère réduction
        textStyle: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      child: Text(text),
    );
  }

  // Actions pour TV (horizontalement centrées)
  static Widget _buildTVActions(List<Widget> actions) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: actions,
    );
  }

  // Actions pour desktop (alignées à droite)
  static Widget _buildDesktopActions(List<Widget> actions) {
    return Row(mainAxisAlignment: MainAxisAlignment.end, children: actions);
  }
}
