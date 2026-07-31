import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_ekeflicks/providers/device_info_provider.dart';
import 'package:app_ekeflicks/ui/pages/tv_search_page.dart';
import 'package:app_ekeflicks/models/content_model.dart';

class IASearchDelegate extends SearchDelegate<String> {
  final bool isTV;
  final List<Content> _searchHistory = [];
  final List<Content> _popularSearches = [];

  IASearchDelegate({bool? isTV}) : isTV = isTV ?? false;

  // Factory method pour détection auto
  factory IASearchDelegate.auto(BuildContext context) {
    final deviceInfo = Provider.of<DeviceInfoProvider>(context, listen: false);
    return IASearchDelegate(isTV: deviceInfo.isTV);
  }

  @override
  String get searchFieldLabel => 'Rechercher films, séries, genres...';

  @override
  TextStyle get searchFieldStyle => const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w500,
      );

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      scaffoldBackgroundColor: Colors.black,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.black.withOpacity(0.95),
        elevation: 4,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: const TextStyle(color: Colors.white70),
        border: InputBorder.none,
        focusedBorder: InputBorder.none,
        enabledBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: Colors.white),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    if (isTV) {
      return [
        IconButton(
          icon: const Icon(Icons.tv, color: Colors.blue),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => TVSearchPage(initialQuery: query),
              ),
            );
          },
          tooltip: 'Mode TV complet',
        ),
      ];
    }

    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear, color: Colors.white70),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
          tooltip: 'Effacer',
        ),
      IconButton(
        icon: const Icon(Icons.mic, color: Colors.white70),
        onPressed: () => _showVoiceSearch(context),
        tooltip: 'Recherche vocale',
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    if (isTV) {
      return const SizedBox.shrink();
    }

    return IconButton(
      icon: const Icon(Icons.arrow_back, color: Colors.white),
      onPressed: () => close(context, ''),
      tooltip: 'Retour',
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (isTV) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TVSearchPage(initialQuery: query),
          ),
        );
      });
      return _buildLoadingScreen();
    }

    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (isTV) {
      return _buildLoadingScreen();
    }

    if (query.isEmpty) {
      return _buildInitialSuggestions(context);
    }

    return _buildSearchSuggestions(context);
  }

  Widget _buildLoadingScreen() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.red)),
            SizedBox(height: 20),
            Text(
              'Chargement...',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialSuggestions(BuildContext context) {
    return Container(
      color: Colors.black,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_searchHistory.isNotEmpty) ...[
              _buildSectionTitle('Recherches récentes'),
              const SizedBox(height: 12),
              _buildHistoryList(context),
              const SizedBox(height: 24),
            ],
            _buildSectionTitle('Tendances actuelles'),
            const SizedBox(height: 12),
            _buildTrendingGrid(),
            const SizedBox(height: 24),
            _buildSectionTitle('Catégories populaires'),
            const SizedBox(height: 12),
            _buildCategoriesGrid(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildHistoryList(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _searchHistory.take(5).map((content) {
        return ActionChip(
          backgroundColor: Colors.white.withOpacity(0.1),
          side: BorderSide(color: Colors.white.withOpacity(0.3)),
          label: Text(
            content.title,
            style: const TextStyle(color: Colors.white),
          ),
          onPressed: () {
            query = content.title;
            showResults(context);
          },
          avatar: const Icon(Icons.history, size: 16, color: Colors.white70),
        );
      }).toList(),
    );
  }

  Widget _buildTrendingGrid() {
    final trendingContent = _generateTrendingContent();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 3,
      ),
      itemCount: trendingContent.length,
      itemBuilder: (context, index) {
        final content = trendingContent[index];
        return _buildTrendingItem(content, index);
      },
    );
  }

  Widget _buildTrendingItem(Content content, int index) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(
              image: NetworkImage(content.imageUrl),
              fit: BoxFit.cover,
            ),
          ),
        ),
        title: Text(
          content.title,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          'Trending #${index + 1}',
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        trailing: const Icon(Icons.trending_up, color: Colors.red, size: 16),
        onTap: () {
          // Naviguer vers le contenu
        },
      ),
    );
  }

  Widget _buildCategoriesGrid(BuildContext context) {
    final categories = ['Action', 'Comédie', 'Drame', 'Science-fiction', 'Horreur', 'Romance'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((category) {
        return ActionChip(
          backgroundColor: Colors.red.withOpacity(0.2),
          side: BorderSide(color: Colors.red.withOpacity(0.5)),
          label: Text(
            category,
            style: const TextStyle(color: Colors.white),
          ),
          onPressed: () {
            query = category;
            showResults(context);
          },
          avatar: const Icon(Icons.category, size: 16, color: Colors.white),
        );
      }).toList(),
    );
  }

  Widget _buildSearchSuggestions(BuildContext context) {
    final suggestions = _getAllSuggestions()
        .where((suggestion) => suggestion.toLowerCase().contains(query.toLowerCase()))
        .toList();

    if (suggestions.isEmpty) {
      return _buildNoResults(context);
    }

    return Container(
      color: Colors.black,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          return _buildSuggestionItem(context, suggestions[index], index);
        },
      ),
    );
  }

  Widget _buildSuggestionItem(BuildContext context, String suggestion, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: const Icon(Icons.search, color: Colors.white70),
        title: Text(
          suggestion,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white70),
        onTap: () {
          query = suggestion;
          showResults(context);
        },
      ),
    );
  }

  Widget _buildSearchResults(BuildContext context) {
    final results = _generateSearchResults(query);

    return Container(
      color: Colors.black,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '${results.length} résultats pour "$query"',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.7,
              ),
              itemCount: results.length,
              itemBuilder: (context, index) {
                return _buildResultItem(results[index], index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultItem(Content content, int index) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Image.network(
              content.imageUrl,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    content.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.yellow, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        content.rating.toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResults(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.white70),
            const SizedBox(height: 16),
            const Text(
              'Aucun résultat trouvé',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Essayez avec d\'autres mots-clés',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                query = '';
                showSuggestions(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Voir les suggestions'),
            ),
          ],
        ),
      ),
    );
  }

  void _showVoiceSearch(BuildContext context) {
    // Implémentation de la recherche vocale
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recherche vocale'),
        content: const Text('Fonctionnalité à venir...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  List<String> _getAllSuggestions() {
    return [
      'Action',
      'Comédie',
      'Drame',
      'Science-fiction',
      'Horreur',
      'Romance',
      'Thriller',
      'Documentaire',
      'Animation',
      'Aventure',
      'Policier',
      'Fantastique',
    ];
  }

  List<Content> _generateTrendingContent() {
    return List.generate(6, (index) {
      return Content(
        id: 'trending_$index',
        title: ['Avengers', 'Stranger Things', 'The Witcher', 'Dune', 'Squid Game', 'Lupin'][index],
        description: 'Description trending $index',
        imageUrl: 'https://picsum.photos/200/300?random=trending$index',
        posterUrl: 'https://picsum.photos/200/300?random=trending$index',
        videoUrl: '',
        type: ContentType.movie,
        genres: ['Action'],
        releaseYear: '2023',
        duration: const Duration(minutes: 120),
        rating: 4.0 + (index * 0.1),
      );
    });
  }

  List<Content> _generateSearchResults(String query) {
    return List.generate(12, (index) {
      return Content(
        id: 'result_${query}_$index',
        title: '$query Résultat ${index + 1}',
        description: 'Description pour $query résultat ${index + 1}',
        imageUrl: 'https://picsum.photos/200/300?random=$query$index',
        posterUrl: 'https://picsum.photos/200/300?random=$query$index',
        videoUrl: '',
        type: ContentType.movie,
        genres: [query],
        releaseYear: '2023',
        duration: Duration(minutes: 90 + index * 5),
        rating: 3.5 + (index * 0.2),
      );
    });
  }
}