import 'package:flutter_test/flutter_test.dart';
import 'package:app_ekeflicks/utils/api_error_message.dart';

void main() {
  group('firstApiErrorMessage', () {
    test('reads a Django REST Framework field error list', () {
      expect(
        firstApiErrorMessage({
          'phone': ['Ajoutez obligatoirement l indicatif du pays.'],
        }),
        'Ajoutez obligatoirement l indicatif du pays.',
      );
    });

    test('prefers the normalized errors envelope', () {
      expect(
        firstApiErrorMessage({
          'phone': ['Duplicated top-level value'],
          'errors': {
            'email': ['Cette adresse email est deja utilisee.'],
          },
        }),
        'Cette adresse email est deja utilisee.',
      );
    });

    test('returns null for empty and unsupported values', () {
      expect(firstApiErrorMessage({'errors': <dynamic>[]}), isNull);
      expect(firstApiErrorMessage(null), isNull);
    });
  });
}
