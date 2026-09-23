import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:app_ekeflicks/widgets/banner/hero_banner.dart';
import 'package:app_ekeflicks/widgets/app_bars/connect_app_bar.dart';
import 'package:app_ekeflicks/l10n/app_localizations.dart';
import 'package:app_ekeflicks/models/content_model.dart';
import 'package:app_ekeflicks/ui/player/player_page.dart';
import 'package:app_ekeflicks/ui/pages/genre_page.dart';
import 'package:app_ekeflicks/widgets/dialog/info_dialog.dart';
import 'package:app_ekeflicks/providers/device_info_provider.dart';

class PostLoginPage extends StatefulWidget {
  const PostLoginPage({super.key});

  @override
  State<PostLoginPage> createState() => _PostLoginPageState();
}

class _PostLoginPageState extends State<PostLoginPage> {
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;

  bool _showAllContinueWatching = false;
  bool _showAllTrending = false;
  bool _showAllNewReleases = false;
  bool _showAllRecommended = false;
  bool _showAllGenres = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    setState(() {
      _scrollOffset = _scrollController.offset;
    });
  }

  void _toggleShowAll(String section) {
    setState(() {
      switch (section) {
        case 'continue-watching':
          _showAllContinueWatching = !_showAllContinueWatching;
          break;
        case 'trending':
          _showAllTrending = !_showAllTrending;
          break;
        case 'new-releases':
          _showAllNewReleases = !_showAllNewReleases;
          break;
        case 'recommended':
          _showAllRecommended = !_showAllRecommended;
          break;
        case 'genres':
          _showAllGenres = !_showAllGenres;
          break;
      }
    });
  }

  double _validateRating(double value) {
    return value.clamp(0.0, 5.0);
  }

  String _generateValidYear(int index) {
    final baseYear = 2000;
    final validYear = baseYear + (index % 24);
    return validYear.toString().padLeft(4, '0');
  }

  void _handlePlayPressed(
    BuildContext context,
    Content content, {
    double? startAt,
  }) {
    final videoUrl = content.videoUrl.trim();

    if (videoUrl.isEmpty || !videoUrl.startsWith('http')) {
      final loc = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc?.videoNotAvailable ?? 'Video not available'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => PlayerPage(
                videoUrl: videoUrl,
                title: content.title,
                imageUrl: content.posterUrl,
                startPosition: startAt,
              ),
        ),
      );
    } catch (e) {
      final loc = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${loc?.videoPlaybackError ?? 'Playback error'}: ${e.toString()}',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleInfoPressed(BuildContext context, Content content) {
    showDialog(
      context: context,
      builder:
          (context) => InfoDialog(
            content: content,
            similarContent: _generateSimilarContent(content),
          ),
    );
  }

  List<Content> _generateSimilarContent(Content content) {
    final allContents = [
      ..._generateFeaturedContent(),
      ..._generateContinueWatching(),
      ..._generateTrendingContent(),
      ..._generateNewReleases(),
      ..._generateRecommendedContent(),
    ];

    return allContents
        .where(
          (c) =>
              c.id != content.id &&
              c.genres.any((g) => content.genres.contains(g)),
        )
        .take(5)
        .toList();
  }

  void _navigateToGenrePage(BuildContext context, String genre) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                GenrePage(genre: genre, contents: _getContentsByGenre(genre)),
      ),
    );
  }

  List<Content> _getContentsByGenre(String genre) {
    return [
      ..._generateFeaturedContent(),
      ..._generateContinueWatching(),
      ..._generateTrendingContent(),
      ..._generateNewReleases(),
      ..._generateRecommendedContent(),
    ].where((content) => content.genres.contains(genre)).toList();
  }

  List<Content> _generateFeaturedContent() {
    final loc = AppLocalizations.of(context);
    return [
      Content(
        id: '1',
        title: loc?.leRoiDuDesert ?? 'Desert King',
        description: 'An epic desert film',
        imageUrl: 'https://picsum.photos/1200/500?random=999',
        posterUrl: 'https://picsum.photos/300/450?random=999',
        backdropUrl: 'https://picsum.photos/1200/500?random=999',
        videoUrl:
            'https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/720/Big_Buck_Bunny_720_10s_1MB.mp4',
        type: ContentType.movie,
        genres: ['Adventure', 'Action', 'Drama'],
        releaseYear: '2023',
        duration: const Duration(hours: 2, minutes: 18),
        rating: _validateRating(4.5),
        ageRating: '12+',
        isHd: true,
      ),
      Content(
        id: '2',
        title: 'The Great Adventure',
        description: 'A captivating series about a group of explorers',
        imageUrl: 'https://picsum.photos/1200/500?random=996',
        posterUrl: 'https://picsum.photos/300/450?random=996',
        backdropUrl: 'https://picsum.photos/1200/500?random=996',
        videoUrl:
            'https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/720/Big_Buck_Bunny_720_10s_1MB.mp4',
        type: ContentType.series,
        genres: ['Adventure', 'Drama'],
        releaseYear: '2023',
        duration: const Duration(minutes: 45),
        rating: _validateRating(4.8),
        ageRating: '12+',
        isHd: true,
        seasons: 3,
        episodeCount: 24,
        cast: ['John Doe', 'Jane Smith'],
        director: 'John Director',
      ),
    ];
  }

  List<Content> _generateContinueWatching() {
    return [
      Content(
        id: '3',
        title: 'The Witcher',
        description: 'Geralt of Rivia, a mutant monster hunter...',
        imageUrl: 'https://picsum.photos/200/300?random=100',
        posterUrl: 'https://picsum.photos/200/300?random=100',
        videoUrl:
            'https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/720/Big_Buck_Bunny_720_10s_1MB.mp4',
        type: ContentType.series,
        genres: ['Fantasy', 'Action'],
        releaseYear: _generateValidYear(19),
        duration: const Duration(minutes: 60),
        rating: _validateRating(4.5),
        progress: 0.3,
        seasons: 3,
      ),
      Content(
        id: '4',
        title: 'Stranger Things',
        description: 'A small town discovers a frightening mystery...',
        imageUrl: 'https://picsum.photos/200/300?random=101',
        posterUrl: 'https://picsum.photos/200/300?random=101',
        videoUrl:
            'https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/720/Big_Buck_Bunny_720_10s_1MB.mp4',
        type: ContentType.series,
        genres: ['Science-Fiction', 'Horror'],
        releaseYear: _generateValidYear(16),
        duration: const Duration(minutes: 50),
        rating: _validateRating(4.0),
        progress: 0.8,
        seasons: 4,
      ),
      Content(
        id: '5',
        title: 'Breaking Bad',
        description: 'A chemistry teacher turns to meth production...',
        imageUrl: 'https://picsum.photos/200/300?random=102',
        posterUrl: 'https://picsum.photos/200/300?random=102',
        videoUrl:
            'https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/720/Big_Buck_Bunny_720_10s_1MB.mp4',
        type: ContentType.series,
        genres: ['Drama', 'Crime'],
        releaseYear: _generateValidYear(13),
        duration: const Duration(minutes: 45),
        rating: _validateRating(4.0),
        progress: 0.6,
        seasons: 5,
      ),
      Content(
        id: '6',
        title: 'The Dark Knight',
        description: 'Batman faces the Joker in this cult film...',
        imageUrl: 'https://picsum.photos/200/300?random=103',
        posterUrl: 'https://picsum.photos/200/300?random=103',
        videoUrl:
            'https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/720/Big_Buck_Bunny_720_10s_1MB.mp4',
        type: ContentType.movie,
        genres: ['Action', 'Drama'],
        releaseYear: _generateValidYear(8),
        duration: const Duration(hours: 2, minutes: 32),
        rating: _validateRating(4.5),
        progress: 0.4,
      ),
      Content(
        id: '7',
        title: 'Inception',
        description: 'A thief who infiltrates dreams...',
        imageUrl: 'https://picsum.photos/200/300?random=104',
        posterUrl: 'https://picsum.photos/200/300?random=104',
        videoUrl:
            'https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/720/Big_Buck_Bunny_720_10s_1MB.mp4',
        type: ContentType.movie,
        genres: ['Science-Fiction', 'Action'],
        releaseYear: _generateValidYear(10),
        duration: const Duration(hours: 2, minutes: 28),
        rating: _validateRating(4.2),
        progress: 0.7,
      ),
      Content(
        id: '8',
        title: 'Pulp Fiction',
        description: 'Interwoven stories of criminals in Los Angeles...',
        imageUrl: 'https://picsum.photos/200/300?random=105',
        posterUrl: 'https://picsum.photos/200/300?random=105',
        videoUrl:
            'https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/720/Big_Buck_Bunny_720_10s_1MB.mp4',
        type: ContentType.movie,
        genres: ['Crime', 'Drama'],
        releaseYear: _generateValidYear(94),
        duration: const Duration(hours: 2, minutes: 34),
        rating: _validateRating(4.8),
        progress: 0.2,
      ),
    ];
  }

  List<Content> _generateTrendingContent() {
    return List.generate(
      15,
      (index) => Content(
        id: 'trending_$index',
        title: 'Trending $index',
        description: 'Description of trending content $index',
        imageUrl: 'https://picsum.photos/500/280?random=${100 + index}',
        posterUrl: 'https://picsum.photos/200/300?random=${100 + index}',
        videoUrl:
            'https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/720/Big_Buck_Bunny_720_10s_1MB.mp4',
        type: index % 2 == 0 ? ContentType.movie : ContentType.series,
        genres: [index % 2 == 0 ? 'Action' : 'Drama'],
        releaseYear: _generateValidYear(20 + index % 4),
        duration: Duration(minutes: 90 + index * 10),
        rating: _validateRating(3.5 + index * 0.1),
      ),
    );
  }

  List<Content> _generateNewReleases() {
    final loc = AppLocalizations.of(context);
    return List.generate(
      12,
      (index) => Content(
        id: 'new_$index',
        title: '${loc?.newRelease ?? 'New Release'} $index',
        description: 'Description of new release $index',
        imageUrl: 'https://picsum.photos/200/300?random=${200 + index}',
        posterUrl: 'https://picsum.photos/200/300?random=${200 + index}',
        videoUrl:
            'https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/720/Big_Buck_Bunny_720_10s_1MB.mp4',
        type: ContentType.movie,
        genres: ['Action', 'Adventure'],
        releaseYear: _generateValidYear(23),
        duration: Duration(minutes: 100 + index * 5),
        rating: _validateRating(4.0 + index * 0.1),
      ),
    );
  }

  List<Content> _generateRecommendedContent() {
    final loc = AppLocalizations.of(context);
    return List.generate(
      10,
      (index) => Content(
        id: 'recommended_$index',
        title: '${loc?.recommendedForYou ?? 'Recommended for you'} $index',
        description: 'Content recommended especially for you $index',
        imageUrl: 'https://picsum.photos/500/280?random=${300 + index}',
        posterUrl: 'https://picsum.photos/200/300?random=${300 + index}',
        videoUrl:
            'https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/720/Big_Buck_Bunny_720_10s_1MB.mp4',
        type: index % 3 == 0 ? ContentType.movie : ContentType.series,
        genres: ['Drama', 'Comedy'],
        releaseYear: _generateValidYear(22 + index % 2),
        duration: Duration(minutes: 80 + index * 8),
        rating: _validateRating(4.2 + index * 0.1),
      ),
    );
  }

  List<Map<String, dynamic>> _generatePopularGenres() {
    final loc = AppLocalizations.of(context);
    return [
      {
        'title': loc?.action ?? 'Action',
        'imageUrl': 'https://picsum.photos/300/180?random=101',
        'contents':
            _getContentsByGenre(loc?.action ?? 'Action').take(3).toList(),
      },
      {
        'title': loc?.comedy ?? 'Comedy',
        'imageUrl': 'https://picsum.photos/300/180?random=102',
        'contents':
            _getContentsByGenre(loc?.comedy ?? 'Comedy').take(3).toList(),
      },
      {
        'title': loc?.drama ?? 'Drama',
        'imageUrl': 'https://picsum.photos/300/180?random=103',
        'contents': _getContentsByGenre(loc?.drama ?? 'Drama').take(3).toList(),
      },
      {
        'title': loc?.sciFi ?? 'Sci-Fi',
        'imageUrl': 'https://picsum.photos/300/180?random=104',
        'contents':
            _getContentsByGenre(loc?.sciFi ?? 'Sci-Fi').take(3).toList(),
      },
      {
        'title': loc?.documentary ?? 'Documentary',
        'imageUrl': 'https://picsum.photos/300/180?random=105',
        'contents':
            _getContentsByGenre(
              loc?.documentary ?? 'Documentary',
            ).take(3).toList(),
      },
      {
        'title': loc?.fantasy ?? 'Fantasy',
        'imageUrl': 'https://picsum.photos/300/180?random=106',
        'contents':
            _getContentsByGenre(loc?.fantasy ?? 'Fantasy').take(3).toList(),
      },
      {
        'title': loc?.horror ?? 'Horror',
        'imageUrl': 'https://picsum.photos/300/180?random=107',
        'contents':
            _getContentsByGenre(loc?.horror ?? 'Horror').take(3).toList(),
      },
      {
        'title': loc?.romance ?? 'Romance',
        'imageUrl': 'https://picsum.photos/300/180?random=108',
        'contents':
            _getContentsByGenre(loc?.romance ?? 'Romance').take(3).toList(),
      },
    ];
  }

  Widget _buildContentCard({
    required Content content,
    required Function(Content) onContentPressed,
    bool isLarge = false,
    String? section,
    double width = 120,
  }) {
    final deviceInfo = Provider.of<DeviceInfoProvider>(context);

    return GestureDetector(
      onTap: () => onContentPressed(content),
      child: Container(
        width: width,
        margin: const EdgeInsets.all(4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: content.posterUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder:
                      (context, url) => Container(
                        color:
                            Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                      ),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              content.title,
              maxLines: deviceInfo.isTV ? 2 : 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: deviceInfo.isTV ? 16 : 14,
              ),
            ),
            if (section == 'continue-watching' && content.progress != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: LinearProgressIndicator(
                  value: content.progress,
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenreCard(Map<String, dynamic> genreData, {double width = 120}) {
    final deviceInfo = Provider.of<DeviceInfoProvider>(context);
    final loc = AppLocalizations.of(context);

    return GestureDetector(
      onTap: () => _navigateToGenrePage(context, genreData['title']),
      child: Container(
        width: width,
        margin: const EdgeInsets.all(4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  children: [
                    CachedNetworkImage(
                      imageUrl: genreData['imageUrl'],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder:
                          (_, _) => Container(
                            color:
                                Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                          ),
                      errorWidget: (_, _, _) => const Icon(Icons.error),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
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
                        child: Text(
                          genreData['title'],
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: deviceInfo.isTV ? 16 : 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(genreData['contents'] as List).length} ${loc?.titles ?? 'titles'}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: deviceInfo.isTV ? 14 : 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _calculateMaxItemsPerRow(double screenWidth, int itemCount) {
    final deviceInfo = Provider.of<DeviceInfoProvider>(context);

    if (deviceInfo.isTV) {
      // For TV, show more items
      const itemWidth = 200.0;
      const spacing = 16.0;
      const seeAllButtonWidth = 120.0;

      final availableWidth = screenWidth - 32 - seeAllButtonWidth;
      final maxPossible = (availableWidth / (itemWidth + spacing)).floor();

      return maxPossible.clamp(4, itemCount);
    } else {
      // For mobile/desktop
      const itemWidth = 150.0;
      const spacing = 16.0;
      const seeAllButtonWidth = 100.0;

      final availableWidth = screenWidth - 32 - seeAllButtonWidth;
      final maxPossible = (availableWidth / (itemWidth + spacing)).floor();

      return maxPossible.clamp(1, itemCount);
    }
  }

  Widget _buildContentGrid({
    required List<Content> contents,
    required Function(Content) onContentPressed,
    bool isLarge = false,
    String? section,
  }) {
    final deviceInfo = Provider.of<DeviceInfoProvider>(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth - 16;
        final cardWidth =
            deviceInfo.isTV
                ? (isLarge ? 250.0 : 200.0)
                : (isLarge ? 200.0 : 120.0);

        final crossAxisCount = (availableWidth / cardWidth).floor().clamp(
          1,
          deviceInfo.isTV ? 8 : 6,
        );
        final adjustedCardWidth = (availableWidth / crossAxisCount) - 8;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio:
                deviceInfo.isTV
                    ? (isLarge ? 250 / 350 : 200 / 280)
                    : (isLarge ? 200 / 280 : 120 / 180),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemCount: contents.length,
          itemBuilder: (context, index) {
            return _buildContentCard(
              content: contents[index],
              onContentPressed: onContentPressed,
              isLarge: isLarge,
              section: section,
              width: adjustedCardWidth,
            );
          },
        );
      },
    );
  }

  Widget _buildGenreGrid({required List<Map<String, dynamic>> genres}) {
    final deviceInfo = Provider.of<DeviceInfoProvider>(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth - 16;
        final cardWidth = deviceInfo.isTV ? 200.0 : 120.0;

        final crossAxisCount = (availableWidth / cardWidth).floor().clamp(
          1,
          deviceInfo.isTV ? 8 : 6,
        );
        final adjustedCardWidth = (availableWidth / crossAxisCount) - 8;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: deviceInfo.isTV ? 200 / 250 : 120 / 180,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemCount: genres.length,
          itemBuilder: (context, index) {
            return _buildGenreCard(genres[index], width: adjustedCardWidth);
          },
        );
      },
    );
  }

  Widget _buildSection({
    required String title,
    required List<Content> contents,
    required String section,
    required Function(Content) onContentPressed,
    bool isLarge = false,
  }) {
    if (contents.isEmpty) return const SizedBox.shrink();

    final deviceInfo = Provider.of<DeviceInfoProvider>(context);
    final loc = AppLocalizations.of(context);

    bool showAll;
    switch (section) {
      case 'continue-watching':
        showAll = _showAllContinueWatching;
        break;
      case 'trending':
        showAll = _showAllTrending;
        break;
      case 'new-releases':
        showAll = _showAllNewReleases;
        break;
      case 'recommended':
        showAll = _showAllRecommended;
        break;
      default:
        showAll = false;
    }

    final maxItemsPerRow = _calculateMaxItemsPerRow(
      MediaQuery.of(context).size.width,
      contents.length,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: deviceInfo.isTV ? 28 : 24,
                ),
              ),
              if (contents.length > maxItemsPerRow)
                TextButton(
                  onPressed: () => _toggleShowAll(section),
                  child: Text(
                    showAll
                        ? loc?.seeLess ?? 'See less'
                        : loc?.seeAll ?? 'See all',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: deviceInfo.isTV ? 18 : 16,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (!showAll)
          SizedBox(
            height:
                deviceInfo.isTV ? (isLarge ? 350 : 280) : (isLarge ? 280 : 180),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: contents.length.clamp(0, maxItemsPerRow),
              itemBuilder: (context, index) {
                return _buildContentCard(
                  content: contents[index],
                  onContentPressed: onContentPressed,
                  isLarge: isLarge,
                  section: section,
                );
              },
            ),
          ),
        if (showAll)
          _buildContentGrid(
            contents: contents,
            onContentPressed: onContentPressed,
            isLarge: isLarge,
            section: section,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final deviceInfo = Provider.of<DeviceInfoProvider>(context);
    final loc = AppLocalizations.of(context);
    final popularGenres = _generatePopularGenres();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: ConnectAppBar(scrollOffset: _scrollOffset),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors:
                Theme.of(context).brightness == Brightness.dark
                    ? [const Color(0xFF121212), Colors.black]
                    : [Colors.grey[100]!, Colors.grey[300]!],
          ),
        ),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1600),
            child: CustomScrollView(
              controller: _scrollController,
              physics:
                  deviceInfo.isTV
                      ? const NeverScrollableScrollPhysics()
                      : const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: HeroBanner(
                    contents: _generateFeaturedContent(),
                    onPlayPressed:
                        (content) => _handlePlayPressed(context, content),
                    onInfoPressed:
                        (content) => _handleInfoPressed(context, content),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.only(top: 20),
                  sliver: SliverToBoxAdapter(
                    child: _buildSection(
                      title: loc?.continueWatching ?? 'Continue Watching',
                      contents: _generateContinueWatching(),
                      section: 'continue-watching',
                      onContentPressed:
                          (content) => _handlePlayPressed(
                            context,
                            content,
                            startAt:
                                content.progress != null
                                    ? content.duration.inSeconds *
                                        content.progress!
                                    : null,
                          ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.only(top: 20),
                  sliver: SliverToBoxAdapter(
                    child: _buildSection(
                      title: loc?.popularOnEkeflicks ?? 'Popular on Ekeflicks',
                      contents: _generateTrendingContent(),
                      section: 'trending',
                      onContentPressed:
                          (content) => _handleInfoPressed(context, content),
                      isLarge: true,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.only(top: 20),
                  sliver: SliverToBoxAdapter(
                    child: _buildSection(
                      title: loc?.newReleases ?? 'New Releases',
                      contents: _generateNewReleases(),
                      section: 'new-releases',
                      onContentPressed:
                          (content) => _handleInfoPressed(context, content),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.only(top: 20),
                  sliver: SliverToBoxAdapter(
                    child: _buildSection(
                      title: loc?.recommendedForYou ?? 'Recommended for You',
                      contents: _generateRecommendedContent(),
                      section: 'recommended',
                      onContentPressed:
                          (content) => _handleInfoPressed(context, content),
                      isLarge: true,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.only(top: 20, bottom: 30),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                loc?.popularGenres ?? 'Popular Genres',
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: deviceInfo.isTV ? 28 : 24,
                                ),
                              ),
                              if (popularGenres.length > 5)
                                TextButton(
                                  onPressed: () => _toggleShowAll('genres'),
                                  child: Text(
                                    _showAllGenres
                                        ? loc?.seeLess ?? 'See less'
                                        : loc?.seeAll ?? 'See all',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontSize: deviceInfo.isTV ? 18 : 16,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (!_showAllGenres)
                          SizedBox(
                            height: deviceInfo.isTV ? 250 : 180,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              itemCount: popularGenres.length.clamp(0, 5),
                              itemBuilder: (context, index) {
                                return _buildGenreCard(popularGenres[index]);
                              },
                            ),
                          ),
                        if (_showAllGenres)
                          _buildGenreGrid(genres: popularGenres),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
