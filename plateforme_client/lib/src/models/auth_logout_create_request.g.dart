// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_logout_create_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$AuthLogoutCreateRequest extends AuthLogoutCreateRequest {
  @override
  final String refresh;

  factory _$AuthLogoutCreateRequest([
    void Function(AuthLogoutCreateRequestBuilder)? updates,
  ]) => (AuthLogoutCreateRequestBuilder()..update(updates))._build();

  _$AuthLogoutCreateRequest._({required this.refresh}) : super._();
  @override
  AuthLogoutCreateRequest rebuild(
    void Function(AuthLogoutCreateRequestBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  AuthLogoutCreateRequestBuilder toBuilder() =>
      AuthLogoutCreateRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AuthLogoutCreateRequest && refresh == other.refresh;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, refresh.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'AuthLogoutCreateRequest')
      ..add('refresh', refresh)).toString();
  }
}

class AuthLogoutCreateRequestBuilder
    implements
        Builder<AuthLogoutCreateRequest, AuthLogoutCreateRequestBuilder> {
  _$AuthLogoutCreateRequest? _$v;

  String? _refresh;
  String? get refresh => _$this._refresh;
  set refresh(String? refresh) => _$this._refresh = refresh;

  AuthLogoutCreateRequestBuilder() {
    AuthLogoutCreateRequest._defaults(this);
  }

  AuthLogoutCreateRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _refresh = $v.refresh;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AuthLogoutCreateRequest other) {
    _$v = other as _$AuthLogoutCreateRequest;
  }

  @override
  void update(void Function(AuthLogoutCreateRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  AuthLogoutCreateRequest build() => _build();

  _$AuthLogoutCreateRequest _build() {
    final _$result =
        _$v ??
        _$AuthLogoutCreateRequest._(
          refresh: BuiltValueNullFieldError.checkNotNull(
            refresh,
            r'AuthLogoutCreateRequest',
            'refresh',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
