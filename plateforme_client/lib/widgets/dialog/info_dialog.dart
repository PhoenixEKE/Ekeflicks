import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:app_ekeflicks/ui/player/player_page.dart';
import 'package:app_ekeflicks/l10n/app_localizations.dart';
import 'package:app_ekeflicks/models/content_model.dart';
import 'package:app_ekeflicks/providers/content_provider.dart';
import 'package:app_ekeflicks/providers/user_provider.dart';

class InfoDialog extends StatefulWidget {
  final Content content;
  final List<Content> similarContent;

  const InfoDialog({
    super.key,
    required this.content,
    required this.similarContent,
  });

  @override
  State<InfoDialog> createState() => _InfoDialogState();
}

class _InfoDialogState extends State<InfoDialog> {
  VideoPlayerController? _trailerController;
  late Content _content;
  bool _isLoadingDetail = true;
  bool _isPlayingTrailer = false;
  bool _isExpanded = false;
  bool _showFullCast = false;
  final _similarContentController = ScrollController();
  final _castController = ScrollController();

  @override
  void initState() {
    super.initState();
    _content = widget.content;
    _loadContentDetail();
  }

  Future<void> _loadContentDetail() async {
    try {
      final detail = await context.read<ContentProvider>().loadDetail(_content.id);
      if (!mounted) return;
      setState(() => _content = detail);
    } catch (error) {
      debugPrint('Chargement du détail du contenu impossible: $error');
    } finally {
      if (mounted) {
        setState(() => _isLoadingDetail = false);
        await _initializeTrailer(_content.trailerUrl);
      }
    }
  }

  Future<void> _initializeTrailer(String source) async {
    if (source.trim().isEmpty || _trailerController != null) return;
    final controller = VideoPlayerController.networkUrl(Uri.parse(source));
    _trailerController = controller;
    controller.addListener(_onTrailerChanged);
    try {
      await controller.initialize();
      if (mounted) setState(() {});
    } catch (error) {
      debugPrint('Initialisation de la bande-annonce impossible: $error');
      if (identical(_trailerController, controller)) {
        _trailerController = null;
        controller.removeListener(_onTrailerChanged);
        await controller.dispose();
      }
    }
  }

  void _onTrailerChanged() {
    if (!mounted || _trailerController == null) return;
    final playing = _trailerController!.value.isPlaying;
    setState(() => _isPlayingTrailer = playing);
  }

  @override
  void dispose() {
    _trailerController?.removeListener(_onTrailerChanged);
    _trailerController?.dispose();
    _similarContentController.dispose();
    _castController.dispose();
    super.dispose();
  }

  void _toggleTrailerPlayback() {
    final controller = _trailerController;
    if (controller == null || !controller.value.isInitialized) return;
    if (controller.value.isPlaying) {
      controller.pause();
    } else {
      controller.play();
    }
    setState(() {});
  }

