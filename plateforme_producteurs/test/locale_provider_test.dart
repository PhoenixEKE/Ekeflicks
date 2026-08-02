import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plateforme_producteurs/providers/locale_provider.dart';

void main() {
  test('producer locale starts in French and toggles to English', () {
    final provider = LocaleProvider();
    var notifications = 0;
    provider.addListener(() => notifications++);

    expect(provider.locale, const Locale('fr'));
    provider.toggleLocale();

    expect(provider.locale, const Locale('en'));
    expect(notifications, 1);
  });

  test('setting the current locale does not notify listeners', () {
    final provider = LocaleProvider();
    var notifications = 0;
    provider.addListener(() => notifications++);

    provider.setLocale(const Locale('fr'));

    expect(notifications, 0);
  });
}
