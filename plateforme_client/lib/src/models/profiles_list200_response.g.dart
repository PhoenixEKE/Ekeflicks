// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profiles_list200_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ProfilesList200Response extends ProfilesList200Response {
  @override
  final int count;
  @override
  final String? next;
  @override
  final String? previous;
  @override
  final BuiltList<Profile> results;

  factory _$ProfilesList200Response([
    void Function(ProfilesList200ResponseBuilder)? updates,
  ]) => (ProfilesList200ResponseBuilder()..update(updates))._build();

  _$ProfilesList200Response._({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  }) : super._();
  @override
  ProfilesList200Response rebuild(
    void Function(ProfilesList200ResponseBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  ProfilesList200ResponseBuilder toBuilder() =>
      ProfilesList200ResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ProfilesList200Response &&
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
    return (newBuiltValueToStringHelper(r'ProfilesList200Response')
          ..add('count', count)
          ..add('next', next)
          ..add('previous', previous)
          ..add('results', results))
        .toString();
  }
}

class ProfilesList200ResponseBuilder
    implements
        Builder<ProfilesList200Response, ProfilesList200ResponseBuilder> {
  _$ProfilesList200Response? _$v;

  int? _count;
  int? get count => _$this._count;
  set count(int? count) => _$this._count = count;

  String? _next;
  String? get next => _$this._next;
  set next(String? next) => _$this._next = next;

  String? _previous;
  String? get previous => _$this._previous;
  set previous(String? previous) => _$this._previous = previous;

  ListBuilder<Profile>? _results;
  ListBuilder<Profile> get results =>
      _$this._results ??= ListBuilder<Profile>();
  set results(ListBuilder<Profile>? results) => _$this._results = results;

  ProfilesList200ResponseBuilder() {
    ProfilesList200Response._defaults(this);
  }

  ProfilesList200ResponseBuilder get _$this {
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
  void replace(ProfilesList200Response other) {
    _$v = other as _$ProfilesList200Response;
  }

  @override
  void update(void Function(ProfilesList200ResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ProfilesList200Response build() => _build();

  _$ProfilesList200Response _build() {
    _$ProfilesList200Response _$result;
    try {
      _$result =
          _$v ??
          _$ProfilesList200Response._(
            count: BuiltValueNullFieldError.checkNotNull(
              count,
              r'ProfilesList200Response',
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
          r'ProfilesList200Response',
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
