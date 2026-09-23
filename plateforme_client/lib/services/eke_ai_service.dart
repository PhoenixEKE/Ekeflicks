import 'package:dio/dio.dart';

import 'package:app_ekeflicks/models/eke_ai_models.dart';

/// Spectator client for the single public EKE IA API surface.
///
/// Authentication is intentionally not duplicated here. The injected Dio
/// instance is the same authenticated client already maintained by
/// UserProvider/Openapi.
class EkeAIService {
  static const String apiVersion = 'g5_2l_v1';
  static const String _prefix = 'eke-ai';

  final Dio _dio;

  EkeAIService(this._dio);

  Future<EkeAIStatus> status() async {
    final response = await _dio.get<Object>('$_prefix/status/');
    return EkeAIStatus.fromJson(_map(response.data));
  }

  Future<EkeAIRecommendationResponse> forYou({int limit = 20}) async {
    final response = await _dio.get<Object>(
      '$_prefix/for-you/',
      queryParameters: {'limit': _limit(limit, max: 50)},
    );
    return EkeAIRecommendationResponse.fromJson(_map(response.data));
  }

  Future<EkeAIRecommendationResponse> search(
    String query, {
    int limit = 20,
  }) async {
    final normalized = query.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(query, 'query', 'La recherche est vide.');
    }

    final response = await _dio.post<Object>(
      '$_prefix/search/',
      data: {'query': normalized, 'limit': _limit(limit, max: 50)},
    );
    return EkeAIRecommendationResponse.fromJson(_map(response.data));
  }

  Future<EkeAIRecommendationResponse> chat(
    String message, {
    int limit = 10,
  }) async {
    final normalized = message.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(message, 'message', 'Le message est vide.');
    }

    final response = await _dio.post<Object>(
      '$_prefix/chat/',
      data: {'message': normalized, 'limit': _limit(limit, max: 20)},
    );
    return EkeAIRecommendationResponse.fromJson(_map(response.data));
  }

  Future<EkeAIExplanation> explain(String contentId) async {
    final normalized = contentId.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(
        contentId,
        'contentId',
        'Le contenu est obligatoire.',
      );
    }

    final response = await _dio.post<Object>(
      '$_prefix/explain/',
      data: {'content_id': normalized},
    );
    return EkeAIExplanation.fromJson(_map(response.data));
  }

  Future<Map<String, dynamic>> feedback({
    required String contentId,
    required String action,
    num? rating,
  }) async {
    final normalizedContentId = contentId.trim();
    final normalizedAction = action.trim();

    if (normalizedContentId.isEmpty) {
      throw ArgumentError.value(
        contentId,
        'contentId',
        'Le contenu est obligatoire.',
      );
    }
    if (normalizedAction.isEmpty) {
      throw ArgumentError.value(action, 'action', 'L’action est obligatoire.');
    }

    final payload = <String, dynamic>{
      'content_id': normalizedContentId,
      'action': normalizedAction,
      if (rating != null) 'rating': rating,
    };

    final response = await _dio.post<Object>(
      '$_prefix/feedback/',
      data: payload,
    );
    return _map(response.data);
  }

  static int _limit(int value, {required int max}) {
    if (value < 1) return 1;
    if (value > max) return max;
    return value;
  }

  static Map<String, dynamic> _map(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    return <String, dynamic>{};
  }
}
