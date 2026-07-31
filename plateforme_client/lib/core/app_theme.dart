import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppTheme {
  // ============== CONSTANTES INCHANGÉES ==============
  static const String _themeKey = 'app_theme';
  static const String lightThemeValue = 'light';
  static const String darkThemeValue = 'dark';

  static const double borderRadius = 12.0;
  static const double smallPadding = 8.0;
  static const double mediumPadding = 16.0;
  static const double largePadding = 24.0;

  // Dimensions TV
  static const double tvBorderRadius = 16.0;
  static const double tvButtonHeight = 60.0;
  static const double tvButtonMinWidth = 200.0;
  static const double tvCardElevation = 8.0;
  static const EdgeInsets tvCardMargin = EdgeInsets.all(16.0);

  // Couleurs
  static const Color primaryOrange = Color(0xFFF67F00);
  static const Color errorRed = Colors.redAccent;
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color infoBlue = Color(0xFF2196F3);
  static const Color warningYellow = Color(0xFFFFC107);
  static const Color disabledColor = Color(0xFF9E9E9E);

  // ============== GESTION DU THÈME INCHANGÉE ==============
  static final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_themeKey);
      themeNotifier.value = savedTheme == lightThemeValue
          ? ThemeMode.light
          : savedTheme == darkThemeValue
              ? ThemeMode.dark
              : ThemeMode.system;
    } catch (e) {
      debugPrint('Error loading theme: $e');
      themeNotifier.value = ThemeMode.system;
    }
  }

  static Future<void> toggleTheme(ThemeMode newTheme) async {
    try {
      themeNotifier.value = newTheme;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _themeKey,
        newTheme == ThemeMode.light
            ? lightThemeValue
            : newTheme == ThemeMode.dark
                ? darkThemeValue
                : '',
      );
    } catch (e) {
      debugPrint('Error saving theme: $e');
    }
  }

  // ============== THÈMES PRINCIPAUX ==============
  static ThemeData get lightTheme => _buildTheme(Brightness.light);
  static ThemeData get darkTheme => _buildTheme(Brightness.dark);
  static ThemeData get tvLightTheme => _buildTVTheme(lightTheme);
  static ThemeData get tvDarkTheme => _buildTVTheme(darkTheme);

  // ============== MODIFICATIONS PRINCIPALES ==============
  static ThemeData _buildTheme(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final baseColorScheme = _buildColorScheme(brightness);

    return ThemeData(
      useMaterial3: true, // Nécessaire pour Material 3
      brightness: brightness,
      colorScheme: baseColorScheme,
      primaryColor: primaryOrange,
      scaffoldBackgroundColor: baseColorScheme.background,
      
      // CORRECTION: Utilisation de CardTheme au lieu de CardThemeData
      cardTheme: CardThemeData(
        elevation: 2,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        color: isLight ? Colors.grey[100] : Colors.grey[900],
      ),

      // RESTE INCHANGÉ
      appBarTheme: _buildAppBarTheme(isLight),
      textTheme: _buildTextTheme(brightness),
      iconTheme: IconThemeData(color: isLight ? Colors.black87 : Colors.white),
      inputDecorationTheme: _buildInputDecorationTheme(brightness),
      elevatedButtonTheme: ElevatedButtonThemeData(style: _buildButtonStyle(brightness)),
      textButtonTheme: TextButtonThemeData(style: _buildTextButtonStyle(brightness)),
      outlinedButtonTheme: OutlinedButtonThemeData(style: _buildOutlinedButtonStyle(brightness)),
      dividerTheme: DividerThemeData(
        color: isLight ? Colors.grey[300] : Colors.grey[700],
        thickness: 1,
        space: 1,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryOrange,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        contentTextStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(borderRadius),
          ),
        ),
      ),
      chipTheme: _buildChipTheme(brightness),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primaryOrange,
        linearTrackColor: primaryOrange.withOpacity(0.2),
      ),
    );
  }

  static ThemeData _buildTVTheme(ThemeData baseTheme) {
    return baseTheme.copyWith(
      textTheme: _buildTVTextTheme(baseTheme.brightness),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: baseTheme.elevatedButtonTheme.style?.copyWith(
          minimumSize: MaterialStateProperty.all(
            Size(tvButtonMinWidth, tvButtonHeight),
          ),
          padding: MaterialStateProperty.all(
            EdgeInsets.symmetric(vertical: 24, horizontal: 32),
          ),
          textStyle: MaterialStateProperty.all(
            TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      // CORRECTION: Utilisation de CardTheme
      cardTheme: baseTheme.cardTheme.copyWith(
        elevation: tvCardElevation,
        margin: tvCardMargin,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tvBorderRadius),
        ),
      ),
      iconTheme: baseTheme.iconTheme.copyWith(size: 32),
      snackBarTheme: baseTheme.snackBarTheme.copyWith(
        contentTextStyle: TextStyle(fontSize: 18),
      ),
    );
  }

  // ============== FONCTIONS INCHANGÉES ==============
  static AppBarTheme _buildAppBarTheme(bool isLight) {
    return AppBarTheme(
      backgroundColor: isLight ? const Color(0xFFFDFDFD) : Colors.black,
      foregroundColor: primaryOrange,
      elevation: 1,
      centerTitle: true,
      iconTheme: const IconThemeData(color: primaryOrange),
      titleTextStyle: const TextStyle(
        color: primaryOrange,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  static ColorScheme _buildColorScheme(Brightness brightness) {
    return brightness == Brightness.light
        ? ColorScheme.light(
            primary: primaryOrange,
            onPrimary: Colors.white,
            secondary: Colors.amber.shade700,
            onSecondary: Colors.black,
            error: errorRed,
            onError: Colors.white,
            background: Colors.white,
            onBackground: Colors.black,
            surface: Colors.grey[100]!,
            onSurface: Colors.black,
          )
        : ColorScheme.dark(
            primary: primaryOrange,
            onPrimary: Colors.black,
            secondary: Colors.amber.shade600,
            onSecondary: Colors.black,
            error: errorRed,
            onError: Colors.white,
            background: Colors.black,
            onBackground: Colors.white,
            surface: Colors.grey[900]!,
            onSurface: Colors.white,
          );
  }

  static TextTheme _buildTextTheme(Brightness brightness) {
    final baseColor = brightness == Brightness.light ? Colors.black : Colors.white;
    return TextTheme(
      displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: baseColor),
      displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: baseColor),
      displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: baseColor),
      headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: baseColor),
      headlineMedium: TextStyle(fontSize: 20, color: baseColor.withOpacity(0.87)),
      headlineSmall: TextStyle(fontSize: 18, color: baseColor.withOpacity(0.87)),
      titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: baseColor),
      titleMedium: TextStyle(fontSize: 16, color: baseColor.withOpacity(0.87)),
      titleSmall: TextStyle(fontSize: 14, color: baseColor.withOpacity(0.87)),
      bodyLarge: TextStyle(fontSize: 16, color: baseColor.withOpacity(0.87)),
      bodyMedium: TextStyle(fontSize: 14, color: baseColor.withOpacity(0.87)),
      bodySmall: TextStyle(fontSize: 12, color: baseColor.withOpacity(0.87)),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: baseColor),
      labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: baseColor),
      labelSmall: TextStyle(fontSize: 11, color: baseColor.withOpacity(0.6)),
    );
  }

  static TextTheme _buildTVTextTheme(Brightness brightness) {
    final base = _buildTextTheme(brightness);
    return base.copyWith(
      displayLarge: base.displayLarge!.copyWith(fontSize: 48),
      displayMedium: base.displayMedium!.copyWith(fontSize: 40),
      displaySmall: base.displaySmall!.copyWith(fontSize: 36),
      headlineLarge: base.headlineLarge!.copyWith(fontSize: 32),
      headlineMedium: base.headlineMedium!.copyWith(fontSize: 28),
      headlineSmall: base.headlineSmall!.copyWith(fontSize: 24),
      titleLarge: base.titleLarge!.copyWith(fontSize: 22),
      bodyLarge: base.bodyLarge!.copyWith(fontSize: 20),
      bodyMedium: base.bodyMedium!.copyWith(fontSize: 18),
    );
  }

  static InputDecorationTheme _buildInputDecorationTheme(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    return InputDecorationTheme(
      filled: true,
      fillColor: isLight ? Colors.grey.withOpacity(0.1) : Colors.grey[850],
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide(color: primaryOrange, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide(color: errorRed),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide(color: errorRed, width: 2),
      ),
      labelStyle: TextStyle(
        color: isLight ? Colors.grey.shade700 : Colors.grey.shade300,
      ),
      hintStyle: TextStyle(
        color: isLight ? Colors.grey.shade500 : Colors.grey.shade500,
      ),
      errorStyle: TextStyle(
        color: errorRed,
        fontSize: 12,
      ),
      prefixIconColor: primaryOrange,
      suffixIconColor: primaryOrange,
    );
  }

  static ChipThemeData _buildChipTheme(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    return ChipThemeData(
      backgroundColor: isLight 
          ? Colors.grey.withOpacity(0.1) 
          : Colors.grey.withOpacity(0.2),
      selectedColor: primaryOrange,
      secondarySelectedColor: primaryOrange,
      disabledColor: disabledColor,
      labelStyle: TextStyle(
        color: isLight ? Colors.black : Colors.white,
      ),
      secondaryLabelStyle: const TextStyle(
        color: Colors.white,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }

  static ButtonStyle _buildButtonStyle(Brightness brightness) {
    return ElevatedButton.styleFrom(
      backgroundColor: primaryOrange,
      foregroundColor: Colors.white,
      disabledBackgroundColor: primaryOrange.withOpacity(0.5),
      disabledForegroundColor: Colors.white.withOpacity(0.5),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.25),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      textStyle: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
    ).copyWith(
      overlayColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.pressed)) {
          return Colors.white.withOpacity(0.2);
        }
        if (states.contains(MaterialState.hovered)) {
          return Colors.white.withOpacity(0.1);
        }
        return Colors.transparent;
      }),
    );
  }

  static ButtonStyle _buildTextButtonStyle(Brightness brightness) {
    return TextButton.styleFrom(
      foregroundColor: primaryOrange,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      textStyle: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
    ).copyWith(
      overlayColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.pressed)) {
          return primaryOrange.withOpacity(0.2);
        }
        if (states.contains(MaterialState.hovered)) {
          return primaryOrange.withOpacity(0.1);
        }
        return Colors.transparent;
      }),
    );
  }

  static ButtonStyle _buildOutlinedButtonStyle(Brightness brightness) {
    return OutlinedButton.styleFrom(
      foregroundColor: primaryOrange,
      side: BorderSide(color: primaryOrange),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      textStyle: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
    ).copyWith(
      overlayColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.pressed)) {
          return primaryOrange.withOpacity(0.2);
        }
        if (states.contains(MaterialState.hovered)) {
          return primaryOrange.withOpacity(0.1);
        }
        return Colors.transparent;
      }),
    );
  }

  // ============== UTILITAIRES INCHANGÉS ==============
  static BorderRadius getBorderRadius(bool isTV) {
    return BorderRadius.circular(isTV ? tvBorderRadius : borderRadius);
  }

  static EdgeInsets getCardMargin(bool isTV) {
    return isTV ? tvCardMargin : const EdgeInsets.all(8.0);
  }

  static double responsiveValue(BuildContext context, 
    {required double mobile, double? tablet, double? desktop}) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1200 && desktop != null) return desktop;
    if (width >= 600 && tablet != null) return tablet;
    return mobile;
  }

  static BoxDecoration pageDecoration(BuildContext context, {bool useGradient = true}) {
    final theme = Theme.of(context);
    if (useGradient) {
      return BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topCenter,
          radius: 1.5, // Réduit de 1.5 à 0.8 pour un effet plus subtil
          colors: theme.brightness == Brightness.dark
              ? [
                  const Color(0xFF121212), // Plus foncé près du centre
                  const Color(0xFF1E1E1E), // Intermediate
                  const Color(0xFF2D2D2D), // Plus clair sur les bords
                ]
              : [
                  const Color(0xFFF8F9FA), // Très léger près du centre
                  const Color(0xFFE9ECEF), // Intermediate
                  const Color(0xFFDEE2E6), // Léger sur les bords
                ],
          stops: const [0.0, 0.5, 1.0], // Contrôle la progression des couleurs
        ),
      );
    } else {
      return BoxDecoration(
        color: theme.colorScheme.background,
      );
    }
  }

  static BoxDecoration cardDecoration(BuildContext context, {double elevation = 2}) {
    return BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1 * elevation),
          blurRadius: 6 * elevation,
          spreadRadius: 1 * elevation,
          offset: Offset(0, 2 * elevation),
        ),
      ],
    );
  }

  static TextStyle offerTitleStyle(BuildContext context) {
    final theme = Theme.of(context);
    return theme.textTheme.titleMedium!.copyWith(
      color: theme.colorScheme.onSurface,
      fontWeight: FontWeight.w600,
    );
  }

  static TextStyle offerPriceStyle(BuildContext context) {
    final theme = Theme.of(context);
    return theme.textTheme.bodyMedium!.copyWith(
      color: theme.colorScheme.onSurface,
      fontWeight: FontWeight.w500,
    );
  }

  static TextStyle offerDetailLabelStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodySmall!;
  }

  static TextStyle offerDetailValueStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold);
  }

  static const tvSectionTitleStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static const tvFeaturedTitleStyle = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    shadows: [
      Shadow(
        color: Colors.black,
        blurRadius: 8,
        offset: Offset(2, 2),
      ),
    ],
  );

}