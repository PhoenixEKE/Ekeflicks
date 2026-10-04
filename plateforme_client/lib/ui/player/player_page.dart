import 'package:app_ekeflicks/core/app_responsive.dart';
import 'package:app_ekeflicks/l10n/app_localizations.dart';
import 'package:app_ekeflicks/providers/profile_provider.dart';
import 'package:app_ekeflicks/providers/content_provider.dart';
import 'package:app_ekeflicks/providers/device_info_provider.dart';
import 'package:app_ekeflicks/services/native_screen_retainer.dart';
import 'package:app_ekeflicks/services/content_api_service.dart';
import 'package:app_ekeflicks/services/offline_download_service.dart';
import 'package:app_ekeflicks/utils/browser_info.dart';
import 'package:app_ekeflicks/ui/salons/ekeroom_page.dart';
import 'package:better_player/better_player.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

/// Client playback uses signed API manifests and asks the API for a short-lived
/// Axinom entitlement immediately before opening protected streams.
class PlayerPage extends StatefulWidget {
  final String videoUrl;
  final String title;
  final String? imageUrl;
  final Duration? resumePosition;
  final bool isTrailer;
  final dynamic episodeData;
  final List<dynamic>? seasons;
  final bool isSeries;
  final bool isWatched;
  final double? startPosition;
  final String? videoAssetId;

  const PlayerPage({
    super.key,
    required this.videoUrl,
    required this.title,
    this.imageUrl,
    this.startPosition,
    this.resumePosition,
    this.isTrailer = false,
    this.episodeData,
    this.isSeries = false,
    this.isWatched = false,
    this.seasons,
    this.videoAssetId,
  });

  static Widget fromRoute(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ??
        const <String, dynamic>{};
    return PlayerPage(
      videoUrl: args['videoUrl'] as String? ?? '',
      title: args['title'] as String? ?? 'Video',
      imageUrl: args['imageUrl'] as String?,
      resumePosition: args['resumePosition'] as Duration?,
      isTrailer: args['isTrailer'] as bool? ?? false,
      episodeData: args['episodeData'],
      isSeries: args['isSeries'] as bool? ?? false,
      isWatched: args['isWatched'] as bool? ?? false,
      seasons: args['seasons'] as List<dynamic>?,
      videoAssetId: args['videoAssetId']?.toString(),
    );
  }

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> with WidgetsBindingObserver {
  BetterPlayerController? _controller;
  bool _loading = true;
  bool _error = false;
  String? _errorMessage;
  bool _isDownloadingOffline = false;
  bool _isTv = false;
  bool _isAndroidTvDevice = false;
  bool _usePlayReadyTvView = false;
  Map<String, String> _playReadyTvParams = const {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    NativeScreenRetainer.retainOn();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializePlayer());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _isTv = AppResponsive.isTVSize(context);
    _isAndroidTvDevice = defaultTargetPlatform == TargetPlatform.android &&
        context.watch<DeviceInfoProvider>().isTV;
  }

  String _platformName() {
    if (kIsWeb) return 'web';
    if (defaultTargetPlatform == TargetPlatform.android) return 'android';
    if (defaultTargetPlatform == TargetPlatform.iOS) return 'ios';
    throw UnsupportedError('Lecture protégée non disponible sur cette plateforme.');
  }

  String _drmSystem(String platform) {
    if (platform == 'tv') return 'playready';
    if (platform == 'ios' || (kIsWeb && isSafariBrowser())) return 'fairplay';
    return 'widevine';
  }

  Future<void> _downloadForOffline() async {
    final assetId = widget.videoAssetId;
    if (assetId == null || assetId.isEmpty || _isDownloadingOffline) return;
    final profile = context.read<ProfileProvider>().currentProfile;
    final profileId = profile?.id;
    if (profileId == null || profileId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez un profil pour télécharger.')),
      );
      return;
    }

    setState(() => _isDownloadingOffline = true);
    try {
      final deviceInfo = context.read<DeviceInfoProvider>();
      if (!deviceInfo.isInitialized) await deviceInfo.init();
      final platform = deviceInfo.isTV
          ? 'tv'
          : defaultTargetPlatform == TargetPlatform.iOS
              ? 'ios'
              : 'android';
      final drmSystem = platform == 'tv'
          ? 'playready'
          : platform == 'ios'
              ? 'fairplay'
              : 'widevine';
      final api = ContentApiService(
        context.read<ProfileProvider>().apiClient.dio,
      );
      await OfflineDownloadService(api).download(
        assetId: assetId,
        title: widget.title,
        posterUrl: widget.imageUrl,
        profileId: profileId,
        platform: platform,
        drmSystem: drmSystem,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Téléchargement hors ligne ajouté à la file.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      final message = error is StateError
          ? error.message.toString()
          : error is UnsupportedError
              ? error.message.toString()
              : 'Impossible de préparer le téléchargement hors ligne.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) setState(() => _isDownloadingOffline = false);
    }
  }

