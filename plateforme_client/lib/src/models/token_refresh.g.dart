// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'token_refresh.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$TokenRefresh extends TokenRefresh {
  @override
  final String refresh;
  @override
  final String? access;

  factory _$TokenRefresh([void Function(TokenRefreshBuilder)? updates]) =>
      (TokenRefreshBuilder()..update(updates))._build();

  _$TokenRefresh._({required this.refresh, this.access}) : super._();
  @override
  TokenRefresh rebuild(void Function(TokenRefreshBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  TokenRefreshBuilder toBuilder() => TokenRefreshBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is TokenRefresh &&
        refresh == other.refresh &&
        access == other.access;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, refresh.hashCode);
    _$hash = $jc(_$hash, access.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'TokenRefresh')
          ..add('refresh', refresh)
          ..add('access', access))
        .toString();
  }
}

class TokenRefreshBuilder
    implements Builder<TokenRefresh, TokenRefreshBuilder> {
  _$TokenRefresh? _$v;

  String? _refresh;
  String? get refresh => _$this._refresh;
  set refresh(String? refresh) => _$this._refresh = refresh;

  String? _access;
  String? get access => _$this._access;
  set access(String? access) => _$this._access = access;

  TokenRefreshBuilder() {
    TokenRefresh._defaults(this);
  }

  TokenRefreshBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _refresh = $v.refresh;
      _access = $v.access;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(TokenRefresh other) {
    _$v = other as _$TokenRefresh;
  }

  @override
  void update(void Function(TokenRefreshBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  TokenRefresh build() => _build();

  _$TokenRefresh _build() {
    final _$result =
        _$v ??
        _$TokenRefresh._(
          refresh: BuiltValueNullFieldError.checkNotNull(
            refresh,
            r'TokenRefresh',
            'refresh',
          ),
          access: access,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
