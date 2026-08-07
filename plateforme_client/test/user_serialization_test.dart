import 'package:app_ekeflicks/src/models/user.dart';
import 'package:app_ekeflicks/src/serializers/serializers.dart';
import 'package:built_value/serializer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('User serialization', () {
    test('accepts an explicitly null email for a phone-only account', () {
      final user = standardSerializers.deserialize(
        {
          'id': 'phone-user',
          'email': null,
          'firstname': 'Awa',
          'lastname': null,
          'is_active': true,
        },
        specifiedType: const FullType(User),
      ) as User;

      expect(user.id, 'phone-user');
      expect(user.email, isNull);
      expect(user.firstname, 'Awa');
      expect(user.lastname, isNull);
      expect(user.isActive, isTrue);
    });

    test('omits a null email when serializing', () {
      final user = User((builder) => builder
        ..id = 'phone-user'
        ..isActive = true);

      final serialized = standardSerializers.serialize(
        user,
        specifiedType: const FullType(User),
      ) as Map<String, dynamic>;

      expect(serialized, isNot(contains('email')));
    });
  });
}
