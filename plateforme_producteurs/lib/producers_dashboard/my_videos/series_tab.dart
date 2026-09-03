//serie_tab.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:plateforme_producteurs/core/core.dart';
import 'package:plateforme_producteurs/models/series_models.dart';
// Import séparé pour éviter les conflits
import 'add_season_modal.dart' as season_modal;
import 'add_episode_modal.dart' as episode_modal;
import 'series_details_modal.dart';

class SeriesTab extends StatefulWidget {
  const SeriesTab({super.key});

  @override
  State<SeriesTab> createState() => _SeriesTabState();
}

class _SeriesTabState extends State<SeriesTab> {
  final List<Series> seriesList = [
    Series(
      title: "Série Test",
      description: "Description de test pour la série",
      genres: ["Drame", "Test"],
      language: "Français",
      releaseYear: 2023,
      country: "France",
      status: "Publié",
      team: ProductionTeam(
        director: "Réalisateur Test",
        screenwriter: "Scénariste Test",
        producers: ["Production Test"],
        actors: {"Acteur Test": "Rôle Test"},
      ),
      media: SeriesMedia(
        posterUrl: "assets/banners/film1.jpg",
        bannerUrl: "assets/banners/film1.jpg",
        trailerUrl: "",
      ),
      stats: SeriesStats(
        views: 1000,
        likes: 100,
        comments: 10,
        rating: 4.0,
        publicationHistory: [PublicationEvent("Test", DateTime.now())],
        recentComments: [
          SeriesComment("Testeur", "Commentaire test", DateTime.now()),
        ],
      ),
      seasons: [],
    ),
  ];

