import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:app_ekeflicks/models/content_model.dart';
import 'package:app_ekeflicks/ui/player/player_page.dart';
import 'package:app_ekeflicks/widgets/dialog/info_dialog.dart';
import 'package:app_ekeflicks/l10n/app_localizations.dart';
import 'package:app_ekeflicks/providers/device_info_provider.dart';

class GenrePage extends StatefulWidget {
  final String genre;
  final List<Content> contents;

  const GenrePage({super.key, required this.genre, required this.contents});

  @override
  State<GenrePage> createState() => _GenrePageState();
}

class _GenrePageState extends State<GenrePage> {
  final ScrollController _scrollController = ScrollController();
  AppLocalizations? get loc => AppLocalizations.of(context);

  bool _showAllMovies = false;
  bool _showAllSeries = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _handleContentPressed(Content content) {
    if (content.hasProgress) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => PlayerPage(
                videoUrl: content.videoUrl,
                title: content.title,
                imageUrl: content.posterUrl,
                startPosition: content.duration.inSeconds * content.progress!,
              ),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => InfoDialog(content: content, similarContent: []),
      );
    }
  }

  int _calculateMaxItemsPerRow(double screenWidth, int itemCount) {
    final deviceInfo = Provider.of<DeviceInfoProvider>(context, listen: false);

    if (deviceInfo.isTV) {
      // Pour TV, on montre plus d'éléments
      const itemWidth = 200.0;
      const spacing = 24.0;
      const seeAllButtonWidth = 120.0;

      final availableWidth = screenWidth - 48 - seeAllButtonWidth;
      final maxPossible = (availableWidth / (itemWidth + spacing)).floor();

      return maxPossible.clamp(4, itemCount);
    } else {
      // Pour mobile/desktop
      const itemWidth = 150.0;
      const spacing = 16.0;
      const seeAllButtonWidth = 100.0;

      final availableWidth = screenWidth - 32 - seeAllButtonWidth;
      final maxPossible = (availableWidth / (itemWidth + spacing)).floor();

      return maxPossible.clamp(1, itemCount);
    }
  }

  Widget _buildContentItem(
    Content content,
    BuildContext context, {
    double? width,
  }) {
    final deviceInfo = Provider.of<DeviceInfoProvider>(context);
    final theme = Theme.of(context);

    final itemWidth = width ?? (deviceInfo.isTV ? 200 : 150);

    return SizedBox(
      width: itemWidth,
      child: GestureDetector(
        onTap: () => _handleContentPressed(content),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              CachedNetworkImage(
                imageUrl: content.posterUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                placeholder:
                    (_, _) => Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                    ),
                errorWidget:
                    (_, _, _) => Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.broken_image,
                        size: deviceInfo.isTV ? 30 : 24,
                      ),
                    ),
              ),
              if (content.hasProgress)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(
                    value: content.progress,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary,
                    ),
                  ),
                ),
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    content.typeString,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontSize: deviceInfo.isTV ? 14 : 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentSection({
    required String title,
    required List<Content> contents,
    required bool showAll,
    required VoidCallback onSeeAllPressed,
    required BuildContext context,
  }) {
    if (contents.isEmpty) return const SizedBox.shrink();

    final deviceInfo = Provider.of<DeviceInfoProvider>(context);
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final maxItemsPerRow = _calculateMaxItemsPerRow(
      size.width,
      contents.length,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: deviceInfo.isTV ? 24 : 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$title (${contents.length})',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: deviceInfo.isTV ? 28 : 24,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              if (contents.length > maxItemsPerRow)
                TextButton(
                  onPressed: onSeeAllPressed,
                  child: Text(
                    showAll
                        ? loc?.seeLess ?? 'Voir moins'
                        : loc?.seeAll ?? 'Voir tout',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontSize: deviceInfo.isTV ? 18 : 16,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (showAll)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: deviceInfo.isTV ? 24 : 16,
            ),
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent:
                  deviceInfo.isTV
                      ? (size.width > 1200 ? 250 : 200)
                      : (size.width > 600 ? 200 : 150),
              crossAxisSpacing: deviceInfo.isTV ? 24 : 16,
              mainAxisSpacing: deviceInfo.isTV ? 24 : 16,
              childAspectRatio: deviceInfo.isTV ? 0.65 : 0.7,
            ),
            itemCount: contents.length,
            itemBuilder: (context, index) {
              return _buildContentItem(contents[index], context);
            },
          )
        else
          SizedBox(
            height: deviceInfo.isTV ? 280 : 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(
                horizontal: deviceInfo.isTV ? 24 : 16,
              ),
              itemCount: maxItemsPerRow,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.only(right: deviceInfo.isTV ? 24 : 16),
                  child: _buildContentItem(contents[index], context),
                );
              },
            ),
          ),
        SizedBox(height: deviceInfo.isTV ? 24 : 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final deviceInfo = Provider.of<DeviceInfoProvider>(context);
    final theme = Theme.of(context);
    final movies = widget.contents.where((c) => c.isMovie).toList();
    final series = widget.contents.where((c) => c.isSeries).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.genre,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
            fontSize: deviceInfo.isTV ? 32 : 24,
          ),
        ),
        centerTitle: true,
        backgroundColor: theme.appBarTheme.backgroundColor,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors:
                theme.brightness == Brightness.dark
                    ? [const Color(0xFF121212), Colors.black]
                    : [Colors.grey[100]!, Colors.grey[300]!],
          ),
        ),
        child: CustomScrollView(
          controller: _scrollController,
          physics:
              deviceInfo.isTV
                  ? const NeverScrollableScrollPhysics()
                  : const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  // Bannière du genre
                  Padding(
                    padding: EdgeInsets.all(deviceInfo.isTV ? 24 : 16),
                    child: SizedBox(
                      height: deviceInfo.isTV ? 300 : 200,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          children: [
                            CachedNetworkImage(
                              imageUrl: _getGenreBannerUrl(widget.genre),
                              width: double.infinity,
                              fit: BoxFit.cover,
                              placeholder:
                                  (_, _) => Container(
                                    color:
                                        theme
                                            .colorScheme
                                            .surfaceContainerHighest,
                                  ),
                              errorWidget:
                                  (_, _, _) => Container(
                                    color:
                                        theme
                                            .colorScheme
                                            .surfaceContainerHighest,
                                    child: Center(
                                      child: Icon(
                                        Icons.theaters,
                                        size: deviceInfo.isTV ? 60 : 50,
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.8),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.bottomLeft,
                              child: Padding(
                                padding: EdgeInsets.all(
                                  deviceInfo.isTV ? 24 : 16,
                                ),
                                child: Text(
                                  widget.genre,
                                  style: theme.textTheme.displaySmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: deviceInfo.isTV ? 40 : 32,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Films
                  _buildContentSection(
                    title: loc?.movies ?? 'Films',
                    contents: movies,
                    showAll: _showAllMovies,
                    onSeeAllPressed:
                        () => setState(() => _showAllMovies = !_showAllMovies),
                    context: context,
                  ),

                  // Séries
                  _buildContentSection(
                    title: loc?.series ?? 'Séries',
                    contents: series,
                    showAll: _showAllSeries,
                    onSeeAllPressed:
                        () => setState(() => _showAllSeries = !_showAllSeries),
                    context: context,
                  ),

                  // Tous les contenus
                  if (widget.contents.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: deviceInfo.isTV ? 24 : 16,
                      ),
                      child: Text(
                        '${loc?.allContents ?? 'Tous les contenus'} (${widget.contents.length})',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: deviceInfo.isTV ? 28 : 24,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  SizedBox(height: deviceInfo.isTV ? 24 : 16),
                ],
              ),
            ),
            if (widget.contents.isNotEmpty)
              SliverPadding(
                padding: EdgeInsets.symmetric(
                  horizontal: deviceInfo.isTV ? 24 : 16,
                ),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent:
                        deviceInfo.isTV
                            ? (MediaQuery.of(context).size.width > 1200
                                ? 250
                                : 200)
                            : 150,
                    crossAxisSpacing: deviceInfo.isTV ? 24 : 16,
                    mainAxisSpacing: deviceInfo.isTV ? 24 : 16,
                    childAspectRatio: deviceInfo.isTV ? 0.65 : 0.7,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    return _buildContentItem(widget.contents[index], context);
                  }, childCount: widget.contents.length),
                ),
              ),
            SliverToBoxAdapter(
              child: SizedBox(height: deviceInfo.isTV ? 32 : 16),
            ),
          ],
        ),
      ),
    );
  }

  String _getGenreBannerUrl(String genre) {
    const genreImages = {
      'Action': 'https://picsum.photos/1200/500?random=action',
      'Comédie': 'https://picsum.photos/1200/500?random=comedy',
      'Drame': 'https://picsum.photos/1200/500?random=drama',
      'Science-Fiction': 'https://picsum.photos/1200/500?random=scifi',
      'Documentaire': 'https://picsum.photos/1200/500?random=documentary',
      'Fantasy': 'https://picsum.photos/1200/500?random=fantasy',
      'Horreur': 'https://picsum.photos/1200/500?random=horror',
      'Romance': 'https://picsum.photos/1200/500?random=romance',
      'Aventure': 'https://picsum.photos/1200/500?random=adventure',
      'Thriller': 'https://picsum.photos/1200/500?random=thriller',
    };
    return genreImages[genre] ?? 'https://picsum.photos/1200/500?random=$genre';
  }
}
