import 'package:dio/dio.dart';
import 'package:app_ekeflicks/models/content_model.dart';

class HomeFeed {
  const HomeFeed({
    required this.featured,
    required this.continueWatching,
    required this.recommended,
    required this.newReleases,
    required this.popular,
  });
  final List<Content> featured, continueWatching, recommended, newReleases, popular;
}

/// Client for the authenticated catalogue and viewing APIs.
class ContentApiService {
  ContentApiService(this._dio);
  final Dio _dio;

  Future<HomeFeed> home({int? profileId}) async {
    final data = await _getMap('/contents/home/', profileId: profileId);
    final rows = (data['rows'] as List? ?? const []).whereType<Map>();
    List<Content> row(String key) {
      final match = rows.where((item) => item['key'] == key);
      return match.isEmpty ? const [] : _contents(match.first['items']);
    }
    return HomeFeed(
      featured: row('hero'),
      continueWatching: row('continue_watching'),
      recommended: row('recommended'),
      newReleases: row('new_releases'),
      popular: row('trending'),
    );
  }

  Future<Content> detail(String id, {int? profileId}) async =>
      Content.fromJson(await _getMap('/contents/$id/', profileId: profileId));

  Future<List<Content>> search(String query, {int? profileId}) async =>
      _contents((await _dio.get(
        _url('/contents/search/'),
        queryParameters: {'q': query},
        options: _options(profileId),
      )).data);

  Future<List<Content>> favorites({int? profileId}) async =>
      _nestedContents((await _dio.get(
        _url('/favorites/'),
        options: _options(profileId),
      )).data);

  Future<List<Content>> history({int? profileId}) async =>
      _nestedContents((await _dio.get(
        _url('/watch-history/'),
        options: _options(profileId),
      )).data);

  Future<void> setFavorite(String id, bool value, {int? profileId}) async {
    if (value) {
      await _dio.post(
        _url('/favorites/'),
        data: {'content_id': id, 'profile_id': profileId},
        options: _options(profileId),
      );
    } else {
      final records = await _records('/favorites/', profileId);
      final record = records.where(
        (item) => '${(item['content'] as Map?)?['id']}' == id,
      );
      if (record.isNotEmpty) {
        await _dio.delete(
          _url('/favorites/${record.first['id']}/'),
          options: _options(profileId),
        );
      }
    }
  }

  Future<void> rate(String id, double rating, {int? profileId}) async {
    await _dio.post(
      _url('/ratings/'),
      data: {
        'content_id': id,
        'profile_id': profileId,
        'rating': rating,
      },
      options: _options(profileId),
    );
  }

  Future<void> saveProgress({
    required String contentId,
    String? episodeId,
    required Duration position,
    required Duration duration,
    required String deviceId,
    int? profileId,
  }) async {
    final progress = duration.inSeconds <= 0
        ? 0
        : position.inSeconds * 100 / duration.inSeconds;
    await _dio.post(
      _url('/watch-history/'),
      data: {
        'profile_id': profileId,
        'content_id': contentId,
        'episode_id': episodeId,
        'progress': progress.clamp(0, 100),
        'last_position': position.inSeconds,
        'watched_duration': position.inSeconds,
      },
      options: _options(profileId),
    );
  }

  Future<List<Content>> listContents(String listId, {int? profileId}) async =>
      _nestedContents(
        (await _dio.get(
          _url('/lists/$listId/'),
          options: _options(profileId),
        )).data,
        key: 'items',
      );

  Future<void> addToList(String listId, String contentId, {int? profileId}) async {
    await _dio.post(
      _url('/list-items/'),
      data: {'list_id': listId, 'content_id': contentId},
      options: _options(profileId),
    );
  }

  Options _options(int? profileId) => Options(
    headers: profileId == null ? null : {'X-Profile-Id': '$profileId'},
  );

  Future<Map<String, dynamic>> _getMap(String path, {int? profileId}) async {
    final response = await _dio.get(
      _url(path),
      options: _options(profileId),
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  List<Content> _contents(dynamic payload) {
    final raw = payload is Map
        ? (payload['results'] ?? payload['items'] ?? const [])
        : payload;
    return (raw as List? ?? const [])
        .whereType<Map>()
        .map((e) => Content.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  List<Content> _nestedContents(dynamic payload, {String? key}) {
    dynamic raw = payload;
    if (raw is Map) {
      raw = key == null ? (raw['results'] ?? const []) : (raw[key] ?? const []);
    }
    return (raw as List? ?? const [])
        .whereType<Map>()
        .map((item) => item['content'])
        .whereType<Map>()
        .map((item) => Content.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<List<Map<String, dynamic>>> _records(String path, int? profileId) async {
    final response = await _dio.get(
      _url(path),
      options: _options(profileId),
    );
    final data = response.data;
    final raw = data is Map ? (data['results'] ?? const []) : data;
    return (raw as List? ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  String _url(String path) => path;
}
