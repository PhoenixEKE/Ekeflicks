// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'users_list200_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$UsersList200Response extends UsersList200Response {
  @override
  final int count;
  @override
  final String? next;
  @override
  final String? previous;
  @override
  final BuiltList<User> results;

  factory _$UsersList200Response([
    void Function(UsersList200ResponseBuilder)? updates,
  ]) => (UsersList200ResponseBuilder()..update(updates))._build();

  _$UsersList200Response._({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  }) : super._();
  @override
  UsersList200Response rebuild(
    void Function(UsersList200ResponseBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  UsersList200ResponseBuilder toBuilder() =>
      UsersList200ResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UsersList200Response &&
        count == other.count &&
        next == other.next &&
        previous == other.previous &&
        results == other.results;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, count.hashCode);
    _$hash = $jc(_$hash, next.hashCode);
    _$hash = $jc(_$hash, previous.hashCode);
    _$hash = $jc(_$hash, results.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UsersList200Response')
          ..add('count', count)
          ..add('next', next)
          ..add('previous', previous)
          ..add('results', results))
        .toString();
  }
}

class UsersList200ResponseBuilder
    implements Builder<UsersList200Response, UsersList200ResponseBuilder> {
  _$UsersList200Response? _$v;

  int? _count;
  int? get count => _$this._count;
  set count(int? count) => _$this._count = count;

  String? _next;
  String? get next => _$this._next;
  set next(String? next) => _$this._next = next;

  String? _previous;
  String? get previous => _$this._previous;
  set previous(String? previous) => _$this._previous = previous;

  ListBuilder<User>? _results;
  ListBuilder<User> get results => _$this._results ??= ListBuilder<User>();
  set results(ListBuilder<User>? results) => _$this._results = results;

  UsersList200ResponseBuilder() {
    UsersList200Response._defaults(this);
  }

  UsersList200ResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _count = $v.count;
      _next = $v.next;
      _previous = $v.previous;
      _results = $v.results.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UsersList200Response other) {
    _$v = other as _$UsersList200Response;
  }

  @override
  void update(void Function(UsersList200ResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UsersList200Response build() => _build();

  _$UsersList200Response _build() {
    _$UsersList200Response _$result;
    try {
      _$result =
          _$v ??
          _$UsersList200Response._(
            count: BuiltValueNullFieldError.checkNotNull(
              count,
              r'UsersList200Response',
              'count',
            ),
            next: next,
            previous: previous,
            results: results.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'results';
        results.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'UsersList200Response',
          _$failedField,
          e.toString(),
        );
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
