import 'package:flutter/material.dart';
import 'package:app_ekeflicks/l10n/app_localizations.dart';
import 'package:app_ekeflicks/models/content_model.dart';

class ContentProvider with ChangeNotifier {
  // État du provider
  List<Content> _featuredContent = [];
  List<Content> _continueWatching = [];
  List<Content> _recommendedContent = [];
  List<Content> _newReleases = [];
  List<Content> _popularContent = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters publics
  List<Content> get featuredContent => _featuredContent;
  List<Content> get continueWatching => _continueWatching;
  List<Content> get recommendedContent => _recommendedContent;
  List<Content> get newReleases => _newReleases;
  List<Content> get popularContent => _popularContent;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Getter pour tous les contenus combinés
  List<Content> get _allContent => [
    ..._featuredContent,
    ..._continueWatching,
    ..._recommendedContent,
    ..._newReleases,
    ..._popularContent,
  ];

  // Chargement initial du contenu
  Future<void> loadInitialContent(AppLocalizations loc) async {
    _isLoading = true;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 1)); // Simule un chargement réseau

      // Génération de tous les contenus
      _featuredContent = _generateFeaturedContent(loc);
      _continueWatching = _generateContinueWatching(loc);
      _recommendedContent = _generateRecommendedContent(loc);
      _newReleases = _generateNouveautes(loc);
      _popularContent = _generatePopulaires(loc);

    } catch (e) {
      _errorMessage = 'Erreur de chargement des contenus';
      debugPrint('Erreur: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Génération des contenus vedettes
  List<Content> _generateFeaturedContent(AppLocalizations loc) {
    return [
      Content(
        id: 'featured-1',
        title: loc.leRoiDuDesert,
        description: 'Un film épique sur le désert',
        imageUrl: 'https://picsum.photos/1200/500?random=101',
        posterUrl: 'https://picsum.photos/300/450?random=101',
        backdropUrl: 'https://picsum.photos/1200/500?random=101',
        videoUrl: 'https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/720/Big_Buck_Bunny_720_10s_1MB.mp4',
        type: ContentType.movie,
        genres: ['Aventure', 'Action'],
        releaseYear: '2023',
        duration: const Duration(hours: 2, minutes: 15),
        rating: 4.7,
        ageRating: '12+',
        isHd: true,
      ),
      Content(
        id: 'featured-2',
        title: '${loc.nouveauFilm} 2',
        description: 'Description du nouveau film',
        imageUrl: 'https://picsum.photos/1200/500?random=102',
        posterUrl: 'https://picsum.photos/300/450?random=102',
        videoUrl: 'https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/720/Big_Buck_Bunny_720_10s_1MB.mp4',
        type: ContentType.movie,
        genres: ['Science-fiction'],
        releaseYear: '2023',
        duration: const Duration(hours: 1, minutes: 50),
        rating: 4.3,
        isHd: true,
      ),
    ];
  }

  // Génération des contenus "Continuer à regarder"
  List<Content> _generateContinueWatching(AppLocalizations loc) {
    return [
      Content(
        id: 'continue-1',
        title: 'Série en cours',
        description: 'Contenu que vous regardez actuellement',
        imageUrl: 'https://picsum.photos/300/169?random=201',
        posterUrl: 'https://picsum.photos/200/300?random=201',
        videoUrl: 'https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/720/Big_Buck_Bunny_720_10s_1MB.mp4',
        type: ContentType.series,
        genres: ['Drame'],
        releaseYear: '2022',
        duration: const Duration(minutes: 45),
        progress: 0.65,
      ),
    ];
  }

  // Génération des recommandations
  List<Content> _generateRecommendedContent(AppLocalizations loc) {
    return List.generate(4, (i) => Content(
      id: 'recommended-$i',
      title: '${loc.recommended} ${i + 1}',
      description: 'Description du contenu recommandé ${i + 1}',
      imageUrl: 'https://picsum.photos/300/169?random=30$i',
      posterUrl: 'https://picsum.photos/200/300?random=30$i',
      videoUrl: 'https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/720/Big_Buck_Bunny_720_10s_1MB.mp4',
      type: i.isEven ? ContentType.movie : ContentType.series,
      genres: i.isEven ? ['Action'] : ['Comédie'],
      releaseYear: '202${3 - i}',
      duration: Duration(minutes: 90 + i * 10),
      rating: 4.0 + (i * 0.2),
    ));
  }

  // Génération des nouveautés
  List<Content> _generateNouveautes(AppLocalizations loc) {
    return List.generate(6, (i) => Content(
      id: 'new-$i',
      title: '${loc.nouveauFilm} ${i + 1}',
      description: '${loc.nouveauFilm} description ${i + 1}',
      imageUrl: 'https://picsum.photos/300/169?random=40$i',
      posterUrl: 'https://picsum.photos/200/300?random=40$i',
      videoUrl: 'https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/720/Big_Buck_Bunny_720_10s_1MB.mp4',
      type: ContentType.movie,
      genres: ['Nouveauté'],
      releaseYear: '2023',
      duration: Duration(minutes: 80 + i * 5),
      rating: 3.8 + (i * 0.1),
    ));
  }

  // Génération des contenus populaires
  List<Content> _generatePopulaires(AppLocalizations loc) {
    return List.generate(5, (i) => Content(
      id: 'popular-$i',
      title: '${loc.populaire} ${i + 1}',
      description: '${loc.populaire} description ${i + 1}',
      imageUrl: 'https://picsum.photos/300/169?random=50$i',
      posterUrl: 'https://picsum.photos/200/300?random=50$i',
      videoUrl: 'https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/720/Big_Buck_Bunny_720_10s_1MB.mp4',
      type: i.isEven ? ContentType.movie : ContentType.series,
      genres: i.isEven ? ['Action'] : ['Drame'],
      releaseYear: '202${2 - (i % 3)}',
      duration: Duration(minutes: 100 + i * 8),
      rating: 4.2 + (i * 0.1),
    ));
  }

  // Trouver des contenus similaires
  List<Content> getSimilarContent(Content content, {int limit = 3}) {
    return _allContent
      .where((c) => c.id != content.id && 
          c.genres.any((genre) => content.genres.contains(genre)))
      .take(limit)
      .toList();
  }

  // Rafraîchir les contenus
  Future<void> refreshContent(AppLocalizations loc) async {
    await loadInitialContent(loc);
  }

  // Trouver un contenu par son ID
  Content? getContentById(String id) {
    try {
      return _allContent.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  // Mettre à jour la progression de visionnage
  void updateProgress(String contentId, double progress) {
    final allLists = [
      _featuredContent,
      _continueWatching,
      _recommendedContent,
      _newReleases,
      _popularContent,
    ];

    for (var list in allLists) {
      final index = list.indexWhere((c) => c.id == contentId);
      if (index != -1) {
        list[index] = list[index].copyWith(progress: progress);
        notifyListeners();
        break;
      }
    }
  }

  // Recherche de contenus
  List<Content> searchContent(String query) {
    return _allContent
      .where((c) => c.title.toLowerCase().contains(query.toLowerCase()))
      .toList();
  }
}