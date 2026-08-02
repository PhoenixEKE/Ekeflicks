import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plateforme_producteurs/providers/locale_provider.dart';

void main() {
  test('administrator locale can be selected explicitly', () {
    final provider = LocaleProvider();

    provider.setLocale(const Locale('en'));

    expect(provider.locale, const Locale('en'));
  });

  test('administrator locale toggle notifies once', () {
    final provider = LocaleProvider();
    var notifications = 0;
    provider.addListener(() => notifications++);

    provider.toggleLocale();

    expect(provider.locale, const Locale('en'));
    expect(notifications, 1);
  });
}
