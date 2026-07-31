import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider with ChangeNotifier {
  static const _localeKey = 'saved_locale';

  Locale _locale;
  final List<Locale> _supportedLocales;

  LocaleProvider({
    Locale? initialLocale,
    List<Locale>? supportedLocales,
  })  : _locale = initialLocale ?? const Locale('fr'),
        _supportedLocales = supportedLocales ?? const [Locale('fr'), Locale('en')];

  Locale get locale => _locale;
  List<Locale> get supportedLocales => _supportedLocales;

  bool get isFrench => _locale.languageCode == 'fr';
  bool get isEnglish => _locale.languageCode == 'en';

  /// Charge la locale sauvegardée (si existante)
  Future<void> loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_localeKey);
    if (code != null) {
      final savedLocale = Locale(code);
      if (_supportedLocales.contains(savedLocale) && _locale != savedLocale) {
        _locale = savedLocale;
        notifyListeners();
      }
    }
  }

  /// Sauvegarde la locale actuelle
  Future<void> saveLocale() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, _locale.languageCode);
  }

  /// Définit un nouveau locale avec sauvegarde
  Future<void> setLocale(Locale newLocale) async {
    if (!_supportedLocales.contains(newLocale)) {
      throw ArgumentError('Locale $newLocale is not supported');
    }
    if (_locale != newLocale) {
      _locale = newLocale;
      await saveLocale();
      notifyListeners();
    }
  }

  /// Bascule entre français et anglais avec sauvegarde
  Future<void> toggleLocale() async {
    _locale = isFrench ? const Locale('en') : const Locale('fr');
    await saveLocale();
    notifyListeners();
  }
}
