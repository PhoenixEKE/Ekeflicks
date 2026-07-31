//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'user.g.dart';

/// User
///
/// Properties:
/// * [id] 
/// * [email] 
/// * [firstname] 
/// * [lastname] 
/// * [role] 
/// * [status] 
/// * [subscription] 
/// * [isActive] 
/// * [createdAt] 
@BuiltValue()
abstract class User implements Built<User, UserBuilder> {
  @BuiltValueField(wireName: r'id')
  int? get id;

  @BuiltValueField(wireName: r'email')
  String get email;

  @BuiltValueField(wireName: r'firstname')
  String? get firstname;

  @BuiltValueField(wireName: r'lastname')
  String? get lastname;

  @BuiltValueField(wireName: r'role')
  UserRoleEnum? get role;
  // enum roleEnum {  user,  admin,  moderator,  accounting,  };

  @BuiltValueField(wireName: r'status')
  UserStatusEnum? get status;
  // enum statusEnum {  active,  inactive,  suspended,  banned,  pending,  };

  @BuiltValueField(wireName: r'subscription')
  UserSubscriptionEnum? get subscription;
  // enum subscriptionEnum {  free,  premium,  family,  };

  @BuiltValueField(wireName: r'is_active')
  bool? get isActive;

  @BuiltValueField(wireName: r'created_at')
  DateTime? get createdAt;

  User._();

  factory User([void updates(UserBuilder b)]) = _$User;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UserBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<User> get serializer => _$UserSerializer();
}

class _$UserSerializer implements PrimitiveSerializer<User> {
  @override
  final Iterable<Type> types = const [User, _$User];

  @override
  final String wireName = r'User';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    User object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.id != null) {
      yield r'id';
      yield serializers.serialize(
        object.id,
        specifiedType: const FullType(int),
      );
    }
    yield r'email';
    yield serializers.serialize(
      object.email,
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
    if (object.role != null) {
      yield r'role';
      yield serializers.serialize(
        object.role,
        specifiedType: const FullType(UserRoleEnum),
      );
    }
    if (object.status != null) {
      yield r'status';
      yield serializers.serialize(
        object.status,
        specifiedType: const FullType(UserStatusEnum),
      );
    }
    if (object.subscription != null) {
      yield r'subscription';
      yield serializers.serialize(
        object.subscription,
        specifiedType: const FullType(UserSubscriptionEnum),
      );
    }
    if (object.isActive != null) {
      yield r'is_active';
      yield serializers.serialize(
        object.isActive,
        specifiedType: const FullType(bool),
      );
    }
    if (object.createdAt != null) {
      yield r'created_at';
      yield serializers.serialize(
        object.createdAt,
        specifiedType: const FullType(DateTime),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    User object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required UserBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.id = valueDes;
          break;
        case r'email':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.email = valueDes;
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
        case r'role':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(UserRoleEnum),
          ) as UserRoleEnum;
          result.role = valueDes;
          break;
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(UserStatusEnum),
          ) as UserStatusEnum;
          result.status = valueDes;
          break;
        case r'subscription':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(UserSubscriptionEnum),
          ) as UserSubscriptionEnum;
          result.subscription = valueDes;
          break;
        case r'is_active':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.isActive = valueDes;
          break;
        case r'created_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.createdAt = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  User deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UserBuilder();
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

class UserRoleEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'user')
  static const UserRoleEnum user = _$userRoleEnum_user;
  @BuiltValueEnumConst(wireName: r'admin')
  static const UserRoleEnum admin = _$userRoleEnum_admin;
  @BuiltValueEnumConst(wireName: r'moderator')
  static const UserRoleEnum moderator = _$userRoleEnum_moderator;
  @BuiltValueEnumConst(wireName: r'accounting')
  static const UserRoleEnum accounting = _$userRoleEnum_accounting;

  static Serializer<UserRoleEnum> get serializer => _$userRoleEnumSerializer;

  const UserRoleEnum._(String name): super(name);

  static BuiltSet<UserRoleEnum> get values => _$userRoleEnumValues;
  static UserRoleEnum valueOf(String name) => _$userRoleEnumValueOf(name);
}

class UserStatusEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'active')
  static const UserStatusEnum active = _$userStatusEnum_active;
  @BuiltValueEnumConst(wireName: r'inactive')
  static const UserStatusEnum inactive = _$userStatusEnum_inactive;
  @BuiltValueEnumConst(wireName: r'suspended')
  static const UserStatusEnum suspended = _$userStatusEnum_suspended;
  @BuiltValueEnumConst(wireName: r'banned')
  static const UserStatusEnum banned = _$userStatusEnum_banned;
  @BuiltValueEnumConst(wireName: r'pending')
  static const UserStatusEnum pending = _$userStatusEnum_pending;

  static Serializer<UserStatusEnum> get serializer => _$userStatusEnumSerializer;

  const UserStatusEnum._(String name): super(name);

  static BuiltSet<UserStatusEnum> get values => _$userStatusEnumValues;
  static UserStatusEnum valueOf(String name) => _$userStatusEnumValueOf(name);
}

class UserSubscriptionEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'free')
  static const UserSubscriptionEnum free = _$userSubscriptionEnum_free;
  @BuiltValueEnumConst(wireName: r'premium')
  static const UserSubscriptionEnum premium = _$userSubscriptionEnum_premium;
  @BuiltValueEnumConst(wireName: r'family')
  static const UserSubscriptionEnum family = _$userSubscriptionEnum_family;

  static Serializer<UserSubscriptionEnum> get serializer => _$userSubscriptionEnumSerializer;

  const UserSubscriptionEnum._(String name): super(name);

  static BuiltSet<UserSubscriptionEnum> get values => _$userSubscriptionEnumValues;
  static UserSubscriptionEnum valueOf(String name) => _$userSubscriptionEnumValueOf(name);
}