  bool _areFiltersVisible = false;
  int _selectedSeriesIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchBar(context),
        if (_areFiltersVisible) _buildFiltersSection(context),
        Expanded(
          child: ListView.builder(
            itemCount: seriesList.length,
            itemBuilder: (context, index) =>
                _buildSeriesCard(context, seriesList[index], index),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: "Rechercher une série...",
                prefixIcon: Icon(Icons.search, color: AppTheme.primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    AppTheme.borderRadiusMedium,
                  ),
                ),
                filled: true,
                fillColor: AppTheme.cardBackground,
              ),
              style: TextStyle(color: AppTheme.textPrimary),
            ),
          ),
          IconButton(
            icon: Icon(Icons.filter_alt, color: AppTheme.primary),
            onPressed: () {
              setState(() {
                _areFiltersVisible = !_areFiltersVisible;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
      ),
      child: Column(
        children: [
          Text(
            "Filtres à implémenter",
            style: TextStyle(color: AppTheme.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildSeriesCard(BuildContext context, Series series, int index) {
    final publishedEpisodes = series.totalEpisodes
        .where((e) => e.status == "Publié")
        .length;
    final totalEpisodes = series.totalEpisodes.length;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      color: AppTheme.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        onTap: () => _showSeriesDetails(context, series, index),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppTheme.borderRadiusMedium),
              ),
              child: Image.asset(
                series.media.bannerUrl,
                height: 150,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 150,
                  color: Colors.grey[200],
                  child: Center(
                    child: Icon(
                      Icons.live_tv,
                      size: 50,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          series.title,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      _buildStatusBadge(context, series.status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _buildMetaChip(
                        Icons.calendar_today,
                        '${series.releaseYear}',
                      ),
                      _buildMetaChip(Icons.language, series.language),
                      _buildMetaChip(Icons.place, series.country),
                      ...series.genres.map(
                        (genre) => _buildMetaChip(Icons.category, genre),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildStatsRow(series, publishedEpisodes, totalEpisodes),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, String status) {
    Color color;
    String statusText;

    switch (status) {
      case 'Publié':
        color = AppTheme.success;
        statusText = 'Publié';
        break;
      case 'En attente':
        color = AppTheme.warning;
        statusText = 'En attente';
        break;
      case 'Rejeté':
        color = AppTheme.error;
        statusText = 'Rejeté';
        break;
      default:
        color = AppTheme.disabled;
        statusText = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildMetaChip(IconData icon, String text) {
    return Chip(
      avatar: Icon(icon, size: 16, color: AppTheme.primary),
      label: Text(text, style: TextStyle(color: AppTheme.textPrimary)),
      backgroundColor: AppTheme.cardBackground,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildStatsRow(
    Series series,
    int publishedEpisodes,
    int totalEpisodes,
  ) {
    final formatter = NumberFormat.compact();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem(
          Icons.remove_red_eye,
          formatter.format(series.stats.views),
        ),
        _buildStatItem(Icons.thumb_up, formatter.format(series.stats.likes)),
        _buildStatItem(Icons.comment, formatter.format(series.stats.comments)),
        _buildStatItem(Icons.star, series.stats.rating.toString()),
        _buildStatItem(
          Icons.playlist_play,
          '$publishedEpisodes/$totalEpisodes',
        ),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, String value) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppTheme.primary),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: AppTheme.textPrimary)),
      ],
    );
  }

  void _showSeriesDetails(BuildContext context, Series series, int index) {
    setState(() {
      _selectedSeriesIndex = index;
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SeriesDetailsModal(
        series: seriesList[_selectedSeriesIndex],
        onAddSeason: _showAddSeasonDialog,
        onAddEpisode: _showAddEpisodeDialog,
      ),
    );
  }

  void _showAddSeasonDialog() {
    final nextSeasonNumber = seriesList[_selectedSeriesIndex].seasons.isEmpty
        ? 1
        : seriesList[_selectedSeriesIndex].seasons.last.number + 1;

    showDialog(
      context: context,
      builder: (context) => season_modal.AddSeasonModal(
        nextSeasonNumber: nextSeasonNumber,
        onAddSeason:
            (title, description, posterPath, bannerPath, trailerPath) =>
                _addSeason(
                  title: title,
                  description: description,
                  posterPath: posterPath,
                  bannerPath: bannerPath,
                  trailerPath: trailerPath,
                  seasonNumber: nextSeasonNumber,
                ),
      ),
    ).then((_) {
      setState(() {});
    });
  }

  void _showAddEpisodeDialog(int seasonNumber) {
    showDialog(
      context: context,
      builder: (context) => episode_modal.AddEpisodeModal(
        seasonNumber: seasonNumber,
        onAddEpisode: (title, description, duration, videoPath) => _addEpisode(
          seasonNumber,
          title: title,
          description: description,
          duration: duration,
          videoPath: videoPath,
        ),
      ),
    ).then((_) {
      setState(() {});
    });
  }

  void _addSeason({
    required String title,
    required String description,
    required String posterPath,
    required String bannerPath,
    required String trailerPath,
    required int seasonNumber,
  }) {
    setState(() {
      seriesList[_selectedSeriesIndex].seasons.add(
        Season(
          number: seasonNumber,
          title: title,
          description: description,
          posterUrl: posterPath.isNotEmpty
              ? posterPath
              : 'assets/placeholder_poster.jpg',
          bannerUrl: bannerPath.isNotEmpty
              ? bannerPath
              : 'assets/placeholder_banner.jpg',
          trailerUrl: trailerPath.isNotEmpty ? trailerPath : '',
          episodes: [],
        ),
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Saison $seasonNumber ajoutée avec succès!'),
        backgroundColor: AppTheme.success,
      ),
    );
  }

  void _addEpisode(
    int seasonNumber, {
    String title = '',
    String description = '',
    int duration = 0,
    String videoPath = '',
  }) {
    setState(() {
      final season = seriesList[_selectedSeriesIndex].seasons.firstWhere(
        (s) => s.number == seasonNumber,
      );

      final episodes = season.episodes;
      final newEpisodeNumber = episodes.isEmpty ? 1 : episodes.last.number + 1;

      season.episodes.add(
        Episode(
          number: newEpisodeNumber,
          title: title.isNotEmpty ? title : 'Épisode $newEpisodeNumber',
          description: description.isNotEmpty
              ? description
              : 'Description à compléter',
          duration: duration,
          status: "En attente",
          releaseDate: DateTime.now(),
          videoUrl: videoPath,
          thumbnailUrl: '',
          views: 0,
        ),
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Épisode ajouté avec succès à la saison $seasonNumber!'),
        backgroundColor: AppTheme.success,
      ),
    );
  }
}
