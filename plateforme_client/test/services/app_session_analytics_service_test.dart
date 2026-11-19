import 'dart:async';

import 'package:app_ekeflicks/services/app_session_analytics_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordedRequest {
  _RecordedRequest(this.data);

  final Map<String, dynamic> data;
}

class _RecordingAdapter implements HttpClientAdapter {
  final List<_RecordedRequest> requests = <_RecordedRequest>[];
  Completer<void>? blockNextRequest;
  Completer<void>? nextRequestEntered;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final data = Map<String, dynamic>.from(options.data as Map);

    requests.add(_RecordedRequest(data));

    final entered = nextRequestEntered;
    nextRequestEntered = null;
    if (entered != null && !entered.isCompleted) {
      entered.complete();
    }

    final blocker = blockNextRequest;
    blockNextRequest = null;

    if (blocker != null) {
      await blocker.future;
    }

    return ResponseBody.fromString(
      '{"accepted":true}',
      202,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late Dio dio;
  late _RecordingAdapter adapter;
  late AppSessionAnalyticsService service;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    adapter = _RecordingAdapter();
    dio.httpClientAdapter = adapter;
    service = AppSessionAnalyticsService(dio);
  });

  test('profile selection starts exactly one session', () async {
    await service.setProfile('11111111-1111-4111-8111-111111111111');
    await service.setProfile('11111111-1111-4111-8111-111111111111');

    expect(adapter.requests, hasLength(1));
    expect(adapter.requests.single.data['event'], 'start');
    expect(service.hasActiveSession, isTrue);
  });

  test(
    'background closes session and duplicate background does not duplicate end',
    () async {
      await service.setProfile('11111111-1111-4111-8111-111111111111');

      final sessionId = service.sessionId;

      await service.onBackground();
      await service.onBackground();

      expect(adapter.requests, hasLength(2));
      expect(adapter.requests[0].data['event'], 'start');
      expect(adapter.requests[1].data['event'], 'end');
      expect(adapter.requests[1].data['session_id'], sessionId);
      expect(service.hasActiveSession, isFalse);
    },
  );

  test('resume creates a new session UUID', () async {
    await service.setProfile('11111111-1111-4111-8111-111111111111');

    final firstSession = service.sessionId;

    await service.onBackground();
    await service.onForeground();

    final secondSession = service.sessionId;

    expect(adapter.requests, hasLength(3));
    expect(adapter.requests[0].data['event'], 'start');
    expect(adapter.requests[1].data['event'], 'end');
    expect(adapter.requests[2].data['event'], 'start');

    expect(firstSession, isNotNull);
    expect(secondSession, isNotNull);
    expect(secondSession, isNot(firstSession));
  });

  test('profile switch closes A before starting B', () async {
    const profileA = '11111111-1111-4111-8111-111111111111';
    const profileB = '22222222-2222-4222-8222-222222222222';

    await service.setProfile(profileA);
    final sessionA = service.sessionId;

    await service.setProfile(profileB);

    expect(adapter.requests, hasLength(3));

    expect(adapter.requests[0].data['event'], 'start');
    expect(adapter.requests[0].data['profile_id'], profileA);

    expect(adapter.requests[1].data['event'], 'end');
    expect(adapter.requests[1].data['profile_id'], profileA);
    expect(adapter.requests[1].data['session_id'], sessionA);

    expect(adapter.requests[2].data['event'], 'start');
    expect(adapter.requests[2].data['profile_id'], profileB);

    expect(service.profileId, profileB);
    expect(service.sessionId, isNot(sessionA));
  });

  test('clearing profile closes active session', () async {
    await service.setProfile('11111111-1111-4111-8111-111111111111');

    await service.setProfile(null);

    expect(adapter.requests, hasLength(2));
    expect(adapter.requests.last.data['event'], 'end');
    expect(service.profileId, isNull);
    expect(service.hasActiveSession, isFalse);
  });

  test(
    'background queued during pending start still emits matching end',
    () async {
      final blocker = Completer<void>();
      final requestEntered = Completer<void>();

      adapter.blockNextRequest = blocker;
      adapter.nextRequestEntered = requestEntered;

      final startFuture = service.setProfile(
        '11111111-1111-4111-8111-111111111111',
      );

      // Wait until START has really entered the fake HTTP adapter.
      await requestEntered.future;

      expect(adapter.requests, hasLength(1));
      expect(adapter.requests.first.data['event'], 'start');

      // Queue background while START is deliberately still pending.
      final backgroundFuture = service.onBackground();

      blocker.complete();

      await startFuture;
      await backgroundFuture;

      expect(adapter.requests, hasLength(2));

      final start = adapter.requests[0].data;
      final end = adapter.requests[1].data;

      expect(start['event'], 'start');
      expect(end['event'], 'end');
      expect(end['session_id'], start['session_id']);
      expect(end['profile_id'], start['profile_id']);
      expect(service.hasActiveSession, isFalse);
    },
  );

  test('UUID has RFC4122 v4 shape', () async {
    await service.setProfile('11111111-1111-4111-8111-111111111111');

    final id = service.sessionId!;

    expect(
      id,
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-'
          r'[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
    );
  });

  test('app session payload never contains viewing_session_id', () async {
    await service.setProfile('11111111-1111-4111-8111-111111111111');
    await service.onBackground();

    for (final request in adapter.requests) {
      expect(request.data.containsKey('viewing_session_id'), isFalse);
    }
  });
}
