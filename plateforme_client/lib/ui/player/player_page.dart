import 'package:app_ekeflicks/core/app_responsive.dart';
import 'package:app_ekeflicks/l10n/app_localizations.dart';
import 'package:app_ekeflicks/providers/profile_provider.dart';
import 'package:app_ekeflicks/providers/content_provider.dart';
import 'package:app_ekeflicks/services/native_screen_retainer.dart';
import 'package:app_ekeflicks/utils/browser_info.dart';
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
  bool _isTv = false;

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
  }

  String _platformName() {
    if (kIsWeb) return 'web';
    if (defaultTargetPlatform == TargetPlatform.android) return 'android';
    if (defaultTargetPlatform == TargetPlatform.iOS) return 'ios';
    throw UnsupportedError('Lecture protégée non disponible sur cette plateforme.');
  }

  String _drmSystem(String platform) {
    if (platform == 'ios' || (kIsWeb && isSafariBrowser())) return 'fairplay';
    return 'widevine';
  }

  Future<void> _initializePlayer() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = false;
        _errorMessage = null;
      });
    }
    BetterPlayerController? nextController;
    try {
      String sourceUrl;
      DrmConfiguration? drm;
      DataSourceType sourceType = DataSourceType.network;

      if (widget.videoAssetId != null && widget.videoAssetId!.isNotEmpty) {
        final profileId = context.read<ProfileProvider>().currentProfile?.id;
        if (profileId == null || profileId.isEmpty) {
          throw StateError('Aucun profil actif pour autoriser la lecture.');
        }
        final platform =
            _isTv && defaultTargetPlatform == TargetPlatform.android
                ? 'tv'
                : _platformName();
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
            : _loading || _controller == null
                ? const CircularProgressIndicator()
                : AspectRatio(
                    aspectRatio: 16 / 9,
                    child: BetterPlayer(controller: _controller!),
                  ),
      ),
    );
  }
}
