//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'token_obtain_pair.g.dart';

/// TokenObtainPair
///
/// Properties:
/// * [email] 
/// * [password] 
@BuiltValue()
abstract class TokenObtainPair implements Built<TokenObtainPair, TokenObtainPairBuilder> {
  @BuiltValueField(wireName: r'email')
  String get email;

  @BuiltValueField(wireName: r'password')
  String get password;

  TokenObtainPair._();

  factory TokenObtainPair([void updates(TokenObtainPairBuilder b)]) = _$TokenObtainPair;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(TokenObtainPairBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<TokenObtainPair> get serializer => _$TokenObtainPairSerializer();
}

class _$TokenObtainPairSerializer implements PrimitiveSerializer<TokenObtainPair> {
  @override
  final Iterable<Type> types = const [TokenObtainPair, _$TokenObtainPair];

  @override
  final String wireName = r'TokenObtainPair';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    TokenObtainPair object, {
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
  }

  @override
  Object serialize(
    Serializers serializers,
    TokenObtainPair object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required TokenObtainPairBuilder result,
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
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  TokenObtainPair deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = TokenObtainPairBuilder();
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

