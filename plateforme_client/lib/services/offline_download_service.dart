
import 'package:app_ekeflicks/services/content_api_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Coordinates the authenticated download grant with the native DRM downloaders.
class OfflineDownloadService {
  OfflineDownloadService(this._api);

  final ContentApiService _api;
  static const MethodChannel _channel = MethodChannel('ekeflicks/offline');

  static bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> download({
    required String assetId,
    required String title,
    String? posterUrl,
    required String profileId,
    required String platform,
    required String drmSystem,
  }) async {
    if (!isSupported) {
      throw UnsupportedError('Le téléchargement hors ligne est disponible sur Android et iOS.');
    }

    final setup = await _api.prepareOfflineDownload(
      assetId: assetId,
      platform: platform,
      drmSystem: drmSystem,
      profileId: profileId,
    );
    final manifest = Map<String, dynamic>.from(setup['manifest'] as Map);
    final record = Map<String, dynamic>.from(setup['offline_record'] as Map);
    final license = Map<String, dynamic>.from(setup['offline_license'] as Map);
    final drm = license['drm'] is Map
        ? Map<String, dynamic>.from(license['drm'] as Map)
        : <String, dynamic>{};
    final drmRequired = manifest['drm_required'] == true;
    final drmProvider = manifest['drm_provider']?.toString() ?? 'none';

    if (drmRequired && drmProvider != 'axinom') {
      await _revokeQuietly(record['id'], profileId);
      throw StateError('Le téléchargement protégé exige une licence Axinom persistante.');
    }

    final licenseUrl = (drm['license_url'] ??
            license['provider_license_url'] ??
            manifest['provider_license_url'])
        ?.toString() ??
        '';
    final token = drm['entitlement_token']?.toString() ?? '';
    if (drmRequired && (licenseUrl.isEmpty || token.isEmpty)) {
      await _revokeQuietly(record['id'], profileId);
      throw StateError('La licence Axinom hors ligne est incomplète.');
    }

    final manifestUrl = platform == 'ios'
        ? manifest['hls_master_url']?.toString() ?? ''
        : manifest['dash_manifest_url']?.toString() ?? '';
    if (manifestUrl.isEmpty) {
      await _revokeQuietly(record['id'], profileId);
      throw StateError('Le manifeste adapté à cet appareil est indisponible.');
    }

    try {
      await _channel.invokeMethod<void>('download', {
        'assetId': assetId,
        'title': title,
        'posterUrl': posterUrl ?? '',
        'profileId': profileId,
        'platform': platform,
        'drmSystem': drmSystem,
        'drmRequired': drmRequired,
        'manifestUrl': manifestUrl,
        'licenseUrl': licenseUrl,
        'entitlementToken': token,
        'certificateUrl':
            (drm['fairplay_certificate_url'] ?? license['fairplay_certificate_url'])
                    ?.toString() ??
                '',
        'expiresAt': record['expires_at']?.toString() ??
            license['expires_at']?.toString() ??
            '',
        'serverLicenseId': record['id']?.toString() ?? '',
      });
    } catch (_) {
      await _revokeQuietly(record['id'], profileId);
      rethrow;
    }
  }

  Future<List<OfflineDownload>> list() async {
    if (!isSupported) return const [];
    final raw = await _channel.invokeListMethod<Object?>('list') ?? const [];
    return raw
        .whereType<Map>()
        .map((row) => OfflineDownload.fromMap(
              Map<String, dynamic>.from(row),
            ))
        .toList(growable: false);
  }

  Future<void> play(OfflineDownload download) async {
    if (download.isExpired) {
      throw StateError('La licence hors ligne de cette vidéo a expiré.');
    }
    if (download.status != 'completed') {
      throw StateError('Le téléchargement de cette vidéo n’est pas terminé.');
    }
    await _channel.invokeMethod<void>('play', {'assetId': download.assetId});
  }

  Future<void> pauseAll() async {
    await _channel.invokeMethod<void>('pause');
  }

  Future<void> resumeAll() async {
    await _channel.invokeMethod<void>('resume');
  }

  /// Deletes local encrypted media and then revokes the matching API record.
  /// Local removal still completes if the device is offline; the server record
  /// will naturally expire with its short-lived offline grant.
  Future<bool> remove(
    OfflineDownload download, {
    required String profileId,
  }) async {
    await _channel.invokeMethod<void>('remove', {'assetId': download.assetId});
    if (download.serverLicenseId.isEmpty) return true;
    try {
      await _api.revokeOfflineDownload(
        download.serverLicenseId,
        profileId: profileId,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _revokeQuietly(dynamic id, String profileId) async {
    final value = id?.toString() ?? '';
    if (value.isEmpty) return;
    try {
      await _api.revokeOfflineDownload(value, profileId: profileId);
    } catch (_) {
      // The original download error is more useful to the user.
    }
  }
}

class OfflineDownload {
  const OfflineDownload({
    required this.assetId,
    required this.title,
    required this.posterUrl,
    required this.profileId,
    required this.platform,
    required this.status,
    required this.progress,
    required this.serverLicenseId,
    this.expiresAt,
    this.error,
  });

  final String assetId;
  final String title;
  final String posterUrl;
  final String profileId;
  final String platform;
  final String status;
  final double progress;
  final String serverLicenseId;
  final DateTime? expiresAt;
  final String? error;

  bool get isExpired =>
      expiresAt != null && !expiresAt!.isAfter(DateTime.now());

  bool get canPlay => status == 'completed' && !isExpired;

  factory OfflineDownload.fromMap(Map<String, dynamic> value) {
    final rawProgress = value['progress'];
    final progress = rawProgress is num ? rawProgress.toDouble() : 0.0;
    return OfflineDownload(
      assetId: value['assetId']?.toString() ?? '',
      title: value['title']?.toString() ?? 'Vidéo',
      posterUrl: value['posterUrl']?.toString() ?? '',
      profileId: value['profileId']?.toString() ?? '',
      platform: value['platform']?.toString() ?? '',
      status: value['status']?.toString() ?? 'queued',
      progress: progress.clamp(0, 100).toDouble(),
      serverLicenseId: value['serverLicenseId']?.toString() ?? '',
      expiresAt: DateTime.tryParse(value['expiresAt']?.toString() ?? ''),
      error: value['error']?.toString(),
    );
  }
}
