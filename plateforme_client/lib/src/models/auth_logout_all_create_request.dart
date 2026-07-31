//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'auth_logout_all_create_request.g.dart';

/// AuthLogoutAllCreateRequest
///
/// Properties:
/// * [userId] - ID de l'utilisateur à déconnecter (optionnel, réservé aux admins)
/// * [confirmAll] - ⚠️ Si true, déconnecte TOUS les utilisateurs (réservé aux admins)
@BuiltValue()
abstract class AuthLogoutAllCreateRequest implements Built<AuthLogoutAllCreateRequest, AuthLogoutAllCreateRequestBuilder> {
  /// ID de l'utilisateur à déconnecter (optionnel, réservé aux admins)
  @BuiltValueField(wireName: r'user_id')
  int? get userId;

  /// ⚠️ Si true, déconnecte TOUS les utilisateurs (réservé aux admins)
  @BuiltValueField(wireName: r'confirm_all')
  bool? get confirmAll;

  AuthLogoutAllCreateRequest._();

  factory AuthLogoutAllCreateRequest([void updates(AuthLogoutAllCreateRequestBuilder b)]) = _$AuthLogoutAllCreateRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(AuthLogoutAllCreateRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<AuthLogoutAllCreateRequest> get serializer => _$AuthLogoutAllCreateRequestSerializer();
}

class _$AuthLogoutAllCreateRequestSerializer implements PrimitiveSerializer<AuthLogoutAllCreateRequest> {
  @override
  final Iterable<Type> types = const [AuthLogoutAllCreateRequest, _$AuthLogoutAllCreateRequest];

  @override
  final String wireName = r'AuthLogoutAllCreateRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    AuthLogoutAllCreateRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.userId != null) {
      yield r'user_id';
      yield serializers.serialize(
        object.userId,
        specifiedType: const FullType(int),
      );
    }
    if (object.confirmAll != null) {
      yield r'confirm_all';
      yield serializers.serialize(
        object.confirmAll,
        specifiedType: const FullType(bool),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    AuthLogoutAllCreateRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required AuthLogoutAllCreateRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'user_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.userId = valueDes;
          break;
        case r'confirm_all':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.confirmAll = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  AuthLogoutAllCreateRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = AuthLogoutAllCreateRequestBuilder();
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

