// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_create.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const UserCreateRoleEnum _$userCreateRoleEnum_user = const UserCreateRoleEnum._(
  'user',
);
const UserCreateRoleEnum _$userCreateRoleEnum_admin =
    const UserCreateRoleEnum._('admin');
const UserCreateRoleEnum _$userCreateRoleEnum_moderator =
    const UserCreateRoleEnum._('moderator');
const UserCreateRoleEnum _$userCreateRoleEnum_accounting =
    const UserCreateRoleEnum._('accounting');

UserCreateRoleEnum _$userCreateRoleEnumValueOf(String name) {
  switch (name) {
    case 'user':
      return _$userCreateRoleEnum_user;
    case 'admin':
      return _$userCreateRoleEnum_admin;
    case 'moderator':
      return _$userCreateRoleEnum_moderator;
    case 'accounting':
      return _$userCreateRoleEnum_accounting;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<UserCreateRoleEnum> _$userCreateRoleEnumValues =
    BuiltSet<UserCreateRoleEnum>(const <UserCreateRoleEnum>[
      _$userCreateRoleEnum_user,
      _$userCreateRoleEnum_admin,
      _$userCreateRoleEnum_moderator,
      _$userCreateRoleEnum_accounting,
    ]);

const UserCreateSubscriptionEnum _$userCreateSubscriptionEnum_free =
    const UserCreateSubscriptionEnum._('free');
const UserCreateSubscriptionEnum _$userCreateSubscriptionEnum_premium =
    const UserCreateSubscriptionEnum._('premium');
const UserCreateSubscriptionEnum _$userCreateSubscriptionEnum_family =
    const UserCreateSubscriptionEnum._('family');

UserCreateSubscriptionEnum _$userCreateSubscriptionEnumValueOf(String name) {
  switch (name) {
    case 'free':
      return _$userCreateSubscriptionEnum_free;
    case 'premium':
      return _$userCreateSubscriptionEnum_premium;
    case 'family':
      return _$userCreateSubscriptionEnum_family;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<UserCreateSubscriptionEnum> _$userCreateSubscriptionEnumValues =
    BuiltSet<UserCreateSubscriptionEnum>(const <UserCreateSubscriptionEnum>[
      _$userCreateSubscriptionEnum_free,
      _$userCreateSubscriptionEnum_premium,
      _$userCreateSubscriptionEnum_family,
    ]);

Serializer<UserCreateRoleEnum> _$userCreateRoleEnumSerializer =
    _$UserCreateRoleEnumSerializer();
Serializer<UserCreateSubscriptionEnum> _$userCreateSubscriptionEnumSerializer =
    _$UserCreateSubscriptionEnumSerializer();

class _$UserCreateRoleEnumSerializer
    implements PrimitiveSerializer<UserCreateRoleEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'user': 'user',
    'admin': 'admin',
    'moderator': 'moderator',
    'accounting': 'accounting',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'user': 'user',
    'admin': 'admin',
    'moderator': 'moderator',
    'accounting': 'accounting',
  };

  @override
  final Iterable<Type> types = const <Type>[UserCreateRoleEnum];
  @override
  final String wireName = 'UserCreateRoleEnum';

  @override
  Object serialize(
    Serializers serializers,
    UserCreateRoleEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  UserCreateRoleEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => UserCreateRoleEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$UserCreateSubscriptionEnumSerializer
    implements PrimitiveSerializer<UserCreateSubscriptionEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'free': 'free',
    'premium': 'premium',
    'family': 'family',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'free': 'free',
    'premium': 'premium',
    'family': 'family',
  };

  @override
  final Iterable<Type> types = const <Type>[UserCreateSubscriptionEnum];
  @override
  final String wireName = 'UserCreateSubscriptionEnum';

  @override
  Object serialize(
    Serializers serializers,
    UserCreateSubscriptionEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  UserCreateSubscriptionEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => UserCreateSubscriptionEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$UserCreate extends UserCreate {
  @override
  final String email;
  @override
  final String password;
  @override
  final String? firstname;
  @override
  final String? lastname;
  @override
  final String? country;
  @override
  final UserCreateRoleEnum? role;
  @override
  final UserCreateSubscriptionEnum? subscription;

  factory _$UserCreate([void Function(UserCreateBuilder)? updates]) =>
      (UserCreateBuilder()..update(updates))._build();

  _$UserCreate._({
    required this.email,
    required this.password,
    this.firstname,
    this.lastname,
    this.country,
    this.role,
    this.subscription,
  }) : super._();
  @override
  UserCreate rebuild(void Function(UserCreateBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  UserCreateBuilder toBuilder() => UserCreateBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UserCreate &&
        email == other.email &&
        password == other.password &&
        firstname == other.firstname &&
        lastname == other.lastname &&
        country == other.country &&
        role == other.role &&
        subscription == other.subscription;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, email.hashCode);
    _$hash = $jc(_$hash, password.hashCode);
    _$hash = $jc(_$hash, firstname.hashCode);
    _$hash = $jc(_$hash, lastname.hashCode);
    _$hash = $jc(_$hash, country.hashCode);
    _$hash = $jc(_$hash, role.hashCode);
    _$hash = $jc(_$hash, subscription.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UserCreate')
          ..add('email', email)
          ..add('password', password)
          ..add('firstname', firstname)
          ..add('lastname', lastname)
          ..add('country', country)
          ..add('role', role)
          ..add('subscription', subscription))
        .toString();
  }
}

class UserCreateBuilder implements Builder<UserCreate, UserCreateBuilder> {
  _$UserCreate? _$v;

  String? _email;
  String? get email => _$this._email;
  set email(String? email) => _$this._email = email;

  String? _password;
  String? get password => _$this._password;
  set password(String? password) => _$this._password = password;

  String? _firstname;
  String? get firstname => _$this._firstname;
  set firstname(String? firstname) => _$this._firstname = firstname;

  String? _lastname;
  String? get lastname => _$this._lastname;
  set lastname(String? lastname) => _$this._lastname = lastname;

  String? _country;
  String? get country => _$this._country;
  set country(String? country) => _$this._country = country;

  UserCreateRoleEnum? _role;
  UserCreateRoleEnum? get role => _$this._role;
  set role(UserCreateRoleEnum? role) => _$this._role = role;

  UserCreateSubscriptionEnum? _subscription;
  UserCreateSubscriptionEnum? get subscription => _$this._subscription;
  set subscription(UserCreateSubscriptionEnum? subscription) =>
      _$this._subscription = subscription;

  UserCreateBuilder() {
    UserCreate._defaults(this);
  }

  UserCreateBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _email = $v.email;
      _password = $v.password;
      _firstname = $v.firstname;
      _lastname = $v.lastname;
      _country = $v.country;
      _role = $v.role;
      _subscription = $v.subscription;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UserCreate other) {
    _$v = other as _$UserCreate;
  }

  @override
  void update(void Function(UserCreateBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UserCreate build() => _build();

  _$UserCreate _build() {
    final _$result =
        _$v ??
        _$UserCreate._(
          email: BuiltValueNullFieldError.checkNotNull(
            email,
            r'UserCreate',
            'email',
          ),
          password: BuiltValueNullFieldError.checkNotNull(
            password,
            r'UserCreate',
            'password',
          ),
          firstname: firstname,
          lastname: lastname,
          country: country,
          role: role,
          subscription: subscription,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
