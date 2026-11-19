// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_logout_all_create_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$AuthLogoutAllCreateRequest extends AuthLogoutAllCreateRequest {
  @override
  final int? userId;
  @override
  final bool? confirmAll;

  factory _$AuthLogoutAllCreateRequest([
    void Function(AuthLogoutAllCreateRequestBuilder)? updates,
  ]) => (AuthLogoutAllCreateRequestBuilder()..update(updates))._build();

  _$AuthLogoutAllCreateRequest._({this.userId, this.confirmAll}) : super._();
  @override
  AuthLogoutAllCreateRequest rebuild(
    void Function(AuthLogoutAllCreateRequestBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  AuthLogoutAllCreateRequestBuilder toBuilder() =>
      AuthLogoutAllCreateRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AuthLogoutAllCreateRequest &&
        userId == other.userId &&
        confirmAll == other.confirmAll;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, userId.hashCode);
    _$hash = $jc(_$hash, confirmAll.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'AuthLogoutAllCreateRequest')
          ..add('userId', userId)
          ..add('confirmAll', confirmAll))
        .toString();
  }
}

class AuthLogoutAllCreateRequestBuilder
    implements
        Builder<AuthLogoutAllCreateRequest, AuthLogoutAllCreateRequestBuilder> {
  _$AuthLogoutAllCreateRequest? _$v;

  int? _userId;
  int? get userId => _$this._userId;
  set userId(int? userId) => _$this._userId = userId;

  bool? _confirmAll;
  bool? get confirmAll => _$this._confirmAll;
  set confirmAll(bool? confirmAll) => _$this._confirmAll = confirmAll;

  AuthLogoutAllCreateRequestBuilder() {
    AuthLogoutAllCreateRequest._defaults(this);
  }

  AuthLogoutAllCreateRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _userId = $v.userId;
      _confirmAll = $v.confirmAll;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AuthLogoutAllCreateRequest other) {
    _$v = other as _$AuthLogoutAllCreateRequest;
  }

  @override
  void update(void Function(AuthLogoutAllCreateRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  AuthLogoutAllCreateRequest build() => _build();

  _$AuthLogoutAllCreateRequest _build() {
    final _$result =
        _$v ??
        _$AuthLogoutAllCreateRequest._(userId: userId, confirmAll: confirmAll);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
