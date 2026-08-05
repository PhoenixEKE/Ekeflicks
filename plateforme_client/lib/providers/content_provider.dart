import 'package:flutter/material.dart';
import 'package:app_ekeflicks/l10n/app_localizations.dart';
import 'package:app_ekeflicks/models/content_model.dart';
import 'package:app_ekeflicks/services/content_api_service.dart';

class ContentProvider with ChangeNotifier {
  ContentProvider(this._api, {this.profileId});
  final ContentApiService _api;
  String? profileId;

  List<Content> _featuredContent = [], _continueWatching = [],
      _recommendedContent = [], _newReleases = [], _popularContent = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Content> get featuredContent => _featuredContent;
  List<Content> get continueWatching => _continueWatching;
  List<Content> get recommendedContent => _recommendedContent;
  List<Content> get newReleases => _newReleases;
  List<Content> get popularContent => _popularContent;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Content> get _allContent => {..._featuredContent, ..._continueWatching,
    ..._recommendedContent, ..._newReleases, ..._popularContent}.toList();

  Future<void> loadInitialContent(AppLocalizations _) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final feed = await _api.home(profileId: profileId);
      _featuredContent = feed.featured;
      _continueWatching = feed.continueWatching;
      _recommendedContent = feed.recommended;
      _newReleases = feed.newReleases;
      _popularContent = feed.popular;
    } catch (error) {
      _errorMessage = 'Impossible de charger les contenus. Vérifiez votre connexion.';
      debugPrint('Content home API error: $error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Content> loadDetail(String id) => _api.detail(id, profileId: profileId);
  Future<List<Content>> searchRemote(String query) => _api.search(query, profileId: profileId);
  Future<List<Content>> loadFavorites() => _api.favorites(profileId: profileId);
  Future<List<Content>> loadHistory() => _api.history(profileId: profileId);
  Future<List<Content>> loadList(String id) => _api.listContents(id, profileId: profileId);
  Future<void> addToList(String listId, String contentId) =>
      _api.addToList(listId, contentId, profileId: profileId);

  Future<void> toggleFavorite(Content content) async {
    await _api.setFavorite(content.id, !content.isFavorite, profileId: profileId);
    _replace(content.id, (item) => item.copyWith(isFavorite: !content.isFavorite));
  }

  Future<void> rate(Content content, double value) async {
    await _api.rate(content.id, value, profileId: profileId);
    _replace(content.id, (item) => item.copyWith(userRating: value));
  }

  Future<void> saveProgress(String contentId, double progress, {
    String? episodeId, Duration? position, Duration? duration, String deviceId = 'unknown'}) async {
    final safeProgress = progress.clamp(0.0, 1.0).toDouble();
    _replace(contentId, (item) => item.copyWith(progress: safeProgress));
    await _api.saveProgress(contentId: contentId, episodeId: episodeId,
      position: position ?? Duration(milliseconds: ((duration?.inMilliseconds ?? 0) * safeProgress).round()),
      duration: duration ?? Duration.zero, deviceId: deviceId, profileId: profileId);
  }

  void updateProgress(String contentId, double progress) =>
      _replace(contentId, (item) => item.copyWith(progress: progress.clamp(0, 1).toDouble()));
  List<Content> searchContent(String query) => _allContent.where((content) {
    final needle = query.toLowerCase();
    return content.title.toLowerCase().contains(needle) ||
      content.genres.any((genre) => genre.toLowerCase().contains(needle));
  }).toList();
  List<Content> getSimilarContent(Content content, {int limit = 3}) => _allContent
      .where((item) => item.id != content.id && item.genres.any(content.genres.contains))
      .take(limit).toList();
  Future<void> refreshContent(AppLocalizations loc) => loadInitialContent(loc);
  Content? getContentById(String id) {
    for (final item in _allContent) { if (item.id == id) return item; }
    return null;
  }

  void _replace(String id, Content Function(Content) transform) {
    for (final list in [_featuredContent, _continueWatching, _recommendedContent,
      _newReleases, _popularContent]) {
      final index = list.indexWhere((item) => item.id == id);
      if (index >= 0) list[index] = transform(list[index]);
    }
    notifyListeners();
  }
}
