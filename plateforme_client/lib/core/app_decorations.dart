import 'package:flutter/material.dart';
import 'app_theme.dart';

class AppDecorations {
  // ================= INPUT DECORATIONS =================
  static InputDecoration inputDecoration(
    BuildContext context, {
    required String label,
    String? hint,
    IconData? icon,
    Widget? prefix,
    bool isPassword = false,
    bool isDense = false,
    VoidCallback? onToggleVisibility,
  }) {
    final theme = Theme.of(context);

    return InputDecoration(
      labelText: label,
      hintText: hint,
      isDense: isDense,
      prefixIcon:
          icon != null ? Icon(icon, color: AppTheme.primaryOrange) : prefix,
      suffixIcon:
          isPassword
              ? IconButton(
                icon: Icon(
                  onToggleVisibility != null ? Icons.visibility : Icons.lock,
                  color: AppTheme.primaryOrange.withValues(alpha: 0.7),
                ),
                onPressed: onToggleVisibility,
              )
              : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      filled: true,
      fillColor: theme.inputDecorationTheme.fillColor,
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      errorStyle: TextStyle(
        color: AppTheme.errorRed,
        fontSize: theme.textTheme.bodySmall?.fontSize,
      ),
    );
  }

  /// Variante InputDecoration pour navigation TV
  static InputDecoration tvInputDecoration(
    BuildContext context, {
    required String label,
    String? hint,
    IconData? icon,
    bool isPassword = false,
    VoidCallback? onToggleVisibility,
  }) {
    return inputDecoration(
      context,
      label: label,
      hint: hint,
      icon: icon,
      isPassword: isPassword,
      onToggleVisibility: onToggleVisibility,
    ).copyWith(
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        borderSide: const BorderSide(color: AppTheme.primaryOrange, width: 3.0),
      ),
    );
  }

  // ================= LOADING INDICATORS =================
  static Widget loadingIndicator(BuildContext context, {double size = 24}) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 3,
        color: Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }

  static Widget linearLoadingIndicator(BuildContext context) {
    return LinearProgressIndicator(
      minHeight: 4,
      color: AppTheme.primaryOrange,
      backgroundColor: AppTheme.primaryOrange.withValues(alpha: 0.2),
    );
  }

  // ================= BUTTON STYLES =================
  static ButtonStyle primaryButtonStyle(BuildContext context) {
    return ElevatedButton.styleFrom(
      backgroundColor: AppTheme.primaryOrange,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      textStyle: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  static ButtonStyle secondaryButtonStyle(BuildContext context) {
    return OutlinedButton.styleFrom(
      foregroundColor: AppTheme.primaryOrange,
      side: BorderSide(color: AppTheme.primaryOrange),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      textStyle: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  /// Bouton optimisé pour TV (gère l’état focus)
  static ButtonStyle tvButtonStyle({bool isFocused = false}) {
    return ElevatedButton.styleFrom(
      backgroundColor:
          isFocused
              ? AppTheme.primaryOrange.withValues(alpha: 0.9)
              : AppTheme.primaryOrange,
      foregroundColor: Colors.white,
      elevation: isFocused ? 8.0 : 4.0,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }

  // ================= TEXT STYLES =================
  static TextStyle linkTextStyle(BuildContext context) {
    return TextStyle(
      color: AppTheme.primaryOrange,
      decoration: TextDecoration.underline,
    );
  }

  static TextStyle errorTextStyle(BuildContext context) {
    return TextStyle(
      color: AppTheme.errorRed,
      fontWeight: FontWeight.w500,
      fontSize: Theme.of(context).textTheme.bodySmall?.fontSize,
    );
  }

  // ================= BOX DECORATIONS =================
  static BoxDecoration contentContainerDecoration(BuildContext context) {
    return BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 10,
          spreadRadius: 2,
        ),
      ],
    );
  }

  static BoxDecoration cardDecoration(
    BuildContext context, {
    double elevation = 2,
  }) {
    return BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1 * elevation),
          blurRadius: 6 * elevation,
          spreadRadius: 1 * elevation,
          offset: Offset(0, 2 * elevation),
        ),
      ],
    );
  }

  static BoxDecoration primaryGradientDecoration(BuildContext context) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppTheme.primaryOrange.withValues(alpha: 0.8),
          AppTheme.primaryOrange,
        ],
      ),
      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
    );
  }

  static BoxDecoration dialogDecoration(BuildContext context) =>
      contentContainerDecoration(context);

  static BoxDecoration featureItemDecoration(BuildContext context) {
    return BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  /// Décoration pour les images en chargement
  static BoxDecoration imagePlaceholderDecoration(BuildContext context) {
    return BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
    );
  }

  // ================= OVERLAYS & EFFECTS =================
  static BoxDecoration focusedDecoration(BuildContext context) {
    return BoxDecoration(
      border: Border.all(color: AppTheme.primaryOrange, width: 3),
      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      boxShadow: [
        BoxShadow(
          color: AppTheme.primaryOrange.withValues(alpha: 0.3),
          blurRadius: 8,
          spreadRadius: 2,
        ),
      ],
    );
  }

  static BoxDecoration errorDecoration(BuildContext context) {
    return BoxDecoration(
      border: Border.all(color: AppTheme.errorRed, width: 2),
      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
    );
  }

  // ================= FOCUS TV =================
  static ButtonStyle tvOutlinedButtonStyle({bool isFocused = false}) {
    return OutlinedButton.styleFrom(
      foregroundColor: isFocused ? AppTheme.primaryOrange : Colors.white,
      side: BorderSide(
        color: isFocused ? AppTheme.primaryOrange : Colors.grey,
        width: 2,
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}
