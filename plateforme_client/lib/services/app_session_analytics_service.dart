import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class AppSessionAnalyticsService {
  AppSessionAnalyticsService(this._dio);

  final Dio _dio;

  String? _sessionId;
  String? _profileId;
  DateTime? _startedAt;
  bool _isForeground = true;

  Future<void> _transition = Future<void>.value();

  String? get sessionId => _sessionId;
  String? get profileId => _profileId;

  bool get hasActiveSession =>
      _sessionId != null && _profileId != null && _startedAt != null;

  Future<void> setProfile(String? profileId) {
    final normalized = profileId?.trim();

    return _enqueue(() async {
      if (normalized == null || normalized.isEmpty) {
        await _endSessionNow();
        _profileId = null;
        return;
      }

      if (_profileId == normalized) {
        if (_isForeground && !hasActiveSession) {
          await _startSessionNow();
        }
        return;
      }

      await _endSessionNow();
      _profileId = normalized;

      if (_isForeground) {
        await _startSessionNow();
      }
    });
  }

  Future<void> onForeground() {
    _isForeground = true;

    return _enqueue(() async {
      if (_isForeground && _profileId != null && !hasActiveSession) {
        await _startSessionNow();
      }
    });
  }

  Future<void> onBackground() {
    _isForeground = false;

    return _enqueue(() async {
      if (!_isForeground) {
        await _endSessionNow();
      }
    });
  }

  Future<void> startSession() {
    return _enqueue(() async {
      if (_isForeground && _profileId != null && !hasActiveSession) {
        await _startSessionNow();
      }
    });
  }

  Future<void> endSession() {
    return _enqueue(_endSessionNow);
  }

  Future<void> _enqueue(Future<void> Function() operation) {
    final completer = Completer<void>();

    _transition = _transition.then((_) async {
      try {
        await operation();
        completer.complete();
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });

    // Keep the internal queue alive even if one caller observes an error.
    _transition = _transition.catchError((Object _) {});

    return completer.future;
  }

  Future<void> _startSessionNow() async {
    final profileId = _profileId;

    if (!_isForeground ||
        profileId == null ||
        profileId.isEmpty ||
        hasActiveSession) {
      return;
    }

    final sessionId = _uuidV4();
    final startedAt = DateTime.now().toUtc();

    try {
      await _dio.post<Object>(
        '/app-sessions/events/',
        data: <String, dynamic>{
          'event': 'start',
          'profile_id': profileId,
          'session_id': sessionId,
          'occurred_at': startedAt.toIso8601String(),
          'platform': _platformName(),
          'device_type': _deviceType(),
          'timezone': DateTime.now().timeZoneName,
          'properties': <String, dynamic>{},
        },
      );

      // A queued background/profile transition will run immediately after
      // this operation and close/switch this exact session if required.
      _sessionId = sessionId;
      _startedAt = startedAt;
    } catch (error) {
      debugPrint('App session start analytics failed: $error');
    }
  }

  Future<void> _endSessionNow() async {
    final sessionId = _sessionId;
    final profileId = _profileId;
    final startedAt = _startedAt;

    if (sessionId == null || profileId == null || startedAt == null) {
      _sessionId = null;
      _startedAt = null;
      return;
    }

    final endedAt = DateTime.now().toUtc();
    final duration = endedAt.difference(startedAt).inSeconds;
    final safeDuration = duration < 0 ? 0 : duration;

    // Clear before I/O. A duplicate background/end notification cannot
    // generate a second END for this session.
    _sessionId = null;
    _startedAt = null;

    try {
      await _dio.post<Object>(
        '/app-sessions/events/',
        data: <String, dynamic>{
          'event': 'end',
          'profile_id': profileId,
          'session_id': sessionId,
          'occurred_at': endedAt.toIso8601String(),
          'platform': _platformName(),
          'device_type': _deviceType(),
          'timezone': DateTime.now().timeZoneName,
          'duration_seconds': safeDuration,
          'properties': <String, dynamic>{},
        },
      );
    } catch (error) {
      debugPrint('App session end analytics failed: $error');
    }
  }

  String _platformName() {
    if (kIsWeb) return 'web';

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.fuchsia:
        return 'fuchsia';
    }
  }

  String _deviceType() {
    if (kIsWeb) return 'web';

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        return 'mobile';
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return 'desktop';
      case TargetPlatform.fuchsia:
        return 'other';
    }
  }

  String _uuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));

    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    final hex =
        bytes.map((value) => value.toRadixString(16).padLeft(2, '0')).join();

    return '${hex.substring(0, 8)}-'
        '${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-'
        '${hex.substring(16, 20)}-'
        '${hex.substring(20, 32)}';
  }
}
