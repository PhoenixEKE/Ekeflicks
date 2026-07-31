import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isLightTheme = false;
  static const String _themePreferenceKey = 'isLightTheme';

  bool get isLightTheme => _isLightTheme;
  bool get isDarkMode => !_isLightTheme;
  ThemeMode get themeMode => _isLightTheme ? ThemeMode.light : ThemeMode.dark;

  ThemeProvider() {
    loadThemePrefs(); // Chargement automatique
  }

  Future<void> loadThemePrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isLightTheme = prefs.getBool(_themePreferenceKey) ?? false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading theme preferences: $e');
      _isLightTheme = false;
    }
  }

  Future<void> toggleTheme() async {
    _isLightTheme = !_isLightTheme;
    notifyListeners();
    await _saveTheme();
  }

  Future<void> _saveTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themePreferenceKey, _isLightTheme);
    } catch (e) {
      debugPrint('Error saving theme preference: $e');
    }
  }
}