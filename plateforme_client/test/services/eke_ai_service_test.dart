import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_ekeflicks/services/eke_ai_service.dart';

class _RecordedRequest {
  final String method;
  final Uri uri;
  final Object? data;

  const _RecordedRequest({
    required this.method,
    required this.uri,
    required this.data,
  });
}

class _FakeAdapter implements HttpClientAdapter {
  final List<_RecordedRequest> requests = [];
  final Map<String, Object?> responses = {};

  String _key(String method, Uri uri) => '$method ${uri.path}';

  void reply(String method, String path, Object? body) {
    responses['${method.toUpperCase()} $path'] = body;
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(
      _RecordedRequest(
        method: options.method,
        uri: options.uri,
        data: options.data,
      ),
    );

    final key = _key(options.method.toUpperCase(), options.uri);

    if (!responses.containsKey(key)) {
      return ResponseBody.fromString(
        jsonEncode({'detail': 'No fake response registered for $key'}),
        404,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }

    return ResponseBody.fromString(
      jsonEncode(responses[key]),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late Dio dio;
  late _FakeAdapter adapter;
  late EkeAIService service;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'https://api.ekeflicks.com/api/v1/'));

    adapter = _FakeAdapter();
    dio.httpClientAdapter = adapter;
    service = EkeAIService(dio);
  });

  test('status uses /api/v1/eke-ai/status/', () async {
    adapter.reply('GET', '/api/v1/eke-ai/status/', {
      'api_version': 'g5_2k_v1',
      'capabilities': [
        'chat',
        'explain',
        'feedback',
        'for-you',
        'search',
        'status',
      ],
    });

    final result = await service.status();

    expect(result.apiVersion, 'g5_2k_v1');
    expect(result.capabilities, contains('search'));

    expect(adapter.requests.single.uri.path, '/api/v1/eke-ai/status/');
  });

  test('forYou preserves api/v1 prefix and clamps limit', () async {
    adapter.reply('GET', '/api/v1/eke-ai/for-you/', {
      'results': [
        {
          'content': {
            'id': 'content-1',
            'title': 'Film test',
            'poster_url': 'https://cdn.ekeflicks.com/poster.webp',
          },
          'score': 0.91,
        },
      ],
    });

    final result = await service.forYou(limit: 500);

    expect(result.items, hasLength(1));
    expect(result.items.first.id, 'content-1');

    final request = adapter.requests.single;
    expect(request.uri.path, '/api/v1/eke-ai/for-you/');
    expect(request.uri.queryParameters['limit'], '50');
  });

  test('search sends grounded query to public EKE IA API', () async {
    adapter.reply('POST', '/api/v1/eke-ai/search/', {
      'api_version': 'g5_2k_v1',
      'results': [
        {'id': '42', 'title': 'Résultat EKE IA'},
      ],
    });

    final result = await service.search(' film africain ', limit: 7);

    expect(result.items.single.id, '42');

    final request = adapter.requests.single;

    expect(request.uri.path, '/api/v1/eke-ai/search/');

    expect(request.data, {'query': 'film africain', 'limit': 7});
  });

  test('chat uses public EKE IA chat API', () async {
    adapter.reply('POST', '/api/v1/eke-ai/chat/', {
      'message': 'Voici une sélection.',
      'recommendations': [
        {'id': '7', 'title': 'Découverte'},
      ],
    });

    final result = await service.chat('Je veux découvrir un film');

    expect(result.message, 'Voici une sélection.');

    expect(adapter.requests.single.uri.path, '/api/v1/eke-ai/chat/');
  });

  test('explain uses grounded content id', () async {
    adapter.reply('POST', '/api/v1/eke-ai/explain/', {
      'explanation': 'Ce contenu correspond à vos préférences.',
    });

    final result = await service.explain('content-9');

    expect(result.explanation, 'Ce contenu correspond à vos préférences.');

    expect(adapter.requests.single.data, {'content_id': 'content-9'});
  });

  test('feedback sends existing backend action', () async {
    adapter.reply('POST', '/api/v1/eke-ai/feedback/', {'status': 'ok'});

    final result = await service.feedback(
      contentId: 'content-5',
      action: 'favorite',
    );

    expect(result['status'], 'ok');

    expect(adapter.requests.single.data, {
      'content_id': 'content-5',
      'action': 'favorite',
    });
  });

  test('empty search and chat do not reach HTTP', () async {
    await expectLater(service.search('   '), throwsA(isA<ArgumentError>()));

    await expectLater(service.chat('   '), throwsA(isA<ArgumentError>()));

    expect(adapter.requests, isEmpty);
  });

  test('service defines no independent auth storage', () {
    final contract = jsonEncode({'apiVersion': EkeAIService.apiVersion});

    expect(contract, contains('g5_2l_v1'));
    expect(dio.options.headers['Authorization'], isNull);
  });
}
