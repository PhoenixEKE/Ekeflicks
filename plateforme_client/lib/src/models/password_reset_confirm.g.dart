// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'password_reset_confirm.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PasswordResetConfirm extends PasswordResetConfirm {
  @override
  final String uid;
  @override
  final String token;
  @override
  final String newPassword;

  factory _$PasswordResetConfirm([
    void Function(PasswordResetConfirmBuilder)? updates,
  ]) => (PasswordResetConfirmBuilder()..update(updates))._build();

  _$PasswordResetConfirm._({
    required this.uid,
    required this.token,
    required this.newPassword,
  }) : super._();
  @override
  PasswordResetConfirm rebuild(
    void Function(PasswordResetConfirmBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  PasswordResetConfirmBuilder toBuilder() =>
      PasswordResetConfirmBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PasswordResetConfirm &&
        uid == other.uid &&
        token == other.token &&
        newPassword == other.newPassword;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, uid.hashCode);
    _$hash = $jc(_$hash, token.hashCode);
    _$hash = $jc(_$hash, newPassword.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PasswordResetConfirm')
          ..add('uid', uid)
          ..add('token', token)
          ..add('newPassword', newPassword))
        .toString();
  }
}

class PasswordResetConfirmBuilder
    implements Builder<PasswordResetConfirm, PasswordResetConfirmBuilder> {
  _$PasswordResetConfirm? _$v;

  String? _uid;
  String? get uid => _$this._uid;
  set uid(String? uid) => _$this._uid = uid;

  String? _token;
  String? get token => _$this._token;
  set token(String? token) => _$this._token = token;

  String? _newPassword;
  String? get newPassword => _$this._newPassword;
  set newPassword(String? newPassword) => _$this._newPassword = newPassword;

  PasswordResetConfirmBuilder() {
    PasswordResetConfirm._defaults(this);
  }

  PasswordResetConfirmBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _uid = $v.uid;
      _token = $v.token;
      _newPassword = $v.newPassword;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PasswordResetConfirm other) {
    _$v = other as _$PasswordResetConfirm;
  }

  @override
  void update(void Function(PasswordResetConfirmBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PasswordResetConfirm build() => _build();

  _$PasswordResetConfirm _build() {
    final _$result =
        _$v ??
        _$PasswordResetConfirm._(
          uid: BuiltValueNullFieldError.checkNotNull(
            uid,
            r'PasswordResetConfirm',
            'uid',
          ),
          token: BuiltValueNullFieldError.checkNotNull(
            token,
            r'PasswordResetConfirm',
            'token',
          ),
          newPassword: BuiltValueNullFieldError.checkNotNull(
            newPassword,
            r'PasswordResetConfirm',
            'newPassword',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