  Map<String, dynamic>? _readPlaybackState() {
    final videoController = _controller?.videoPlayerController;
    if (videoController == null) return null;
    final value = videoController.value;
    return {
      'position_ms': value.position.inMilliseconds,
      'is_playing': value.isPlaying,
      'playback_rate': value.playbackSpeed,
    };
  }

  Future<void> _applyRemotePlayback(Map<String, dynamic> state) async {
    final controller = _controller;
    if (controller == null) return;
    final position = (state['effective_position_ms'] ??
            state['position_ms'] ??
            0) as num;
    await controller.seekTo(Duration(milliseconds: position.toInt()));
    if (state['is_playing'] == true) {
      await controller.play();
    } else {
      await controller.pause();
    }
  }

  Future<void> _openEkeroom() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => EkeroomPage(
          contentId: widget.videoAssetId,
          contentTitle: widget.title,
          readPlaybackState: _readPlaybackState,
          onRemotePlaybackState: _applyRemotePlayback,
        ),
      ),
    );
  }

  Future<void> _initializePlayer() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = false;
        _errorMessage = null;
        _usePlayReadyTvView = false;
        _playReadyTvParams = const {};
      });
    }
    BetterPlayerController? nextController;
    try {
      String sourceUrl;
      DrmConfiguration? drm;
      DataSourceType sourceType = DataSourceType.network;

      if (widget.videoAssetId != null && widget.videoAssetId!.isNotEmpty) {
        final deviceInfo = context.read<DeviceInfoProvider>();
        if (!deviceInfo.isInitialized) await deviceInfo.init();
        _isAndroidTvDevice = defaultTargetPlatform == TargetPlatform.android &&
            deviceInfo.isTV;
        final profileId = context.read<ProfileProvider>().currentProfile?.id;
        if (profileId == null || profileId.isEmpty) {
          throw StateError('Aucun profil actif pour autoriser la lecture.');
        }
        final platform = _isAndroidTvDevice ? 'tv' : _platformName();
        final drmSystem = _drmSystem(platform);
        final playback = await context.read<ContentProvider>().preparePlayback(
          assetId: widget.videoAssetId!,
          platform: platform,
          drmSystem: drmSystem,
          activeProfileId: profileId,
        );
        final drmRequired = playback['drm_required'] == true;
        final drmData = playback['drm'] is Map
            ? Map<String, dynamic>.from(playback['drm'] as Map)
            : <String, dynamic>{};
        if (drmRequired) {
          var licenseUrl =
              (drmData['license_url'] ?? playback['provider_license_url'])
                  ?.toString() ??
              '';
          final token = drmData['entitlement_token']?.toString() ?? '';
          if (licenseUrl.isEmpty || token.isEmpty) {
            throw StateError('La licence DRM est indisponible pour ce contenu.');
          }
          if (drmSystem == 'playready') {
            final manifest = playback['dash_manifest_url']?.toString() ?? '';
            if (manifest.isEmpty || kIsWeb) {
              throw StateError('Le manifeste PlayReady pour Android TV est indisponible.');
            }
            if (!mounted) return;
            setState(() {
              _playReadyTvParams = {
                'manifestUrl': manifest,
                'licenseUrl': licenseUrl,
                'entitlementToken': token,
                'cacheKey': 'eke-asset-${widget.videoAssetId}',
              };
              _usePlayReadyTvView = true;
              _loading = false;
            });
            return;
          }
          if (drmSystem == 'fairplay') {
            final uri = Uri.parse(licenseUrl);
            licenseUrl = uri
                .replace(
                  queryParameters: {
                    ...uri.queryParameters,
                    'AxDrmMessage': token,
                  },
                )
                .toString();
          }
          drm = DrmConfiguration(
            drmType: drmSystem == 'fairplay' ? DrmType.fairplay : DrmType.widevine,
            licenseUrl: licenseUrl,
            certificateUrl: drmData['fairplay_certificate_url']?.toString() ??
                drmData['certificate_url']?.toString(),
            headers: drmSystem == 'widevine'
                ? {'X-AxDRM-Message': token}
                : null,
          );
        }
        sourceUrl = drmSystem == 'fairplay'
            ? playback['hls_master_url']?.toString() ?? ''
            : playback['dash_manifest_url']?.toString() ??
                playback['hls_master_url']?.toString() ??
                '';
        if (sourceUrl.isEmpty) {
          throw StateError('Le manifeste de lecture n’est pas disponible.');
        }
        if (sourceUrl.toLowerCase().contains('.mpd')) {
          sourceType = DataSourceType.network;
        }
      } else {
        // Trailers and legacy unprotected assets keep the existing URL path.
        sourceUrl = widget.videoUrl.trim();
      if (sourceUrl.isEmpty || !sourceUrl.startsWith('http')) {
          throw StateError('URL vidéo vide ou invalide.');
        }
      }

      nextController = BetterPlayerController(
        const PlayerConfiguration(
          autoPlay: true,
          looping: false,
          aspectRatio: 16 / 9,
          fit: BoxFit.contain,
          handleLifecycle: true,
        ),
      );
      await nextController.setupDataSource(
        PlayerDataSource(
          sourceType,
          sourceUrl,
          drmConfiguration: drm,
          cacheConfiguration: !kIsWeb && sourceType == DataSourceType.network
              ? CacheConfiguration(
                  useCache: true,
                  maxCacheSize: 256 * 1024 * 1024,
                  maxCacheFileSize: 64 * 1024 * 1024,
                  preCacheSize: 12 * 1024 * 1024,
                  key: widget.videoAssetId?.isNotEmpty == true
                      ? 'eke-asset-${widget.videoAssetId}'
                      : sourceUrl,
                )
              : null,
          useAsmsSubtitles: true,
        ),
      );
      if (widget.resumePosition != null) {
        await nextController.seekTo(widget.resumePosition!);
      } else if (widget.startPosition != null && widget.startPosition! > 0) {
        await nextController.seekTo(
          Duration(seconds: widget.startPosition!.round()),
        );
      }
      if (!mounted) {
        nextController.dispose();
        return;
      }
      final previous = _controller;
      setState(() {
        _controller = nextController;
        _loading = false;
      });
      previous?.dispose();
    } catch (error) {
      nextController?.dispose();
      if (!mounted) return;
      setState(() {
        _error = true;
        _loading = false;
        _errorMessage = error is StateError
            ? error.message.toString()
            : 'Impossible de charger la vidéo ou sa licence DRM.';
      });
      // Keep diagnostic detail out of the log: it may include signed URLs.
      debugPrint('Playback setup failed (${error.runtimeType}).');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      _controller?.pause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    NativeScreenRetainer.release();
    SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: true,
        actions: [
          if (OfflineDownloadService.isSupported &&
              widget.videoAssetId?.isNotEmpty == true)
            IconButton(
              tooltip: 'Télécharger hors ligne',
              onPressed: _isDownloadingOffline ? null : _downloadForOffline,
              icon: _isDownloadingOffline
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_for_offline_outlined),
            ),
          if (widget.videoAssetId?.isNotEmpty == true)
            IconButton(
              tooltip: 'Ekeroom',
              onPressed: _openEkeroom,
              icon: const Icon(Icons.groups_outlined),
            ),
          IconButton(
            tooltip: 'Téléchargements',
            onPressed: () => Navigator.of(context).pushNamed('/downloads'),
            icon: const Icon(Icons.download_done_outlined),
          ),
        ],
      ),
      body: Center(
        child: _error
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    strings?.videoPlaybackError ?? 'Playback error',
                    style: const TextStyle(color: Colors.white),
                  ),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ElevatedButton(
                    onPressed: _initializePlayer,
                    child: Text(strings?.retry ?? 'Retry'),
                  ),
                ],
              )
            : _loading
                ? const CircularProgressIndicator()
                : _usePlayReadyTvView
                    ? AndroidView(
                        viewType: 'ekeflicks/playready-tv-player',
                        creationParams: _playReadyTvParams,
                        creationParamsCodec: const StandardMessageCodec(),
                      )
                    : _controller == null
                        ? const CircularProgressIndicator()
                        : AspectRatio(
                    aspectRatio: 16 / 9,
                    child: BetterPlayer(controller: _controller!),
                  ),
      ),
    );
  }
}
