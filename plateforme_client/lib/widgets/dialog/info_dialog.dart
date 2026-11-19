import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:app_ekeflicks/ui/player/player_page.dart';
import 'package:app_ekeflicks/l10n/app_localizations.dart';
import 'package:app_ekeflicks/models/content_model.dart';

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
  late VideoPlayerController _trailerController;
  bool _isPlayingTrailer = false;
  bool _isExpanded = false;
  bool _showFullCast = false;
  final _similarContentController = ScrollController();
  final _castController = ScrollController();

  @override
  void initState() {
    super.initState();
    _trailerController = VideoPlayerController.networkUrl(
        Uri.parse(
          widget.content.videoUrl.isNotEmpty
              ? widget.content.videoUrl
              : 'https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/720/Big_Buck_Bunny_720_10s_1MB.mp4',
        ),
      )
      ..initialize()
          .then((_) {
            if (mounted) setState(() {});
          })
          .catchError((e) {
            debugPrint('Error initializing video: $e');
            if (mounted) setState(() {});
          });
  }

  @override
  void dispose() {
    _trailerController.dispose();
    _similarContentController.dispose();
    _castController.dispose();
    super.dispose();
  }

  void _toggleTrailerPlayback() {
    if (!_trailerController.value.isInitialized) return;

    setState(() {
      _isPlayingTrailer = !_isPlayingTrailer;
      _isPlayingTrailer
          ? _trailerController.play()
          : _trailerController.pause();
    });
  }

  void _playContent(BuildContext context) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => PlayerPage(
              videoUrl: widget.content.videoUrl,
              title: widget.content.title,
              imageUrl: widget.content.posterUrl,
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
              index < (widget.content.rating?.round() ?? 0)
                  ? Icons.star
                  : Icons.star_border,
              color: theme.colorScheme.primary,
              size: 20,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${widget.content.rating?.toStringAsFixed(1) ?? '0.0'}/5',
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
        widget.content.cast?.where((name) => name.isNotEmpty).toList() ?? [];
    final fullCast = [
      if (widget.content.director?.isNotEmpty ?? false)
        {'name': widget.content.director!, 'role': 'Director', 'image': null},
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
    if (!widget.content.isSeries) return const SizedBox();

    final loc = AppLocalizations.of(context)!;
    final seasonsList =
        widget.content.seasons is List
            ? widget.content.seasons as List
            : [
              {'season': 1, 'episodes': widget.content.episodeCount ?? 10},
            ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.seasons,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(seasonsList.length, (index) {
          final season = seasonsList[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              border: Border.all(color: theme.dividerColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ExpansionTile(
              title: Text(
                '${loc.season} ${season['season']}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                '${season['episodes']} ${loc.episodes}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(
                    alpha: 0.7,
                  ), // Texte secondaire
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: List.generate(
                      3,
                      (episodeIndex) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: CachedNetworkImage(
                            imageUrl:
                                'https://picsum.photos/100/100?random=$episodeIndex',
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        ),
                        title: Text(
                          '${loc.episode} ${episodeIndex + 1}',
                          style: theme.textTheme.bodyMedium,
                        ),
                        subtitle: Text(
                          'Episode title ${episodeIndex + 1} • 45 min',
                          style: theme.textTheme.bodySmall,
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.play_arrow),
                          onPressed: () => _playContent(context),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

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
              Stack(
                alignment: Alignment.center,
                children: [
                  if (_isPlayingTrailer &&
                      _trailerController.value.isInitialized)
                    AspectRatio(
                      aspectRatio: _trailerController.value.aspectRatio,
                      child: VideoPlayer(_trailerController),
                    )
                  else
                    CachedNetworkImage(
                      imageUrl:
                          widget.content.backdropUrl.isNotEmpty
                              ? widget.content.backdropUrl
                              : widget.content.posterUrl,
                      width: double.infinity,
                      height: isMobile ? 180 : 250,
                      fit: BoxFit.cover,
                      errorWidget:
                          (_, _, _) => Container(
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: const Icon(Icons.broken_image, size: 50),
                          ),
                    ),

                  if (_trailerController.value.isInitialized)
                    IconButton(
                      icon: Icon(
                        _isPlayingTrailer ? Icons.pause : Icons.play_arrow,
                        size: 50,
                        color: Colors.white,
                      ),
                      onPressed: _toggleTrailerPlayback,
                    ),

                  Positioned(
                    top: 16,
                    right: 16,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
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
                                widget.content.title,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 16,
                                runSpacing: 8,
                                children: [
                                  if (widget.content.releaseYear.isNotEmpty)
                                    _buildMetadataItem(
                                      widget.content.releaseYear,
                                      Icons.calendar_today,
                                      theme,
                                    ),
                                  if (widget.content.isSeries)
                                    _buildMetadataItem(
                                      widget.content.seasonInfo ?? '',
                                      Icons.tv,
                                      theme,
                                    )
                                  else
                                    _buildMetadataItem(
                                      widget.content.formattedDuration,
                                      Icons.timer,
                                      theme,
                                    ),
                                  if (widget.content.isHd) _buildHdBadge(theme),
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
                          onPressed: _toggleTrailerPlayback,
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
                          widget.content.description.isEmpty
                              ? loc.noDescriptionAvailable
                              : _isExpanded
                              ? widget.content.description
                              : widget.content.description.length >
                                  (isMobile ? 100 : 150)
                              ? '${widget.content.description.substring(0, isMobile ? 100 : 150)}...'
                              : widget.content.description,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.9,
                            ), // Texte légèrement transparent
                          ),
                        ),
                        if (widget.content.description.length >
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

                    if (widget.content.genres.isNotEmpty) ...[
                      Wrap(
                        spacing: 8,
                        children:
                            widget.content.genres
                                .map((genre) => Chip(label: Text(genre)))
                                .toList(),
                      ),
                      const SizedBox(height: 24),
                    ],

                    _buildDistributionSection(theme),

                    _buildSeasonsSection(theme),

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
