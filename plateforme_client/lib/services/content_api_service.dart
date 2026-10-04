import 'dart:math';

import 'package:app_ekeflicks/models/content_model.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeFeed {
  const HomeFeed({
    required this.featured,
    required this.continueWatching,
    required this.recommended,
    required this.newReleases,
    required this.popular,
  });
  final List<Content> featured,
      continueWatching,
      recommended,
      newReleases,
      popular;
}

/// Client for the authenticated catalogue and viewing APIs.
class ContentApiService {
  ContentApiService(this._dio);
  final Dio _dio;

  Future<HomeFeed> home({String? profileId}) async {
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

  Future<Content> detail(String id, {String? profileId}) async =>
      Content.fromJson(await _getMap('/contents/$id/', profileId: profileId));

  Future<List<Content>> search(String query, {String? profileId}) async =>
      _contents(
        (await _dio.get(
          _url('/contents/search/'),
          queryParameters: {'q': query},
          options: _options(profileId),
        )).data,
      );

  Future<List<Content>> favorites({String? profileId}) async => _nestedContents(
    (await _dio.get(_url('/favorites/'), options: _options(profileId))).data,
  );

  Future<List<Content>> history({String? profileId}) async => _nestedContents(
    (await _dio.get(
      _url('/watch-history/'),
      options: _options(profileId),
    )).data,
  );

  Future<void> setFavorite(String id, bool value, {String? profileId}) async {
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

  Future<void> rate(String id, double rating, {String? profileId}) async {
    await _dio.post(
      _url('/ratings/'),
      data: {'content_id': id, 'profile_id': profileId, 'rating': rating},
      options: _options(profileId),
    );
  }

  Future<void> saveProgress({
    required String contentId,
    String? episodeId,
    required Duration position,
    required Duration duration,
    required String deviceId,
    String? profileId,
  }) async {
    final progress =
        duration.inSeconds <= 0
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

  /// Fetches a signed manifest and obtains the per-playback Axinom entitlement.
  /// The entitlement stays in memory and is passed to the DRM player only.
  Future<Map<String, dynamic>> preparePlayback({
    required String assetId,
    required String platform,
    required String drmSystem,
    required String profileId,
  }) async {
    final deviceId = await _persistentDeviceId();
    final manifestResponse = await _dio.get(
      _url('/video-assets/$assetId/manifest/'),
      queryParameters: {'platform': platform, 'drm_system': drmSystem},
      options: _options(profileId),
    );
    final manifest = Map<String, dynamic>.from(manifestResponse.data as Map);
    final licenseResponse = await _dio.post(
      _url('/video-assets/$assetId/license/'),
      data: {
        'profile_id': profileId,
        'device_id': deviceId,
        'device_type': platform,
        'platform': platform,
        'drm_system': drmSystem,
      },
      options: _options(profileId),
    );
    final license = Map<String, dynamic>.from(licenseResponse.data as Map);
    final drm = license['drm'] is Map
        ? Map<String, dynamic>.from(license['drm'] as Map)
        : <String, dynamic>{};
    return {
      ...manifest,
      'license': license,
      'drm': drm,
    };
  }

  /// Creates the server-side offline authorization and persistent Axinom license.
  /// The manifest URL uses a longer, subscription-gated signature so large downloads
  /// can finish over slower connections.
  Future<Map<String, dynamic>> prepareOfflineDownload({
    required String assetId,
    required String platform,
    required String drmSystem,
    required String profileId,
  }) async {
    final deviceId = await _persistentDeviceId();
    final manifestResponse = await _dio.get(
      _url('/video-assets/$assetId/manifest/'),
      queryParameters: {
        'platform': platform,
        'drm_system': drmSystem,
        'offline': '1',
      },
      options: _options(profileId),
    );
    final manifest = Map<String, dynamic>.from(manifestResponse.data as Map);
    if (manifest['offline_allowed'] != true) {
      throw StateError('Le forfait ou ce contenu ne permet pas le téléchargement hors ligne.');
    }

    final recordResponse = await _dio.post(
      _url('/video-assets/$assetId/request-offline/'),
      data: {
        'profile_id': profileId,
        'device_id': deviceId,
        'device_type': platform,
        'platform': platform,
      },
      options: _options(profileId),
    );
    final offlineRecord = Map<String, dynamic>.from(recordResponse.data as Map);
    try {
      final licenseResponse = await _dio.post(
        _url('/video-assets/$assetId/offline-license/'),
        data: {
          'profile_id': profileId,
          'device_id': deviceId,
          'device_type': platform,
          'platform': platform,
          'drm_system': drmSystem,
        },
        options: _options(profileId),
      );
      return {
        'manifest': manifest,
        'offline_record': offlineRecord,
        'offline_license': Map<String, dynamic>.from(licenseResponse.data as Map),
        'device_id': deviceId,
      };
    } catch (_) {
      try {
        await revokeOfflineDownload(
          offlineRecord['id'].toString(),
          profileId: profileId,
        );
      } catch (_) {
        // Preserve the original license request failure.
      }
      rethrow;
    }
  }

  Future<void> revokeOfflineDownload(
    String id, {
    required String profileId,
  }) async {
    await _dio.post(
      _url('/offline-licenses/$id/revoke/'),
      options: _options(profileId),
    );
  }

  Future<String> _persistentDeviceId() async {
    final preferences = await SharedPreferences.getInstance();
    final saved = preferences.getString('eke_install_device_id');
    if (saved != null && saved.isNotEmpty) return saved;
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((value) => value.toRadixString(16).padLeft(2, '0')).join();
    final deviceId = '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
    await preferences.setString('eke_install_device_id', deviceId);
    return deviceId;
  }

  Future<List<Content>> listContents(
    String listId, {
    String? profileId,
  }) async => _nestedContents(
    (await _dio.get(
      _url('/lists/$listId/'),
      options: _options(profileId),
    )).data,
    key: 'items',
  );

  Future<void> addToList(
    String listId,
    String contentId, {
    String? profileId,
  }) async {
    await _dio.post(
      _url('/list-items/'),
      data: {'list_id': listId, 'content_id': contentId},
      options: _options(profileId),
    );
  }

  Options _options(String? profileId) =>
      Options(headers: profileId == null ? null : {'X-Profile-Id': profileId});

  Future<Map<String, dynamic>> _getMap(String path, {String? profileId}) async {
    final response = await _dio.get(_url(path), options: _options(profileId));
    return Map<String, dynamic>.from(response.data as Map);
  }

  List<Content> _contents(dynamic payload) {
    final raw =
        payload is Map
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

  Future<List<Map<String, dynamic>>> _records(
    String path,
    String? profileId,
  ) async {
    final response = await _dio.get(_url(path), options: _options(profileId));
    final data = response.data;
    final raw = data is Map ? (data['results'] ?? const []) : data;
    return (raw as List? ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  String _url(String path) => path;
}
