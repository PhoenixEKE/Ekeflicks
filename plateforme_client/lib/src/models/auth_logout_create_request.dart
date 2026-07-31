//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'auth_logout_create_request.g.dart';

/// AuthLogoutCreateRequest
///
/// Properties:
/// * [refresh] - Refresh token à invalider
@BuiltValue()
abstract class AuthLogoutCreateRequest implements Built<AuthLogoutCreateRequest, AuthLogoutCreateRequestBuilder> {
  /// Refresh token à invalider
  @BuiltValueField(wireName: r'refresh')
  String get refresh;

  AuthLogoutCreateRequest._();

  factory AuthLogoutCreateRequest([void updates(AuthLogoutCreateRequestBuilder b)]) = _$AuthLogoutCreateRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(AuthLogoutCreateRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<AuthLogoutCreateRequest> get serializer => _$AuthLogoutCreateRequestSerializer();
}

class _$AuthLogoutCreateRequestSerializer implements PrimitiveSerializer<AuthLogoutCreateRequest> {
  @override
  final Iterable<Type> types = const [AuthLogoutCreateRequest, _$AuthLogoutCreateRequest];

  @override
  final String wireName = r'AuthLogoutCreateRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    AuthLogoutCreateRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'refresh';
    yield serializers.serialize(
      object.refresh,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    AuthLogoutCreateRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required AuthLogoutCreateRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'refresh':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.refresh = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  AuthLogoutCreateRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = AuthLogoutCreateRequestBuilder();
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

