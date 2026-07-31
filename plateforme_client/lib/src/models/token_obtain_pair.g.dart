// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'token_obtain_pair.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$TokenObtainPair extends TokenObtainPair {
  @override
  final String email;
  @override
  final String password;

  factory _$TokenObtainPair([void Function(TokenObtainPairBuilder)? updates]) =>
      (TokenObtainPairBuilder()..update(updates))._build();

  _$TokenObtainPair._({required this.email, required this.password})
    : super._();
  @override
  TokenObtainPair rebuild(void Function(TokenObtainPairBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  TokenObtainPairBuilder toBuilder() => TokenObtainPairBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is TokenObtainPair &&
        email == other.email &&
        password == other.password;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, email.hashCode);
    _$hash = $jc(_$hash, password.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'TokenObtainPair')
          ..add('email', email)
          ..add('password', password))
        .toString();
  }
}

class TokenObtainPairBuilder
    implements Builder<TokenObtainPair, TokenObtainPairBuilder> {
  _$TokenObtainPair? _$v;

  String? _email;
  String? get email => _$this._email;
  set email(String? email) => _$this._email = email;

  String? _password;
  String? get password => _$this._password;
  set password(String? password) => _$this._password = password;

  TokenObtainPairBuilder() {
    TokenObtainPair._defaults(this);
  }

  TokenObtainPairBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _email = $v.email;
      _password = $v.password;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(TokenObtainPair other) {
    _$v = other as _$TokenObtainPair;
  }

  @override
  void update(void Function(TokenObtainPairBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  TokenObtainPair build() => _build();

  _$TokenObtainPair _build() {
    final _$result =
        _$v ??
        _$TokenObtainPair._(
          email: BuiltValueNullFieldError.checkNotNull(
            email,
            r'TokenObtainPair',
            'email',
          ),
          password: BuiltValueNullFieldError.checkNotNull(
            password,
            r'TokenObtainPair',
            'password',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
