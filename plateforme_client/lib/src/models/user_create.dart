//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'user_create.g.dart';

/// UserCreate
///
/// Properties:
/// * [email] 
/// * [password] 
/// * [firstname] 
/// * [lastname] 
/// * [country] 
/// * [role] 
/// * [subscription] 
@BuiltValue()
abstract class UserCreate implements Built<UserCreate, UserCreateBuilder> {
  @BuiltValueField(wireName: r'email')
  String get email;

  @BuiltValueField(wireName: r'password')
  String get password;

  @BuiltValueField(wireName: r'firstname')
  String? get firstname;

  @BuiltValueField(wireName: r'lastname')
  String? get lastname;

  @BuiltValueField(wireName: r'country')
  String? get country;

  @BuiltValueField(wireName: r'role')
  UserCreateRoleEnum? get role;
  // enum roleEnum {  user,  admin,  moderator,  accounting,  };

  @BuiltValueField(wireName: r'subscription')
  UserCreateSubscriptionEnum? get subscription;
  // enum subscriptionEnum {  free,  premium,  family,  };

  UserCreate._();

  factory UserCreate([void updates(UserCreateBuilder b)]) = _$UserCreate;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UserCreateBuilder b) => b
      ..role = const UserCreateRoleEnum._('user')
      ..subscription = const UserCreateSubscriptionEnum._('free');

  @BuiltValueSerializer(custom: true)
  static Serializer<UserCreate> get serializer => _$UserCreateSerializer();
}

class _$UserCreateSerializer implements PrimitiveSerializer<UserCreate> {
  @override
  final Iterable<Type> types = const [UserCreate, _$UserCreate];

  @override
  final String wireName = r'UserCreate';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UserCreate object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'email';
    yield serializers.serialize(
      object.email,
      specifiedType: const FullType(String),
    );
    yield r'password';
    yield serializers.serialize(
      object.password,
      specifiedType: const FullType(String),
    );
    if (object.firstname != null) {
      yield r'firstname';
      yield serializers.serialize(
        object.firstname,
        specifiedType: const FullType(String),
      );
    }
    if (object.lastname != null) {
      yield r'lastname';
      yield serializers.serialize(
        object.lastname,
        specifiedType: const FullType(String),
      );
    }
    if (object.country != null) {
      yield r'country';
      yield serializers.serialize(
        object.country,
        specifiedType: const FullType(String),
      );
    }
    if (object.role != null) {
      yield r'role';
      yield serializers.serialize(
        object.role,
        specifiedType: const FullType(UserCreateRoleEnum),
      );
    }
    if (object.subscription != null) {
      yield r'subscription';
      yield serializers.serialize(
        object.subscription,
        specifiedType: const FullType(UserCreateSubscriptionEnum),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    UserCreate object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required UserCreateBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'email':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.email = valueDes;
          break;
        case r'password':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.password = valueDes;
          break;
        case r'firstname':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.firstname = valueDes;
          break;
        case r'lastname':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.lastname = valueDes;
          break;
        case r'country':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.country = valueDes;
          break;
        case r'role':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(UserCreateRoleEnum),
          ) as UserCreateRoleEnum;
          result.role = valueDes;
          break;
        case r'subscription':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(UserCreateSubscriptionEnum),
          ) as UserCreateSubscriptionEnum;
          result.subscription = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  UserCreate deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UserCreateBuilder();
    final serializedList = (serialized as Iterable<Object?>).toList();
    final unhandled = <Object?>[];
    _deserializeProperties(
      serializers,
      serialized,
      specifiedType: specifiedType,
      serializedList: serializedList,
      unhandled: unhandled,
      result: result,
    );
    return result.build();
  }
}

class UserCreateRoleEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'user')
  static const UserCreateRoleEnum user = _$userCreateRoleEnum_user;
  @BuiltValueEnumConst(wireName: r'admin')
  static const UserCreateRoleEnum admin = _$userCreateRoleEnum_admin;
  @BuiltValueEnumConst(wireName: r'moderator')
  static const UserCreateRoleEnum moderator = _$userCreateRoleEnum_moderator;
  @BuiltValueEnumConst(wireName: r'accounting')
  static const UserCreateRoleEnum accounting = _$userCreateRoleEnum_accounting;

  static Serializer<UserCreateRoleEnum> get serializer => _$userCreateRoleEnumSerializer;

  const UserCreateRoleEnum._(String name): super(name);

  static BuiltSet<UserCreateRoleEnum> get values => _$userCreateRoleEnumValues;
  static UserCreateRoleEnum valueOf(String name) => _$userCreateRoleEnumValueOf(name);
}

class UserCreateSubscriptionEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'free')
  static const UserCreateSubscriptionEnum free = _$userCreateSubscriptionEnum_free;
  @BuiltValueEnumConst(wireName: r'premium')
  static const UserCreateSubscriptionEnum premium = _$userCreateSubscriptionEnum_premium;
  @BuiltValueEnumConst(wireName: r'family')
  static const UserCreateSubscriptionEnum family = _$userCreateSubscriptionEnum_family;

  static Serializer<UserCreateSubscriptionEnum> get serializer => _$userCreateSubscriptionEnumSerializer;

  const UserCreateSubscriptionEnum._(String name): super(name);

  static BuiltSet<UserCreateSubscriptionEnum> get values => _$userCreateSubscriptionEnumValues;
  static UserCreateSubscriptionEnum valueOf(String name) => _$userCreateSubscriptionEnumValueOf(name);
}

