// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const UserRoleEnum _$userRoleEnum_user = const UserRoleEnum._('user');
const UserRoleEnum _$userRoleEnum_admin = const UserRoleEnum._('admin');
const UserRoleEnum _$userRoleEnum_moderator = const UserRoleEnum._('moderator');
const UserRoleEnum _$userRoleEnum_accounting = const UserRoleEnum._(
  'accounting',
);

UserRoleEnum _$userRoleEnumValueOf(String name) {
  switch (name) {
    case 'user':
      return _$userRoleEnum_user;
    case 'admin':
      return _$userRoleEnum_admin;
    case 'moderator':
      return _$userRoleEnum_moderator;
    case 'accounting':
      return _$userRoleEnum_accounting;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<UserRoleEnum> _$userRoleEnumValues =
    BuiltSet<UserRoleEnum>(const <UserRoleEnum>[
      _$userRoleEnum_user,
      _$userRoleEnum_admin,
      _$userRoleEnum_moderator,
      _$userRoleEnum_accounting,
    ]);

const UserStatusEnum _$userStatusEnum_active = const UserStatusEnum._('active');
const UserStatusEnum _$userStatusEnum_inactive = const UserStatusEnum._(
  'inactive',
);
const UserStatusEnum _$userStatusEnum_suspended = const UserStatusEnum._(
  'suspended',
);
const UserStatusEnum _$userStatusEnum_banned = const UserStatusEnum._('banned');
const UserStatusEnum _$userStatusEnum_pending = const UserStatusEnum._(
  'pending',
);

UserStatusEnum _$userStatusEnumValueOf(String name) {
  switch (name) {
    case 'active':
      return _$userStatusEnum_active;
    case 'inactive':
      return _$userStatusEnum_inactive;
    case 'suspended':
      return _$userStatusEnum_suspended;
    case 'banned':
      return _$userStatusEnum_banned;
    case 'pending':
      return _$userStatusEnum_pending;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<UserStatusEnum> _$userStatusEnumValues =
    BuiltSet<UserStatusEnum>(const <UserStatusEnum>[
      _$userStatusEnum_active,
      _$userStatusEnum_inactive,
      _$userStatusEnum_suspended,
      _$userStatusEnum_banned,
      _$userStatusEnum_pending,
    ]);

const UserSubscriptionEnum _$userSubscriptionEnum_free =
    const UserSubscriptionEnum._('free');
const UserSubscriptionEnum _$userSubscriptionEnum_premium =
    const UserSubscriptionEnum._('premium');
const UserSubscriptionEnum _$userSubscriptionEnum_family =
    const UserSubscriptionEnum._('family');

UserSubscriptionEnum _$userSubscriptionEnumValueOf(String name) {
  switch (name) {
    case 'free':
      return _$userSubscriptionEnum_free;
    case 'premium':
      return _$userSubscriptionEnum_premium;
    case 'family':
      return _$userSubscriptionEnum_family;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<UserSubscriptionEnum> _$userSubscriptionEnumValues =
    BuiltSet<UserSubscriptionEnum>(const <UserSubscriptionEnum>[
      _$userSubscriptionEnum_free,
      _$userSubscriptionEnum_premium,
      _$userSubscriptionEnum_family,
    ]);

Serializer<UserRoleEnum> _$userRoleEnumSerializer = _$UserRoleEnumSerializer();
Serializer<UserStatusEnum> _$userStatusEnumSerializer =
    _$UserStatusEnumSerializer();
Serializer<UserSubscriptionEnum> _$userSubscriptionEnumSerializer =
    _$UserSubscriptionEnumSerializer();

class _$UserRoleEnumSerializer implements PrimitiveSerializer<UserRoleEnum> {
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
  final Iterable<Type> types = const <Type>[UserRoleEnum];
  @override
  final String wireName = 'UserRoleEnum';

  @override
  Object serialize(
    Serializers serializers,
    UserRoleEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  UserRoleEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => UserRoleEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$UserStatusEnumSerializer
    implements PrimitiveSerializer<UserStatusEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'active': 'active',
    'inactive': 'inactive',
    'suspended': 'suspended',
    'banned': 'banned',
    'pending': 'pending',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'active': 'active',
    'inactive': 'inactive',
    'suspended': 'suspended',
    'banned': 'banned',
    'pending': 'pending',
  };

  @override
  final Iterable<Type> types = const <Type>[UserStatusEnum];
  @override
  final String wireName = 'UserStatusEnum';

  @override
  Object serialize(
    Serializers serializers,
    UserStatusEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  UserStatusEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => UserStatusEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$UserSubscriptionEnumSerializer
    implements PrimitiveSerializer<UserSubscriptionEnum> {
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
  final Iterable<Type> types = const <Type>[UserSubscriptionEnum];
  @override
  final String wireName = 'UserSubscriptionEnum';

  @override
  Object serialize(
    Serializers serializers,
    UserSubscriptionEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  UserSubscriptionEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => UserSubscriptionEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$User extends User {
  @override
  final int? id;
  @override
  final String email;
  @override
  final String? firstname;
  @override
  final String? lastname;
  @override
  final UserRoleEnum? role;
  @override
  final UserStatusEnum? status;
  @override
  final UserSubscriptionEnum? subscription;
  @override
  final bool? isActive;
  @override
  final DateTime? createdAt;

  factory _$User([void Function(UserBuilder)? updates]) =>
      (UserBuilder()..update(updates))._build();

  _$User._({
    this.id,
    required this.email,
    this.firstname,
    this.lastname,
    this.role,
    this.status,
    this.subscription,
    this.isActive,
    this.createdAt,
  }) : super._();
  @override
  User rebuild(void Function(UserBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  UserBuilder toBuilder() => UserBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is User &&
        id == other.id &&
        email == other.email &&
        firstname == other.firstname &&
        lastname == other.lastname &&
        role == other.role &&
        status == other.status &&
        subscription == other.subscription &&
        isActive == other.isActive &&
        createdAt == other.createdAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, email.hashCode);
    _$hash = $jc(_$hash, firstname.hashCode);
    _$hash = $jc(_$hash, lastname.hashCode);
    _$hash = $jc(_$hash, role.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, subscription.hashCode);
    _$hash = $jc(_$hash, isActive.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'User')
          ..add('id', id)
          ..add('email', email)
          ..add('firstname', firstname)
          ..add('lastname', lastname)
          ..add('role', role)
          ..add('status', status)
          ..add('subscription', subscription)
          ..add('isActive', isActive)
          ..add('createdAt', createdAt))
        .toString();
  }
}

class UserBuilder implements Builder<User, UserBuilder> {
  _$User? _$v;

  int? _id;
  int? get id => _$this._id;
  set id(int? id) => _$this._id = id;

  String? _email;
  String? get email => _$this._email;
  set email(String? email) => _$this._email = email;

  String? _firstname;
  String? get firstname => _$this._firstname;
  set firstname(String? firstname) => _$this._firstname = firstname;

  String? _lastname;
  String? get lastname => _$this._lastname;
  set lastname(String? lastname) => _$this._lastname = lastname;

  UserRoleEnum? _role;
  UserRoleEnum? get role => _$this._role;
  set role(UserRoleEnum? role) => _$this._role = role;

  UserStatusEnum? _status;
  UserStatusEnum? get status => _$this._status;
  set status(UserStatusEnum? status) => _$this._status = status;

  UserSubscriptionEnum? _subscription;
  UserSubscriptionEnum? get subscription => _$this._subscription;
  set subscription(UserSubscriptionEnum? subscription) =>
      _$this._subscription = subscription;

  bool? _isActive;
  bool? get isActive => _$this._isActive;
  set isActive(bool? isActive) => _$this._isActive = isActive;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  UserBuilder() {
    User._defaults(this);
  }

  UserBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _email = $v.email;
      _firstname = $v.firstname;
      _lastname = $v.lastname;
      _role = $v.role;
      _status = $v.status;
      _subscription = $v.subscription;
      _isActive = $v.isActive;
      _createdAt = $v.createdAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(User other) {
    _$v = other as _$User;
  }

  @override
  void update(void Function(UserBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  User build() => _build();

  _$User _build() {
    final _$result =
        _$v ??
        _$User._(
          id: id,
          email: BuiltValueNullFieldError.checkNotNull(email, r'User', 'email'),
          firstname: firstname,
          lastname: lastname,
          role: role,
          status: status,
          subscription: subscription,
          isActive: isActive,
          createdAt: createdAt,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