  void _playContent(BuildContext context) {
    final isLoggedIn = context.read<UserProvider>().isLoggedIn;
    String videoUrl;
    Episode? episode;

    if (!isLoggedIn) {
      videoUrl = _content.trailerUrl;
      if (videoUrl.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bande-annonce indisponible pour ce contenu.')),
        );
        return;
      }
    } else if (_content.isSeries) {
      final seasons = List<Season>.of(_content.seasonList)
        ..sort((a, b) => a.number.compareTo(b.number));
      for (final season in seasons) {
        final episodes = List<Episode>.of(season.episodes)
          ..sort((a, b) => a.number.compareTo(b.number));
        if (episodes.isNotEmpty) {
          episode = episodes.first;
          break;
        }
      }
      if (episode == null || episode.videoUrl.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Le premier épisode n’est pas encore disponible.')),
        );
        return;
      }
      videoUrl = episode.videoUrl;
    } else {
      videoUrl = _content.videoUrl;
      if (videoUrl.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vidéo indisponible pour ce contenu.')),
        );
        return;
      }
    }

    final navigator = Navigator.of(context);
    navigator.pop();
    navigator.push(
      MaterialPageRoute(
        builder: (_) => PlayerPage(
          videoUrl: videoUrl,
          title: episode == null ? _content.title : '${_content.title} • ${episode.title}',
          imageUrl: episode?.imageUrl.isNotEmpty == true ? episode!.imageUrl : _content.posterUrl,
          contentId: _content.id,
          isTrailer: !isLoggedIn,
          episodeData: episode,
          isSeries: _content.isSeries,
          seasons: _content.seasonList,
        ),
      ),
    );
  }

  void _playEpisode(Episode episode) {
    if (!context.read<UserProvider>().isLoggedIn) {
      _playContent(context);
      return;
    }
    if (episode.videoUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vidéo indisponible pour cet épisode.')),
      );
      return;
    }
    final navigator = Navigator.of(context);
    navigator.pop();
    navigator.push(
      MaterialPageRoute(
        builder: (_) => PlayerPage(
          videoUrl: episode.videoUrl,
          title: '${_content.title} • ${episode.title}',
          imageUrl: episode.imageUrl.isNotEmpty ? episode.imageUrl : _content.posterUrl,
          contentId: _content.id,
          episodeData: episode,
          isSeries: true,
          seasons: _content.seasonList,
        ),
      ),
    );
  }

  Widget _buildMetadataItem(String text, IconData icon, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHdBadge(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(
          color:
              theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7) ??
              Colors.grey,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'HD',
        style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildRatingSection(ThemeData theme) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            5,
            (index) => Icon(
              index < (_content.rating?.round() ?? 0)
                  ? Icons.star
                  : Icons.star_border,
              color: theme.colorScheme.primary,
              size: 20,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${_content.rating?.toStringAsFixed(1) ?? '0.0'}/5',
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String label, ThemeData theme) {
    return Tooltip(
      message: label,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        onPressed:
            () => ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Action: $label'))),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 4),
            Text(label),
          ],
        ),
      ),
    );
  }

  Widget _buildSimilarContentCard(
    Content content,
    double width,
    ThemeData theme,
  ) {
    return SizedBox(
      width: width,
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: content.posterUrl,
              height: width * 1.5,
              width: width,
              fit: BoxFit.cover,
              placeholder:
                  (_, _) => Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                  ),
              errorWidget:
                  (_, _, _) => Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const Icon(Icons.broken_image),
                  ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content.title,
            style: theme.textTheme.bodySmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCastMember(
    String name,
    String role,
    String? imageUrl,
    ThemeData theme,
  ) {
    return SizedBox(
      width: 100,
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage:
                imageUrl != null ? CachedNetworkImageProvider(imageUrl) : null,
            child: imageUrl == null ? const Icon(Icons.person, size: 40) : null,
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: theme.textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            role,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionSection(ThemeData theme) {
    final loc = AppLocalizations.of(context)!;

    final castList =
        _content.cast?.where((name) => name.isNotEmpty).toList() ?? [];
    final fullCast = [
      if (_content.director?.isNotEmpty ?? false)
        {'name': _content.director!, 'role': 'Director', 'image': null},
      ...List.generate(
        castList.length,
        (index) => {
          'name': castList[index],
          'role': 'Actor ${index + 1}',
          'image': 'https://picsum.photos/200/200?random=$index',
        },
      ),
    ];

    if (fullCast.isEmpty) return const SizedBox();

    final visibleCast = _showFullCast ? fullCast : fullCast.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              loc.distribution,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            if (fullCast.length > 5)
              TextButton(
                onPressed: () => setState(() => _showFullCast = !_showFullCast),
                child: Text(_showFullCast ? (loc.seeLess) : (loc.seeMore)),
              ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          controller: _castController,
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              const SizedBox(width: 8),
              ...visibleCast.map(
                (person) => Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: _buildCastMember(
                    person['name']!,
                    person['role']!,
                    person['image'],
                    theme,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSeasonsSection(ThemeData theme) {
    if (!_content.isSeries || _content.seasonList.isEmpty) return const SizedBox();

    final loc = AppLocalizations.of(context)!;
    final seasons = List<Season>.of(_content.seasonList)
      ..sort((a, b) => a.number.compareTo(b.number));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(loc.seasons, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...seasons.map((season) {
          final episodes = List<Episode>.of(season.episodes)
            ..sort((a, b) => a.number.compareTo(b.number));
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              border: Border.all(color: theme.dividerColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ExpansionTile(
              title: Text('${loc.season} ${season.number}', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              subtitle: Text('${episodes.length} ${loc.episodes}'),
              children: episodes.map((episode) {
                final duration = episode.duration > Duration.zero ? ' • ${episode.duration.inMinutes} min' : '';
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: episode.imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: episode.imageUrl,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorWidget: (_, _, _) => _episodePlaceholder(theme),
                          )
                        : _episodePlaceholder(theme),
                  ),
                  title: Text(episode.title.isEmpty ? '${loc.episode} ${episode.number}' : episode.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text('${loc.episode} ${episode.number}$duration'),
                  trailing: IconButton(tooltip: loc.play, icon: const Icon(Icons.play_arrow), onPressed: () => _playEpisode(episode)),
                );
              }).toList(),
            ),
          );
        }),
      ],
    );
  }

  Widget _episodePlaceholder(ThemeData theme) => Container(
    width: 60,
    height: 60,
    color: theme.colorScheme.surfaceContainerHighest,
    child: const Icon(Icons.movie_outlined),
  );

  Widget _buildSimilarContentSlider(ThemeData theme, bool isMobile) {
    if (widget.similarContent.isEmpty) return const SizedBox();

    final loc = AppLocalizations.of(context)!;
    final itemWidth = isMobile ? 120.0 : 150.0;
    final itemCount = widget.similarContent.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.similarContent,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: itemWidth * 1.5 + 40,
          child: Stack(
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width - 32,
                child: ListView.separated(
                  controller: _similarContentController,
                  scrollDirection: Axis.horizontal,
                  itemCount: itemCount,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  separatorBuilder: (_, _) => const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    if (index >= itemCount) return const SizedBox();
                    return _buildSimilarContentCard(
                      widget.similarContent[index],
                      itemWidth,
                      theme,
                    );
                  },
                ),
              ),
              if (itemCount > 3)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerRight,
                        end: Alignment.centerLeft,
                        colors: [
                          theme.cardColor,
                          theme.cardColor.withValues(alpha: 0.1),
                        ],
                      ),
                    ),
                    child: Center(
                      child: IconButton(
                        icon: Icon(
                          Icons.chevron_right,
                          color: theme.primaryColor,
                        ),
                        onPressed:
                            () => _similarContentController.animateTo(
                              (_similarContentController.offset + 200).clamp(
                                0.0,
                                _similarContentController
                                    .position
                                    .maxScrollExtent,
                              ),
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                            ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _clock(Duration value) {
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return value.inHours > 0 ? '${value.inHours}:$minutes:$seconds' : '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    return Dialog(
      backgroundColor: theme.cardColor,
      insetPadding: EdgeInsets.all(isMobile ? 8 : 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: size.width * (isMobile ? 0.95 : 0.9),
          maxHeight: size.height * 0.9,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 12 : 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_trailerController?.value.isInitialized == true)
                      AspectRatio(
                        aspectRatio: _trailerController!.value.aspectRatio,
                        child: VideoPlayer(_trailerController!),
                      )
                    else
                      CachedNetworkImage(
                        imageUrl: _content.backdropUrl.isNotEmpty ? _content.backdropUrl : _content.posterUrl,
                        width: double.infinity,
                        height: isMobile ? 180 : 250,
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) => Container(
                          height: isMobile ? 180 : 250,
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: const Icon(Icons.broken_image, size: 50),
                        ),
                      ),
                    if (_isLoadingDetail && _trailerController == null)
                      const Positioned.fill(child: Center(child: CircularProgressIndicator())),
                    if (_trailerController?.value.isInitialized == true)
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.black.withValues(alpha: 0.18), Colors.transparent, Colors.black.withValues(alpha: 0.72)],
                              stops: const [0, 0.48, 1],
                            ),
                          ),
                        ),
                      ),
                    if (_trailerController?.value.isInitialized == true)
                      IconButton(
                        icon: Icon(_trailerController!.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill, size: 64, color: Colors.white),
                        onPressed: _toggleTrailerPlayback,
                      )
                    else if (_trailerController == null && !_isLoadingDetail)
                      const Icon(Icons.movie_outlined, size: 52, color: Colors.white70),
                    if (_trailerController?.value.isInitialized == true)
                      Positioned(
                        left: 12,
                        right: 12,
                        bottom: 6,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            VideoProgressIndicator(
                              _trailerController!,
                              allowScrubbing: true,
                              colors: const VideoProgressColors(playedColor: Colors.deepOrange, bufferedColor: Colors.white54, backgroundColor: Colors.white24),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  tooltip: 'Reculer de 10 secondes',
                                  icon: const Icon(Icons.replay_10, color: Colors.white),
                                  onPressed: () {
                                    final c = _trailerController!;
                                    c.seekTo(c.value.position - const Duration(seconds: 10));
                                  },
                                ),
                                Text('${_clock(_trailerController!.value.position)} / ${_clock(_trailerController!.value.duration)}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                                IconButton(
                                  tooltip: 'Avancer de 10 secondes',
                                  icon: const Icon(Icons.forward_10, color: Colors.white),
                                  onPressed: () {
                                    final c = _trailerController!;
                                    c.seekTo(c.value.position + const Duration(seconds: 10));
                                  },
                                ),
                                const Spacer(),
                                IconButton(
                                  tooltip: _trailerController!.value.volume > 0 ? 'Couper le son' : 'Activer le son',
                                  icon: Icon(_trailerController!.value.volume > 0 ? Icons.volume_up : Icons.volume_off, color: Colors.white),
                                  onPressed: () {
                                    final c = _trailerController!;
                                    c.setVolume(c.value.volume > 0 ? 0 : 1);
                                    setState(() {});
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _content.title,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 16,
                                runSpacing: 8,
                                children: [
                                  if (_content.releaseYear.isNotEmpty)
                                    _buildMetadataItem(
                                      _content.releaseYear,
                                      Icons.calendar_today,
                                      theme,
                                    ),
                                  if (_content.isSeries)
                                    _buildMetadataItem(
                                      _content.seasonInfo ?? '',
                                      Icons.tv,
                                      theme,
                                    )
                                  else if (_content.duration > Duration.zero)
                                    _buildMetadataItem(
                                      _content.formattedDuration,
                                      Icons.timer,
                                      theme,
                                    ),
                                  if (_content.isHd) _buildHdBadge(theme),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (!isMobile) _buildRatingSection(theme),
                      ],
                    ),

                    if (isMobile) ...[
                      const SizedBox(height: 16),
                      _buildRatingSection(theme),
                    ],

                    const SizedBox(height: 24),

                    Wrap(
                      spacing: isMobile ? 8 : 16,
                      runSpacing: isMobile ? 8 : 16,
                      alignment: WrapAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.play_arrow, size: 20),
                          label: Text(loc.play),
                          onPressed: () => _playContent(context),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 16 : 24,
                              vertical: isMobile ? 8 : 12,
                            ),
                          ),
                        ),
                        OutlinedButton.icon(
                          icon: Icon(
                            _isPlayingTrailer ? Icons.pause : Icons.movie,
                            size: 20,
                          ),
                          label: Text(
                            _isPlayingTrailer ? (loc.pause) : (loc.trailer),
                          ),
                          onPressed: _trailerController == null ? null : _toggleTrailerPlayback,
                        ),
                        _buildActionButton(Icons.share, loc.share, theme),
                        _buildActionButton(Icons.download, loc.download, theme),
                        _buildActionButton(
                          Icons.favorite_border,
                          loc.favorites,
                          theme,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.synopsis,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _content.description.isEmpty
                              ? loc.noDescriptionAvailable
                              : _isExpanded
                              ? _content.description
                              : _content.description.length >
                                  (isMobile ? 100 : 150)
                              ? '${_content.description.substring(0, isMobile ? 100 : 150)}...'
                              : _content.description,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.9,
                            ), // Texte légèrement transparent
                          ),
                        ),
                        if (_content.description.length >
                            (isMobile ? 100 : 150))
                          TextButton(
                            onPressed:
                                () =>
                                    setState(() => _isExpanded = !_isExpanded),
                            child: Text(
                              _isExpanded ? (loc.seeLess) : (loc.seeMore),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    if (_content.genres.isNotEmpty) ...[
                      Wrap(
                        spacing: 8,
                        children:
                            _content.genres
                                .map((genre) => Chip(label: Text(genre)))
                                .toList(),
                      ),
                      const SizedBox(height: 24),
                    ],

                    if (_content.isSeries) ...[
                      _buildSeasonsSection(theme),
                      const SizedBox(height: 16),
                      _buildDistributionSection(theme),
                    ] else
                      _buildDistributionSection(theme),

                    const SizedBox(height: 32),

                    _buildSimilarContentSlider(theme, isMobile),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
