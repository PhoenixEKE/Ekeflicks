import 'dart:async';

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
import 'package:url_launcher/url_launcher.dart';
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
  Timer? _adMonitor;
  StreamSubscription<dynamic>? _tvPlayerEvents;
  bool _isPlayingAd = false;
  bool _startingAd = false;
  bool _preRollHandled = false;
  bool _ssaiActive = false;
  String? _ssaiManifestUrl;
  bool _wasPlaying = false;
  bool _checkingAds = false;
  bool _finishingAd = false;
  Map<String, dynamic>? _ssaiInteractiveAd;
  String? _activeProfileId;
  String _activePlatform = 'web';
  String _activeDrmSystem = 'widevine';
  String? _playbackSessionId;
  Map<String, dynamic>? _activeAd;
  Map<String, dynamic>? _pauseAd;
  String _activeAdPlacement = 'preroll';
  BetterPlayerController? _contentControllerDuringAd;
  Duration _resumeAfterAd = Duration.zero;
  final Set<int> _playedMidrolls = <int>{};
  final Set<int> _reportedQuartiles = <int>{};
  final Set<int> _reportedSsaiBreaks = <int>{};
  final Set<int> _completedSsaiBreaks = <int>{};
  List<int> _midrollCuePoints = const [];
  List<Map<String, dynamic>> _ssaiBreaks = const [];
  int _lastPausePositionSeconds = -1;
  int _tvPositionMilliseconds = 0;
  bool _tvIsPlaying = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    NativeScreenRetainer.retainOn();
    _adMonitor = Timer.periodic(
      const Duration(milliseconds: 500),
      (_) => unawaited(_monitorAds()),
    );
    if (defaultTargetPlatform == TargetPlatform.android) {
      _tvPlayerEvents = const EventChannel('ekeflicks/tv-player-events')
          .receiveBroadcastStream()
          .listen(_onTvPlayerEvent, onError: (_) {});
    }
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

  void _onTvPlayerEvent(dynamic event) {
    if (event is! Map) return;
    final wasPlaying = _tvIsPlaying;
    _tvIsPlaying = event['play_when_ready'] == true ||
        (event['play_when_ready'] == null && event['is_playing'] == true);
    _tvPositionMilliseconds = (event['position_ms'] as num? ?? _tvPositionMilliseconds).toInt();
    if (_tvIsPlaying) {
      if (_pauseAd != null && mounted) setState(() => _pauseAd = null);
      _wasPlaying = true;
    } else if (wasPlaying && _usePlayReadyTvView) {
      _wasPlaying = false;
      unawaited(_loadPauseAd(Duration(milliseconds: _tvPositionMilliseconds)));
    }
  }

  ContentApiService _contentApi() => ContentApiService(
        context.read<ProfileProvider>().apiClient.dio,
      );

  Future<Map<String, dynamic>?> _requestAdDecision(
    String placement, {
    int positionSeconds = 0,
  }) async {
    final assetId = widget.videoAssetId;
    final profileId = _activeProfileId;
    if (assetId == null || assetId.isEmpty || profileId == null) return null;
    try {
      _playbackSessionId ??= await _contentApi().newPlaybackSessionId();
      return await _contentApi().requestAdDecision(
        assetId: assetId,
        profileId: profileId,
        placement: placement,
        platform: _activePlatform,
        drmSystem: _activeDrmSystem,
        playbackSessionId: _playbackSessionId!,
        positionSeconds: positionSeconds,
      );
    } catch (error) {
      debugPrint('Ad decision unavailable (${error.runtimeType}).');
      return null;
    }
  }

  void _storeAdSchedule(Map<String, dynamic>? decision) {
    if (decision == null) return;
    final raw = decision['ad_schedule'];
    _midrollCuePoints = raw is List
        ? raw.whereType<num>().map((value) => value.toInt()).where((value) => value > 0).toSet().toList()..sort()
        : const [];
    final breaks = decision['ssai_breaks'];
    _ssaiBreaks = breaks is List
        ? breaks.whereType<Map>().map((value) => Map<String, dynamic>.from(value)).toList()
        : const [];
    _ssaiActive = decision['delivery'] == 'ssai' &&
        (decision['manifest_url']?.toString().startsWith('https://') ?? false);
    _ssaiManifestUrl = _ssaiActive ? decision['manifest_url']?.toString() : null;
    final startAt = widget.resumePosition?.inSeconds ??
        (widget.startPosition?.round() ?? 0);
    _playedMidrolls.addAll(_midrollCuePoints.where((point) => point < startAt));
  }

  Future<Map<String, dynamic>?> _preparePreRoll() async {
    if (_preRollHandled || widget.videoAssetId?.isNotEmpty != true) return null;
    _preRollHandled = true;
    final decision = await _requestAdDecision('preroll');
    _storeAdSchedule(decision);
    if (_ssaiActive) {
      for (final slot in _ssaiBreaks.where((item) => item['placement'] == 'preroll')) {
        final campaignId = slot['campaign_id']?.toString();
        if (campaignId != null) {
          await _trackCampaignEvent(campaignId, 'impression', 'preroll');
          await _trackCampaignEvent(campaignId, 'start', 'preroll');
        }
      }
    }
    return decision;
  }

  Future<void> _trackCampaignEvent(
    String campaignId,
    String eventType,
    String placement, {
    int positionSeconds = 0,
  }) async {
    final assetId = widget.videoAssetId;
    final profileId = _activeProfileId;
    final sessionId = _playbackSessionId;
    if (assetId == null || profileId == null || sessionId == null) return;
    try {
      await _contentApi().reportAdEvent(
        campaignId: campaignId,
        assetId: assetId,
        profileId: profileId,
        placement: placement,
        platform: _activePlatform,
        playbackSessionId: sessionId,
        eventType: eventType,
        positionSeconds: positionSeconds,
      );
    } catch (_) {
      // Playback continues if measurement is temporarily unavailable.
    }
  }

  Future<void> _loadPauseAd(Duration position) async {
    if (_pauseAd != null || _startingAd || _activeAd != null) return;
    final positionSeconds = position.inSeconds;
    if (positionSeconds == _lastPausePositionSeconds) return;
    _lastPausePositionSeconds = positionSeconds;
    final decision = await _requestAdDecision(
      'pause',
      positionSeconds: positionSeconds,
    );
    final ad = decision?['ad'];
    if (!mounted || ad is! Map) return;
    final stillPaused = _usePlayReadyTvView
        ? !_tvIsPlaying
        : !(_controller?.playerValue?.isPlaying ?? false);
    if (!stillPaused) return;
    final creative = Map<String, dynamic>.from(ad);
    setState(() => _pauseAd = creative);
    final campaignId = creative['campaign_id']?.toString();
    if (campaignId != null) {
      await _trackCampaignEvent(
        campaignId,
        'impression',
        'pause',
        positionSeconds: positionSeconds,
      );
    }
  }

  Future<bool> _startClientAd(
    Map<String, dynamic> creative,
    String placement, {
    Duration contentPosition = Duration.zero,
  }) async {
    final mediaUrl = creative['media_url']?.toString() ?? '';
    final uri = Uri.tryParse(mediaUrl);
    if (!mounted || uri == null || uri.scheme != 'https' || _startingAd || _activeAd != null) {
      return false;
    }
    final currentContent = placement == 'midroll' ? _controller : null;
    if (currentContent != null) {
      _resumeAfterAd = contentPosition;
      _contentControllerDuringAd = currentContent;
      await currentContent.pause();
      if (!mounted) return false;
    }
    setState(() {
      _startingAd = true;
      _pauseAd = null;
      if (placement == 'preroll') _loading = true;
    });
    final adController = BetterPlayerController(
      const PlayerConfiguration(
        autoPlay: true,
        looping: false,
        aspectRatio: 16 / 9,
        fit: BoxFit.contain,
        handleLifecycle: true,
      ),
    );
    try {
      await adController.setupDataSource(
        PlayerDataSource(
          DataSourceType.network,
          mediaUrl,
          cacheConfiguration: null,
        ),
      );
      if (!mounted) {
        adController.dispose();
        return false;
      }
      final previous = placement == 'midroll' ? _controller : null;
      setState(() {
        _controller = adController;
        _activeAd = creative;
        _activeAdPlacement = placement;
        _isPlayingAd = true;
        _startingAd = false;
        _reportedQuartiles.clear();
        _loading = false;
      });
      if (placement == 'midroll') _contentControllerDuringAd = previous;
      final campaignId = creative['campaign_id']?.toString();
      if (campaignId != null) {
        await _trackCampaignEvent(
          campaignId,
          'impression',
          placement,
          positionSeconds: contentPosition.inSeconds,
        );
        await _trackCampaignEvent(
          campaignId,
          'start',
          placement,
          positionSeconds: contentPosition.inSeconds,
        );
      }
      return true;
    } catch (_) {
      adController.dispose();
      if (!mounted) return false;
      setState(() {
        _startingAd = false;
        _isPlayingAd = false;
        _activeAd = null;
        if (placement == 'preroll') _loading = true;
      });
      final campaignId = creative['campaign_id']?.toString();
      if (campaignId != null) {
        await _trackCampaignEvent(campaignId, 'error', placement);
      }
      if (placement == 'preroll') {
        _preRollHandled = true;
      } else {
        final content = _contentControllerDuringAd;
        _contentControllerDuringAd = null;
        if (content != null) {
          setState(() => _controller = content);
          await content.seekTo(_resumeAfterAd);
          await content.play();
        }
      }
      return false;
    }
  }

  Future<void> _finishClientAd({bool skipped = false}) async {
    final creative = _activeAd;
    final placement = _activeAdPlacement;
    final adController = _controller;
    if (creative == null || adController == null || !_isPlayingAd || _finishingAd) return;
    _finishingAd = true;
    await adController.pause();
    final campaignId = creative['campaign_id']?.toString();
    if (campaignId != null) {
      await _trackCampaignEvent(
        campaignId,
        skipped ? 'skip' : 'complete',
        placement,
        positionSeconds: adController.playerValue?.position.inSeconds ?? 0,
      );
    }
    if (!mounted) return;
    _isPlayingAd = false;
    if (placement == 'preroll') {
      _preRollHandled = true;
      setState(() {
        _controller = null;
        _activeAd = null;
        _isPlayingAd = false;
        _finishingAd = false;
        _loading = true;
      });
      adController.dispose();
      await _initializePlayer();
      return;
    }
    final content = _contentControllerDuringAd;
    _contentControllerDuringAd = null;
    setState(() {
      _controller = content;
      _activeAd = null;
      _isPlayingAd = false;
      _finishingAd = false;
      _pauseAd = null;
    });
    adController.dispose();
    if (content != null) {
      await content.seekTo(_resumeAfterAd);
      await content.play();
    }
  }

  Future<void> _pollAdProgress() async {
    final creative = _activeAd;
    final controller = _controller;
    if (!_isPlayingAd || creative == null || controller == null) return;
    final value = controller.playerValue;
    final position = value?.position ?? Duration.zero;
    final duration = value?.duration ?? Duration.zero;
    if (duration.inMilliseconds > 0) {
      final progress = position.inMilliseconds / duration.inMilliseconds;
      for (final threshold in const [25, 50, 75]) {
        if (progress >= threshold / 100 && _reportedQuartiles.add(threshold)) {
          final campaignId = creative['campaign_id']?.toString();
          if (campaignId != null) {
            final event = switch (threshold) {
              25 => 'first_quartile',
              50 => 'midpoint',
              _ => 'third_quartile',
            };
            await _trackCampaignEvent(
              campaignId,
              event,
              _activeAdPlacement,
              positionSeconds: position.inSeconds,
            );
          }
        }
      }
      if (position.inMilliseconds >= duration.inMilliseconds - 300) {
        await _finishClientAd();
      }
    }
  }

  Future<void> _monitorAds() async {
    if (_checkingAds || !mounted || _loading) return;
    _checkingAds = true;
    try {
      if (_isPlayingAd) {
        await _pollAdProgress();
        return;
      }
      final controller = _controller;
      final position = _usePlayReadyTvView
          ? Duration(milliseconds: _tvPositionMilliseconds)
          : controller?.playerValue?.position ?? Duration.zero;
      final isBuffering = !_usePlayReadyTvView &&
          (controller?.playerValue?.isBuffering ?? false);
      final isPlaying = _usePlayReadyTvView
          ? _tvIsPlaying
          : controller?.playerValue?.isPlaying ?? false;
      if (!isPlaying && isBuffering) return;
      if (!isPlaying) {
        if (_wasPlaying && _pauseAd == null && _activeAd == null) {
          _wasPlaying = false;
          await _loadPauseAd(position);
        }
        return;
      }
      _wasPlaying = true;
      if (_pauseAd != null) setState(() => _pauseAd = null);

      if (_ssaiActive) {
        Map<String, dynamic>? activeInteractive;
        for (var index = 0; index < _ssaiBreaks.length; index++) {
          final slot = _ssaiBreaks[index];
          final cue = (slot['cue_point_seconds'] as num?)?.toInt();
          final duration = (slot['duration_seconds'] as num?)?.toInt() ?? 0;
          final placement = slot['placement']?.toString() ?? '';
          final campaignId = slot['campaign_id']?.toString();
          final start = placement == 'preroll' ? 0 : cue;
          final end = start == null ? null : start + (duration > 0 ? duration : 20);
          final inBreak = start != null &&
              position.inSeconds >= start &&
              (end == null || position.inSeconds < end);
          if (placement == 'midroll' &&
              cue != null &&
              campaignId != null &&
              position.inSeconds >= cue &&
              _reportedSsaiBreaks.add(index)) {
            await _trackCampaignEvent(
              campaignId,
              'impression',
              'midroll',
              positionSeconds: position.inSeconds,
            );
            await _trackCampaignEvent(
              campaignId,
              'start',
              'midroll',
              positionSeconds: position.inSeconds,
            );
            if (!mounted) return;
          }
          if (duration > 0 &&
              campaignId != null &&
              position.inSeconds >= (end ?? 0) &&
              (placement == 'preroll' || _reportedSsaiBreaks.contains(index)) &&
              _completedSsaiBreaks.add(index)) {
            await _trackCampaignEvent(
              campaignId,
              'complete',
              placement,
              positionSeconds: position.inSeconds,
            );
            if (!mounted) return;
          }
          if (inBreak && (slot['cta_url']?.toString() ?? '').startsWith('https://')) {
            activeInteractive = {
              'campaign_id': campaignId,
              'name': slot['name'],
              'advertiser': slot['advertiser'],
              'cta_label': slot['cta_label'],
              'cta_url': slot['cta_url'],
            };
          }
        }
        final previousInteractive = _ssaiInteractiveAd;
        final unchanged = previousInteractive == null && activeInteractive == null ||
            previousInteractive != null &&
                activeInteractive != null &&
                previousInteractive['campaign_id'] == activeInteractive['campaign_id'] &&
                previousInteractive['cta_url'] == activeInteractive['cta_url'] &&
                previousInteractive['cta_label'] == activeInteractive['cta_label'] &&
                previousInteractive['name'] == activeInteractive['name'];
        if (!unchanged) {
          setState(() => _ssaiInteractiveAd = activeInteractive);
        }
        final serverCuePoints = _ssaiBreaks
            .where((slot) => slot['placement'] == 'midroll')
            .map((slot) => (slot['cue_point_seconds'] as num?)?.toInt())
            .whereType<int>()
            .toSet();
        for (final cue in _midrollCuePoints) {
          if (serverCuePoints.contains(cue) ||
              position.inSeconds < cue ||
              !_playedMidrolls.add(cue)) {
            continue;
          }
          final decision = await _requestAdDecision(
            'midroll',
            positionSeconds: position.inSeconds,
          );
          final ad = decision?['ad'];
          if (ad is Map && decision?['delivery'] == 'client_side') {
            await _startClientAd(
              Map<String, dynamic>.from(ad),
              'midroll',
              contentPosition: controller?.playerValue?.position ?? position,
            );
          }
          break;
        }
        return;
      }

      for (final cue in _midrollCuePoints) {
        if (position.inSeconds >= cue && _playedMidrolls.add(cue)) {
          final decision = await _requestAdDecision(
            'midroll',
            positionSeconds: position.inSeconds,
          );
          final ad = decision?['ad'];
          if (ad is Map && decision?['delivery'] == 'client_side') {
            await _startClientAd(
              Map<String, dynamic>.from(ad),
              'midroll',
              contentPosition: controller?.playerValue?.position ?? position,
            );
          }
          break;
        }
      }
    } finally {
      _checkingAds = false;
    }
  }

  Future<void> _openAdCta(Map<String, dynamic> creative, String placement) async {
    final url = creative['cta_url']?.toString() ?? '';
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https') return;
    final campaignId = creative['campaign_id']?.toString();
    final position = _isPlayingAd
        ? _controller?.playerValue?.position.inSeconds ?? 0
        : _usePlayReadyTvView
            ? Duration(milliseconds: _tvPositionMilliseconds).inSeconds
            : _controller?.playerValue?.position.inSeconds ?? 0;
    if (campaignId != null) {
      await _trackCampaignEvent(
        campaignId,
        'click',
        placement,
        positionSeconds: position,
      );
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
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
    final value = (_contentControllerDuringAd ?? _controller)?.playerValue;
    if (value == null) return null;
    return {
      'position_ms': value.position.inMilliseconds,
      'is_playing': value.isPlaying,
      'playback_rate': 1.0,
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
        _activeProfileId = profileId;
        _activePlatform = platform;
        _activeDrmSystem = drmSystem;
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
            var manifest = playback['dash_manifest_url']?.toString() ?? '';
            if (!_preRollHandled) {
              final decision = await _preparePreRoll();
              if (_ssaiActive) {
                manifest = decision?['manifest_url']?.toString() ?? manifest;
              }
            } else if (_ssaiActive && _ssaiManifestUrl != null) {
              manifest = _ssaiManifestUrl!;
            }
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
        if (!_preRollHandled) {
          final decision = await _preparePreRoll();
          if (_ssaiActive) {
            sourceUrl = decision?['manifest_url']?.toString() ?? sourceUrl;
          }
          if (decision?['ad'] is Map &&
              (decision?['delivery'] == 'client_side' ||
                  (decision?['delivery'] == 'ssai' &&
                      (decision?['ad'] as Map)['delivery_mode'] == 'client_side'))) {
            final started = await _startClientAd(
              Map<String, dynamic>.from(decision!['ad'] as Map),
              'preroll',
            );
            if (started) return;
          }
        } else if (_ssaiActive && _ssaiManifestUrl != null) {
          sourceUrl = _ssaiManifestUrl!;
        }
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
    _adMonitor?.cancel();
    _tvPlayerEvents?.cancel();
    _controller?.dispose();
    if (_contentControllerDuringAd != _controller) {
      _contentControllerDuringAd?.dispose();
    }
    NativeScreenRetainer.release();
    SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Widget _buildAdControls(Map<String, dynamic> ad, String placement) {
    final skipAfter = (ad['skip_after_seconds'] as num?)?.toInt();
    final position = _controller?.playerValue?.position.inSeconds ?? 0;
    final canSkip = skipAfter != null && position >= skipAfter;
    return Material(
      color: Colors.black87,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Text('Publicité', style: TextStyle(color: Colors.white)),
          if ((ad['cta_url']?.toString() ?? '').isNotEmpty) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => _openAdCta(ad, placement),
              child: Text(ad['cta_label']?.toString().trim().isNotEmpty == true
                  ? ad['cta_label'].toString()
                  : 'En savoir plus'),
            ),
          ],
          if (canSkip) ...[
            const SizedBox(width: 4),
            OutlinedButton(
              onPressed: () => _finishClientAd(skipped: true),
              child: const Text('Passer'),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _buildInteractiveAd(Map<String, dynamic> ad) => Material(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(children: [
            const Icon(Icons.ads_click, color: Colors.white70),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Publicité interactive', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  Text(ad['name']?.toString() ?? 'Annonce', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            FilledButton(
              autofocus: _isTv,
              onPressed: () => _openAdCta(ad, 'midroll'),
              child: Text(ad['cta_label']?.toString().trim().isNotEmpty == true
                  ? ad['cta_label'].toString()
                  : 'En savoir plus'),
            ),
          ]),
        ),
      );

  Widget _buildPauseAd(Map<String, dynamic> ad) {
    final imageUrl = ad['image_url']?.toString() ?? '';
    final ctaUrl = ad['cta_url']?.toString() ?? '';
    return Material(
      color: Colors.black87,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          if (imageUrl.startsWith('https://')) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                width: 104,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(
                  width: 104,
                  height: 60,
                  child: Icon(Icons.campaign_outlined, color: Colors.white70),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Publicité sur pause', style: TextStyle(color: Colors.white70, fontSize: 12)),
                Text(ad['name']?.toString() ?? 'Annonce', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                if ((ad['advertiser']?.toString() ?? '').isNotEmpty)
                  Text(ad['advertiser'].toString(), style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          if (ctaUrl.isNotEmpty)
            FilledButton(
              autofocus: _isTv,
              onPressed: () => _openAdCta(ad, 'pause'),
              child: Text(ad['cta_label']?.toString().trim().isNotEmpty == true
                  ? ad['cta_label'].toString()
                  : 'En savoir plus'),
            ),
          IconButton(
            tooltip: 'Fermer la publicité',
            onPressed: () => setState(() => _pauseAd = null),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ]),
      ),
    );
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
      body: Stack(
        alignment: Alignment.center,
        children: [
          Center(
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
          if (_isPlayingAd && _activeAd != null)
            Positioned(
              top: 12,
              right: 12,
              child: _buildAdControls(_activeAd!, _activeAdPlacement),
            ),
          if (_pauseAd != null)
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: _buildPauseAd(_pauseAd!),
            ),
          if (_ssaiInteractiveAd != null)
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: _buildInteractiveAd(_ssaiInteractiveAd!),
            ),
        ],
      ),
    );
  }
}
