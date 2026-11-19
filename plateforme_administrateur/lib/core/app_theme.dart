import 'package:flutter/material.dart';

class AppTheme {
  // Couleurs principales
  static const Color primary = Color(0xFFF67F00);
  static const Color secondary = Color(0xFF1A1A1A);
  static const Color background = Color(0xFF121212);
  static const Color cardBackground = Color(0xFF242424);
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFF44336);
  static const Color warning = Color(0xFFFFC107);
  static const Color disabled = Color(0xFF9E9E9E);

  // Couleurs de texte
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;
  static const Color textDisabled = Color(0xFF9E9E9E);
  static const Color info = Color(0xFF17a2b8);

  // Couleurs supplémentaires
  static const Color grey = Color(0xFF9E9E9E);
  static const Color orange = Color(0xFFF67F00);
  static const Color divider = Color(0xFF333333);

  // Espacements
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;

  // Rayons de bordure
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;

  // Couleurs
  static const Color darkBackground = Color(0xFF121212);
  static const Color primaryOrange = Color(0xFFF67F00);
  static const Color textWhite = Colors.white;
  static const Color textWhite70 = Colors.white70;

  // Text Styles
  static const TextStyle textTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: textPrimary,
  );
  
  static const TextStyle textSubtitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: textPrimary,
  );
  
  static const TextStyle textBody = TextStyle(
    fontSize: 14,
    color: textPrimary,
  );

  static const TextStyle textBodyBold = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: textPrimary,
  );

  static const TextStyle textBodyItalic = TextStyle(
    fontSize: 14,
    fontStyle: FontStyle.italic,
    color: textPrimary,
  );

  static const TextStyle textCaption = TextStyle(
    fontSize: 12,
    color: textSecondary,
  );

  // Tailles de police
  static const double fontSizeSmall = 12.0;
  static const double fontSizeMedium = 14.0;
  static const double fontSizeLarge = 16.0;
  static const double fontSizeTitle = 20.0;
  static const double fontSizeHeadline = 24.0;

  // Theme Data
  static ThemeData get themeData => ThemeData.dark().copyWith(
        colorScheme: ColorScheme.dark(
          primary: primary,
          secondary: secondary,
          surface: cardBackground,
          background: background,
          error: error,
        ),
        scaffoldBackgroundColor: background,
        cardTheme: CardThemeData(
          color: cardBackground,
          elevation: 2,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: cardBackground,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: textTitle.copyWith(fontSize: fontSizeTitle),
          iconTheme: const IconThemeData(color: textPrimary),
        ),
        textTheme: TextTheme(
          displayLarge: TextStyle(
            fontSize: fontSizeHeadline,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
          displayMedium: textTitle,
          titleLarge: textTitle,
          titleMedium: textSubtitle,
          bodyLarge: textBody,
          bodyMedium: TextStyle(
            fontSize: fontSizeMedium,
            color: textSecondary,
          ),
          labelLarge: TextStyle(
            fontSize: fontSizeLarge,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
          labelMedium: TextStyle(
            fontSize: fontSizeMedium,
            color: grey,
          ),
          headlineSmall: TextStyle(
            fontSize: fontSizeMedium,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[850],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          hintStyle: const TextStyle(color: textDisabled),
          labelStyle: const TextStyle(color: textSecondary),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: textPrimary,
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
            ),
            textStyle: const TextStyle(
              fontSize: fontSizeLarge,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: primary,
            side: const BorderSide(color: primary),
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
            ),
            textStyle: const TextStyle(
              fontSize: fontSizeLarge,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: textSecondary),
        dividerTheme: DividerThemeData(
          color: divider,
          thickness: 1,
          space: 1,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: cardBackground,
          contentTextStyle: const TextStyle(color: textPrimary),
          actionTextColor: primary,
        ),
        dialogTheme: DialogThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
          ),
          backgroundColor: cardBackground,
        ),
      );

  // Méthodes pour les styles dynamiques
  static TextStyle textStyleAppBarTitle(BuildContext context) => 
      Theme.of(context).textTheme.titleLarge!;
  
  static TextStyle textStyleBody(BuildContext context) => 
      Theme.of(context).textTheme.bodyLarge!;
  
  static TextStyle textStyleBodyBold(BuildContext context) => 
      Theme.of(context).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.bold);
  
  static TextStyle textStyleBodyItalic(BuildContext context) => 
      Theme.of(context).textTheme.bodyLarge!.copyWith(fontStyle: FontStyle.italic);
  
  static TextStyle textStyleHint(BuildContext context) => 
      Theme.of(context).textTheme.bodyMedium!;
  
  static TextStyle textStyleTitleMedium(BuildContext context) => 
      Theme.of(context).textTheme.titleMedium!;
  
  static TextStyle textStyleTitleLarge(BuildContext context) => 
      Theme.of(context).textTheme.titleLarge!;
  
  static TextStyle textStyleCaption(BuildContext context) => 
      Theme.of(context).textTheme.bodySmall!;
  
  static TextStyle textStyleButtonText(BuildContext context) => 
      Theme.of(context).textTheme.labelLarge!;
  
  static TextStyle textStyleSnackBarText(BuildContext context) => 
      Theme.of(context).textTheme.bodyLarge!;
  
  static Color iconColor(BuildContext context) => 
      Theme.of(context).iconTheme.color!;
  
  static Color scaffoldBackgroundColor(BuildContext context) => 
      Theme.of(context).scaffoldBackgroundColor;
  
  static Color cardBackgroundColor(BuildContext context) => 
      Theme.of(context).cardTheme.color!;
  
  static Color appBarBackgroundColor(BuildContext context) => 
      Theme.of(context).appBarTheme.backgroundColor!;
  
  static Color dividerColor(BuildContext context) => 
      Theme.of(context).dividerTheme.color!;
}