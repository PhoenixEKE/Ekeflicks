import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_ekeflicks/l10n/app_localizations.dart';
import 'package:app_ekeflicks/providers/device_info_provider.dart';

class CustomErrorDialog {
  // Méthode pour afficher un dialogue d'erreur responsive
  static void show({
    required BuildContext context,
    required String message,
    String? title,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final loc = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) {
        return _buildResponsiveDialog(
          context: context,
          title: title ?? loc?.error ?? 'Erreur',
          content: Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color:
                  isDark
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurface,
              height: 1.4,
            ),
            textAlign: TextAlign.start,
          ),
          icon: Icons.error_outline,
          actions: [
            _buildDialogButton(
              context: context,
              text: loc?.ok ?? 'OK',
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

    // Adaptation pour TV (taille plus grande)
    if (deviceInfo.isTV) {
      return Dialog(
        backgroundColor: isDark ? theme.colorScheme.surface : Colors.white,
        surfaceTintColor: isDark ? theme.colorScheme.surface : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Container(
          width: 600,
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDialogHeader(context, title, icon, isTV: true),
              const SizedBox(height: 24),
              content,
              const SizedBox(height: 32),
              _buildTVActions(actions),
            ],
          ),
        ),
      );
    }

    // Adaptation pour desktop (taille moyenne)
    if (deviceInfo.isDesktop) {
      return Dialog(
        backgroundColor: isDark ? theme.colorScheme.surface : Colors.white,
        surfaceTintColor: isDark ? theme.colorScheme.surface : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Container(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDialogHeader(context, title, icon),
                const SizedBox(height: 20),
                content,
                const SizedBox(height: 24),
                _buildDesktopActions(actions),
              ],
            ),
          ),
        ),
      );
    }

    // Version mobile (taille standard)
    return AlertDialog(
      backgroundColor: isDark ? theme.colorScheme.surface : Colors.white,
      surfaceTintColor: isDark ? theme.colorScheme.surface : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDialogHeader(context, title, icon),
          const SizedBox(height: 20),
          content,
        ],
      ),
      actions: actions,
    );
  }

  // En-tête du dialogue
  static Widget _buildDialogHeader(
    BuildContext context,
    String title,
    IconData icon, {
    bool isTV = false,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isTV ? 16 : 12,
        horizontal: isTV ? 20 : 16,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(isTV ? 16.0 : 12.0),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.onPrimary, size: isTV ? 28 : 24),
          SizedBox(width: isTV ? 16 : 12),
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
              fontSize: isTV ? 22 : null,
            ),
          ),
        ],
      ),
    );
  }

  // Bouton de dialogue
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
