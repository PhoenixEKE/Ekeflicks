import 'package:flutter/material.dart';
import 'app_theme.dart';

class AppDecorations {
  // Border radius - utilise maintenant les constantes de AppTheme
  static double get borderRadiusSmall => AppTheme.borderRadiusSmall;
  static double get borderRadiusMedium => AppTheme.borderRadiusMedium;
  static double get borderRadiusLarge => AppTheme.borderRadiusLarge;

  // Card shapes
  static ShapeBorder get cardShape => RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(borderRadiusMedium),
  );

  // Dialog shapes
  static ShapeBorder get dialogShape => RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(borderRadiusLarge),
  );

  // AppBar decorations
  static BoxDecoration get appBarGradientBackground => BoxDecoration(
    gradient: LinearGradient(
      colors: [AppTheme.primary, AppTheme.secondary],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  // Bottom navigation bar
  static BoxDecoration get bottomNavBarDecoration => BoxDecoration(
    color: AppTheme.cardBackground,
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.3),
        blurRadius: 10,
        offset: const Offset(0, -5),
      ),
    ],
  );

  // Input decorations
  static InputDecoration get inputDecoration => InputDecoration(
    filled: true,
    fillColor: Colors.grey[850],
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadiusMedium),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadiusMedium),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadiusMedium),
      borderSide: BorderSide(color: AppTheme.primary, width: 2),
    ),
    contentPadding: EdgeInsets.symmetric(
      horizontal: AppTheme.paddingMedium,
      vertical: AppTheme.paddingSmall,
    ),
  );

  // Outline input border
  static InputBorder get outlineInputBorder => OutlineInputBorder(
    borderRadius: BorderRadius.circular(borderRadiusMedium),
    borderSide: BorderSide(color: AppTheme.grey),
  );

  // Focused outline input border
  static InputBorder get outlineInputBorderFocused => OutlineInputBorder(
    borderRadius: BorderRadius.circular(borderRadiusMedium),
    borderSide: BorderSide(color: AppTheme.primary, width: 2),
  );

  // Card decoration
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: AppTheme.cardBackground,
    borderRadius: BorderRadius.circular(borderRadiusMedium),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.3),
        blurRadius: 6,
        offset: const Offset(0, 3),
      ),
    ],
  );

  // Elevated button style
  static ButtonStyle get elevatedButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: AppTheme.primary,
    foregroundColor: AppTheme.textPrimary,
    padding: EdgeInsets.symmetric(
      horizontal: AppTheme.paddingLarge,
      vertical: AppTheme.paddingMedium,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadiusMedium),
    ),
    textStyle: TextStyle(
      fontSize: AppTheme.fontSizeLarge,
      fontWeight: FontWeight.bold,
    ),
  );

  // Section decoration
  static BoxDecoration get sectionDecoration => BoxDecoration(
    color: AppTheme.cardBackground,
    borderRadius: BorderRadius.circular(borderRadiusMedium),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.15),
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ],
  );

  // Badge decoration
  static BoxDecoration badgeDecoration(Color color) => BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(borderRadiusSmall),
  );

  // Text field decoration avec paramètres
  static InputDecoration textFieldDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
    String? hintText,
    String? errorText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      errorText: errorText,
      labelStyle: TextStyle(color: AppTheme.textSecondary),
      hintStyle: TextStyle(color: AppTheme.textSecondary),
      prefixIcon: Icon(icon, color: AppTheme.primary),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppTheme.cardBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadiusMedium),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadiusMedium),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadiusMedium),
        borderSide: BorderSide(color: AppTheme.primary, width: 1.5),
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: AppTheme.paddingMedium,
        vertical: AppTheme.paddingSmall,
      ),
    );
  }
}
