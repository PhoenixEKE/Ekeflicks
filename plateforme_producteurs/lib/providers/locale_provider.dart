import 'package:flutter/material.dart';

class LocaleProvider with ChangeNotifier {
  Locale _locale = const Locale('fr');

  Locale get locale => _locale;

  void setLocale(Locale newLocale) {
    if (_locale == newLocale) return;
    _locale = newLocale;
    notifyListeners();
  }

  void toggleLocale() {
    _locale = _locale.languageCode == 'fr'
        ? const Locale('en')
        : const Locale('fr');
    notifyListeners();
  }
}
