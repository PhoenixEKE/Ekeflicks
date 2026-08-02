import 'package:dio/dio.dart';
import 'package:app_ekeflicks/models/content_model.dart';

class HomeFeed {
  const HomeFeed({required this.featured, required this.continueWatching,
    required this.recommended, required this.newReleases, required this.popular});
  final List<Content> featured, continueWatching, recommended, newReleases, popular;
}

/// Client for the authenticated catalogue and viewing APIs.
class ContentApiService {
  ContentApiService(this._dio)
      : _apiRoot = _dio.options.baseUrl.replaceFirst(RegExp(r'/accounts/?$'), '');
  final Dio _dio;
  final String _apiRoot;

  Future<HomeFeed> home({int? profileId}) async {
    final data = await _getMap('/catalog/home/', profileId: profileId);
    return HomeFeed(
      featured: _contents(data['featured']),
      continueWatching: _contents(data['continue_watching']),
      recommended: _contents(data['recommended']),
      newReleases: _contents(data['new_releases']), popular: _contents(data['popular']));
  }

  Future<Content> detail(String id, {int? profileId}) async =>
      Content.fromJson(await _getMap('/catalog/contents/$id/', profileId: profileId));
  Future<List<Content>> search(String query, {int? profileId}) async =>
      _contents((await _dio.get(_url('/catalog/search/'), queryParameters: {'q': query}, options: _options(profileId))).data);
  Future<List<Content>> favorites({int? profileId}) async =>
      _contents((await _dio.get(_url('/library/favorites/'), options: _options(profileId))).data);
  Future<List<Content>> history({int? profileId}) async =>
      _contents((await _dio.get(_url('/viewing/history/'), options: _options(profileId))).data);
  Future<void> setFavorite(String id, bool value, {int? profileId}) async {
    if (value) {
      await _dio.post(_url('/library/favorites/'), data: {'content_id': id}, options: _options(profileId));
    } else {
      await _dio.delete(_url('/library/favorites/$id/'), options: _options(profileId));
    }
  }
  Future<void> rate(String id, double rating, {int? profileId}) async {
    await _dio.put(_url('/library/ratings/$id/'), data: {'rating': rating}, options: _options(profileId));
  }
  Future<void> saveProgress({required String contentId, String? episodeId,
    required Duration position, required Duration duration, required String deviceId,
    int? profileId}) async {
    await _dio.put(_url('/viewing/progress/$contentId/'), data: {
      'episode_id': episodeId, 'position_seconds': position.inSeconds,
      'duration_seconds': duration.inSeconds, 'device_id': deviceId,
    }, options: _options(profileId));
  }
  Future<List<Content>> listContents(String listId, {int? profileId}) async =>
      _contents((await _dio.get(_url('/library/lists/$listId/'), options: _options(profileId))).data);
  Future<void> addToList(String listId, String contentId, {int? profileId}) async {
    await _dio.post(_url('/library/lists/$listId/items/'),
      data: {'content_id': contentId}, options: _options(profileId));
  }

  Options _options(int? profileId) => Options(headers: profileId == null ? null : {'X-Profile-Id': '$profileId'});
  Future<Map<String, dynamic>> _getMap(String path, {int? profileId}) async {
    final response = await _dio.get(_url(path), options: _options(profileId));
    return Map<String, dynamic>.from(response.data as Map);
  }
  List<Content> _contents(dynamic payload) {
    final raw = payload is Map ? (payload['results'] ?? payload['items'] ?? const []) : payload;
    return (raw as List? ?? const []).whereType<Map>().map((e) => Content.fromJson(Map<String, dynamic>.from(e))).toList();
  }
  String _url(String path) => '$_apiRoot$path';
}
