import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:app_ekeflicks/services/native_screen_retainer.dart';
import 'package:app_ekeflicks/l10n/app_localizations.dart';
import 'package:app_ekeflicks/core/app_responsive.dart';
import 'package:app_ekeflicks/providers/locale_provider.dart';

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
  });

  static Route<void> route(RouteSettings settings) {
    final args = settings.arguments as Map<String, dynamic>? ?? {};
    
    return MaterialPageRoute(
      builder: (context) => PlayerPage(
        videoUrl: args['videoUrl'] as String? ?? '',
        title: args['title'] as String? ?? 'Video',
        imageUrl: args['imageUrl'] as String?,
        resumePosition: args['resumePosition'] as Duration?,
        isTrailer: args['isTrailer'] as bool? ?? false,
        episodeData: args['episodeData'],
        isSeries: args['isSeries'] as bool? ?? false,
        isWatched: args['isWatched'] as bool? ?? false,
        seasons: args['seasons'] as List<dynamic>?,
      ),
    );
  }

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> with WidgetsBindingObserver {
  late VideoPlayerController _controller;
  bool _showControls = true;
  bool _isMuted = false;
  bool _subtitlesEnabled = false;
  bool _isFullscreen = true;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _isBuffering = false;
  bool _isMobile = false;
  bool _isTV = false;

  final Map<Duration, String> _dummySubtitles = {
    Duration(seconds: 0): "Bienvenue dans la vidéo !",
    Duration(seconds: 5): "Voici un sous-titre exemple.",
    Duration(seconds: 10): "Profitez du visionnage.",
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    NativeScreenRetainer.retainOn();
    _initializePlayer();
    _setLandscape();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateDeviceType();
  }

  void _updateDeviceType() {
    final isMobile = AppResponsive.isMobile(context);
    final isTV = AppResponsive.isTVSize(context);
    
    if (isMobile != _isMobile || isTV != _isTV) {
      setState(() {
        _isMobile = isMobile;
        _isTV = isTV;
      });
    }
  }

  Future<void> _initializePlayer() async {
    try {
      if (widget.videoUrl.isEmpty) {
        throw Exception('URL vidéo vide');
      }

      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
        ..addListener(_videoListener)
        ..setLooping(false);

      _controller.addListener(() {
        if (!mounted) return;
        setState(() {
          _isBuffering = _controller.value.isBuffering;
        });
      });

      await _controller.initialize();
      
      if (widget.resumePosition != null) {
        await _controller.seekTo(widget.resumePosition!);
      }
      
      await _controller.play();
      
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
      });
      debugPrint('Erreur initialisation lecteur: $e');
      _controller.dispose();
    }
  }

  void _videoListener() {
    if (!mounted) return;
    
    if (_controller.value.hasError) {
      setState(() {
        _hasError = true;
      });
      return;
    }

    if (_controller.value.position >= _controller.value.duration) {
      _controller.pause();
    }
    
    setState(() {});
  }

  void _setLandscape() {
    if (!_isTV) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }

  void _setPortrait() {
    if (!_isTV) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_videoListener);
    _controller.dispose();
    NativeScreenRetainer.release();
    _setPortrait();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _controller.pause();
    } else if (state == AppLifecycleState.resumed) {
      if (!_controller.value.isPlaying && !_controller.value.isBuffering) {
        _controller.play();
      }
    }
  }

  void _toggleFullscreen() {
    if (_isTV) return; // Désactive le plein écran pour TV
    
    setState(() {
      _isFullscreen = !_isFullscreen;
      if (_isFullscreen) {
        _setLandscape();
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      } else {
        _setPortrait();
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
    });
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _controller.setVolume(_isMuted ? 0 : 1);
    });
  }

  void _toggleSubtitles() {
    setState(() {
      _subtitlesEnabled = !_subtitlesEnabled;
    });
  }

  void _retryInitialization() {
    setState(() {
      _hasError = false;
      _isInitialized = false;
    });
    _initializePlayer();
  }

  String? _getCurrentSubtitle(Duration position) {
    String? current;
    for (var entry in _dummySubtitles.entries) {
      if (position >= entry.key) {
        current = entry.value;
      }
    }
    return current;
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    String? tooltip,
    double? size,
  }) {
    return IconButton(
      icon: Icon(icon, size: size),
      color: Colors.white,
      hoverColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
      splashRadius: 20,
      tooltip: tooltip,
      onPressed: onPressed,
    );
  }

  Widget _buildControls(BuildContext context) {
    if (!_isInitialized || _hasError) return const SizedBox();

    final duration = _controller.value.duration;
    final position = _controller.value.position;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final loc = AppLocalizations.of(context)!;
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        opacity: _showControls ? 1 : 0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: _isTV ? 24 : 12,
            vertical: _isTV ? 16 : 8,
          ),
          color: Colors.black54,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              VideoProgressIndicator(
                _controller,
                allowScrubbing: true,
                colors: VideoProgressColors(
                  playedColor: primaryColor,
                  bufferedColor: Colors.white54,
                  backgroundColor: Colors.white30,
                ),
              ),
              SizedBox(height: _isTV ? 16 : 8),
              Row(
                children: [
                  _buildIconButton(
                    icon: _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                    onPressed: () {
                      _controller.value.isPlaying 
                          ? _controller.pause() 
                          : _controller.play();
                    },
                    tooltip: _controller.value.isPlaying ? loc.pause : loc.play,
                    size: _isTV ? 32 : null,
                  ),
                  _buildIconButton(
                    icon: _isMuted ? Icons.volume_off : Icons.volume_up,
                    onPressed: _toggleMute,
                    tooltip: _isMuted ? loc.unmute : loc.mute,
                    size: _isTV ? 32 : null,
                  ),
                  _buildIconButton(
                    icon: _subtitlesEnabled ? Icons.subtitles : Icons.subtitles_off,
                    onPressed: _toggleSubtitles,
                    tooltip: _subtitlesEnabled ? loc.subtitlesOn : loc.subtitlesOff,
                    size: _isTV ? 32 : null,
                  ),
                  Text(
                    '${_formatDuration(position)} / ${_formatDuration(duration)}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: _isTV ? 20 : 14,
                    ),
                  ),
                  const Spacer(),
                  if (!_isFullscreen && !_isTV)
                    _buildIconButton(
                      icon: Icons.fullscreen,
                      onPressed: _toggleFullscreen,
                      tooltip: loc.fullscreen,
                      size: _isTV ? 32 : null,
                    ),
                  // Bouton de changement de langue
                  if (_showControls && _isTV)
                    _buildIconButton(
                      icon: Icons.language,
                      onPressed: () => localeProvider.toggleLocale(),
                      tooltip: loc.changeLanguage,
                      size: _isTV ? 32 : null,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    
    return hours > 0 
        ? '$hours:$minutes:$seconds' 
        : '$minutes:$seconds';
  }

  Widget _buildErrorWidget(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline, 
            color: Colors.red, 
            size: _isTV ? 80 : 50,
          ),
          SizedBox(height: _isTV ? 32 : 16),
          Text(
            loc.videoPlaybackError,
            style: TextStyle(
              color: Colors.white, 
              fontSize: _isTV ? 28 : 18,
            ),
          ),
          SizedBox(height: _isTV ? 32 : 16),
          ElevatedButton(
            onPressed: _retryInitialization,
            style: ElevatedButton.styleFrom(
              padding: _isTV 
                  ? const EdgeInsets.symmetric(horizontal: 32, vertical: 16)
                  : null,
            ),
            child: Text(
              loc.retry,
              style: _isTV 
                  ? const TextStyle(fontSize: 20) 
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return AspectRatio(
      aspectRatio: _controller.value.aspectRatio,
      child: Stack(
        fit: StackFit.expand,
        children: [
          VideoPlayer(_controller),
          if (_subtitlesEnabled)
            Positioned(
              bottom: _isTV ? 120 : 80,
              left: 20,
              right: 20,
              child: Container(
                padding: EdgeInsets.symmetric(
                  vertical: _isTV ? 12 : 8,
                  horizontal: _isTV ? 24 : 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _getCurrentSubtitle(_controller.value.position) ?? '',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: _isTV ? 24 : 16,
                    fontWeight: FontWeight.bold,
                    shadows: const [
                      Shadow(
                        blurRadius: 4,
                        color: Colors.black,
                        offset: Offset(1, 1),
                      )
                    ],
                  ),
                ),
              ),
            ),
          if (_isBuffering)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }

  PreferredSizeWidget? _buildAppBar() {
    final loc = AppLocalizations.of(context)!;
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    
    return AppBar(
      title: Text(
        widget.title,
        style: _isTV ? const TextStyle(fontSize: 28) : null,
      ),
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      leading: _isTV
          ? _buildIconButton(
              icon: Icons.arrow_back,
              onPressed: () => Navigator.pop(context),
              size: 32,
            )
          : IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
      actions: [
        if (!_isMobile || !_isFullscreen) ...[
          _buildIconButton(
            icon: _isMuted ? Icons.volume_off : Icons.volume_up,
            onPressed: _toggleMute,
            tooltip: _isMuted ? loc.unmute : loc.mute,
            size: _isTV ? 32 : null,
          ),
          _buildIconButton(
            icon: _subtitlesEnabled ? Icons.subtitles : Icons.subtitles_off,
            onPressed: _toggleSubtitles,
            tooltip: _subtitlesEnabled ? loc.subtitlesOn : loc.subtitlesOff,
            size: _isTV ? 32 : null,
          ),
          // Bouton de changement de langue
          _buildIconButton(
            icon: Icons.language,
            onPressed: () => localeProvider.toggleLocale(),
            tooltip: loc.changeLanguage,
            size: _isTV ? 32 : null,
          ),
        ],
        if (!_isTV && (!_isMobile || !_isFullscreen))
          _buildIconButton(
            icon: _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
            onPressed: _toggleFullscreen,
            tooltip: _isFullscreen ? loc.exitFullscreen : loc.fullscreen,
            size: _isTV ? 32 : null,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _isFullscreen || _isTV ? _buildAppBar() : null,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() {
            _showControls = !_showControls;
          });
        },
        child: Stack(
          children: [
            Center(
              child: _hasError
                  ? _buildErrorWidget(context)
                  : (_isInitialized ? _buildVideoPlayer() : const CircularProgressIndicator()),
            ),
            if (_showControls) _buildControls(context),
          ],
        ),
      ),
    );
  }
}