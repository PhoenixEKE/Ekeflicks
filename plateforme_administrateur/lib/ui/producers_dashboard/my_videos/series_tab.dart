import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'add_episode_modal.dart';
import 'add_season_modal.dart';
import 'package:plateforme_administrateur/core/core.dart';
import 'package:plateforme_administrateur/gen/app_localizations.dart';

class Series {
  final String title;
  final String description;
  final List<String> genres;
  final String language;
  final int releaseYear;
  final String country;
  final String status;
  final ProductionTeam team;
  final SeriesMedia media;
  final SeriesStats stats;
  final List<Season> seasons;

  Series({
    required this.title,
    required this.description,
    required this.genres,
    required this.language,
    required this.releaseYear,
    required this.country,
    required this.status,
    required this.team,
    required this.media,
    required this.stats,
    required this.seasons,
  });

  List<Episode> get totalEpisodes {
    return seasons.expand((season) => season.episodes).toList();
  }
}

class Season {
  final int number;
  final String title;
  final List<Episode> episodes;

  Season({
    required this.number,
    required this.title,
    required this.episodes,
  });
}

class Episode {
  final int number;
  final String title;
  final String description;
  final int duration;
  final String status;
  final DateTime releaseDate;
  final String videoUrl;
  final String thumbnailUrl;
  final int views;

  Episode({
    required this.number,
    required this.title,
    required this.description,
    required this.duration,
    required this.status,
    required this.releaseDate,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.views,
  });
}

class ProductionTeam {
  final String director;
  final String screenwriter;
  final List<String> producers;
  final Map<String, String> actors;

  ProductionTeam({
    required this.director,
    required this.screenwriter,
    required this.producers,
    required this.actors,
  });
}

class SeriesMedia {
  final String posterUrl;
  final String bannerUrl;
  final String trailerUrl;

  SeriesMedia({
    required this.posterUrl,
    required this.bannerUrl,
    required this.trailerUrl,
  });
}

class SeriesStats {
  final int views;
  final int likes;
  final int comments;
  final double rating;
  final List<PublicationEvent> publicationHistory;
  final List<SeriesComment> recentComments;

  SeriesStats({
    required this.views,
    required this.likes,
    required this.comments,
    required this.rating,
    required this.publicationHistory,
    required this.recentComments,
  });
}

class PublicationEvent {
  final String action;
  final DateTime date;

  PublicationEvent(this.action, this.date);
}

class SeriesComment {
  final String username;
  final String text;
  final DateTime date;

  SeriesComment(this.username, this.text, this.date);
}

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
        posterUrl: "",
        bannerUrl: "",
        trailerUrl: "",
      ),
      stats: SeriesStats(
        views: 1000,
        likes: 100,
        comments: 10,
        rating: 4.0,
        publicationHistory: [
          PublicationEvent("Test", DateTime.now()),
        ],
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
    return Theme(
      data: AppTheme.themeData,
      child: Column(
        children: [
          _buildSearchBar(context),
          if (_areFiltersVisible) _buildFiltersSection(context),
          Expanded(
            child: ListView.builder(
              itemCount: seriesList.length,
              itemBuilder: (context, index) => _buildSeriesCard(context, seriesList[index], index),
            ),
          ),
        ],
      ),
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
                hintText: AppLocalizations.of(context)!.searchSeriesHint,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                ),
                filled: true,
                fillColor: AppTheme.cardBackground,
              ),
              style: const TextStyle(color: AppTheme.textPrimary),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.filter_alt),
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
            AppLocalizations.of(context)!.filtersToImplement,
            style: const TextStyle(color: AppTheme.textPrimary)
          ),
        ],
      ),
    );
  }

  Widget _buildSeriesCard(BuildContext context, Series series, int index) {
    final publishedEpisodes = series.totalEpisodes.where((e) => e.status == "Publié").length;
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
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.borderRadiusMedium)),
              child: Image.asset(
                series.media.bannerUrl,
                height: 150,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 150,
                  color: Colors.grey[200],
                  child: Center(child: Icon(Icons.live_tv, size: 50, color: AppTheme.primary)),
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
                          style: const TextStyle(
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
                      _buildMetaChip(Icons.calendar_today, '${series.releaseYear}'),
                      _buildMetaChip(Icons.language, series.language),
                      _buildMetaChip(Icons.place, series.country),
                      ...series.genres.map((genre) => _buildMetaChip(Icons.category, genre)),
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
        statusText = AppLocalizations.of(context)!.publishedStatus;
        break;
      case 'En attente': 
        color = AppTheme.warning;
        statusText = AppLocalizations.of(context)!.pendingStatus;
        break;
      case 'Rejeté': 
        color = AppTheme.error;
        statusText = AppLocalizations.of(context)!.rejectedStatus;
        break;
      default: 
        color = AppTheme.grey;
        statusText = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
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
      label: Text(text, style: const TextStyle(color: AppTheme.textPrimary)),
      backgroundColor: AppTheme.cardBackground,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildStatsRow(Series series, int publishedEpisodes, int totalEpisodes) {
    final formatter = NumberFormat.compact();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem(Icons.remove_red_eye, formatter.format(series.stats.views)),
        _buildStatItem(Icons.thumb_up, formatter.format(series.stats.likes)),
        _buildStatItem(Icons.comment, formatter.format(series.stats.comments)),
        _buildStatItem(Icons.star, series.stats.rating.toString()),
        _buildStatItem(Icons.playlist_play, '$publishedEpisodes/$totalEpisodes'),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, String value) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppTheme.primary),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: AppTheme.textPrimary)),
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
        series: series,
        onAddSeason: _showAddSeasonDialog,
        onAddEpisode: _showAddEpisodeDialog,
      ),
    );
  }

  void _showAddSeasonDialog() {
    showDialog(
      context: context,
      builder: (context) => AddSeasonModal(
        onAddSeason: (title) => _addSeason(title),
      ),
    );
  }

  void _showAddEpisodeDialog(int seasonNumber) {
    showDialog(
      context: context,
      builder: (context) => AddEpisodeModal(
        seasonNumber: seasonNumber,
        onAddEpisode: (title, description, duration, videoPath) => _addEpisode(
          seasonNumber,
          title: title,
          description: description,
          duration: duration,
          videoPath: videoPath,
        ),
      ),
    );
  }

  void _addSeason([String? title]) {
    setState(() {
      final seasons = seriesList[_selectedSeriesIndex].seasons;
      final newSeasonNumber = seasons.isEmpty ? 1 : seasons.last.number + 1;
      
      seriesList[_selectedSeriesIndex].seasons.add(
        Season(
          number: newSeasonNumber,
          title: title ?? '${AppLocalizations.of(context)!.seasonLabel} $newSeasonNumber',
          episodes: [],
        ),
      );
    });
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
          title: title.isNotEmpty ? title : '${AppLocalizations.of(context)!.episodeLabel} $newEpisodeNumber',
          description: description.isNotEmpty ? description : AppLocalizations.of(context)!.descriptionToComplete,
          duration: duration,
          status: AppLocalizations.of(context)!.pendingStatus,
          releaseDate: DateTime.now(),
          videoUrl: videoPath,
          thumbnailUrl: '',
          views: 0,
        ),
      );
    });
  }
}

class SeriesDetailsModal extends StatelessWidget {
  final Series series;
  final VoidCallback? onAddSeason;
  final Function(int)? onAddEpisode;

  const SeriesDetailsModal({
    super.key, 
    required this.series,
    this.onAddSeason,
    this.onAddEpisode,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: CustomScrollView(
          controller: controller,
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              flexibleSpace: FlexibleSpaceBar(
                background: Image.asset(
                  series.media.bannerUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppTheme.cardBackground,
                    child: Center(child: Icon(Icons.live_tv, size: 50, color: AppTheme.primary)),
                 ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            series.title,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: series.status == "Publié" 
                              ? AppTheme.success.withOpacity(0.2)
                              : AppTheme.warning.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                          ),
                          child: Text(
                            series.status == "Publié" 
                              ? AppLocalizations.of(context)!.publishedStatus
                              : AppLocalizations.of(context)!.pendingStatus,
                            style: TextStyle(
                              color: series.status == "Publié" 
                                ? AppTheme.success 
                                : AppTheme.warning,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSection(AppLocalizations.of(context)!.synopsisTitle, series.description),
                    _buildSectionTitle(AppLocalizations.of(context)!.informationTitle),
                    _buildInfoTable(context, series),
                    const SizedBox(height: 16),
                    _buildSectionTitle(AppLocalizations.of(context)!.teamTitle),
                    _buildTeamSection(context, series.team),
                    const SizedBox(height: 16),
                    _buildSectionTitle(AppLocalizations.of(context)!.statsTitle),
                    _buildStatsSection(context, series.stats),
                    const SizedBox(height: 16),
                    _buildSectionTitle(AppLocalizations.of(context)!.seasonsEpisodesTitle),
                    _buildSeasonsSection(context, series),
                    const SizedBox(height: 16),
                    _buildSectionTitle(AppLocalizations.of(context)!.commentsTitle),
                    _buildCommentsSection(series.stats.recentComments),
                    const SizedBox(height: 24),
                    _buildActionButtons(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(title),
        Text(
          content,
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _buildInfoTable(BuildContext context, Series series) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(1),
        1: FlexColumnWidth(2),
      },
      children: [
        _buildTableRow(context, AppLocalizations.of(context)!.genresLabel, series.genres.join(', ')),
        _buildTableRow(context, AppLocalizations.of(context)!.languageLabel, series.language),
        _buildTableRow(context, AppLocalizations.of(context)!.yearLabel, series.releaseYear.toString()),
        _buildTableRow(context, AppLocalizations.of(context)!.countryLabel, series.country),
      ],
    );
  }

  TableRow _buildTableRow(BuildContext context, String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Text(
            value,
            style: const TextStyle(color: AppTheme.textPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildTeamSection(BuildContext context, ProductionTeam team) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTeamItem(context, AppLocalizations.of(context)!.directorLabel, team.director),
        _buildTeamItem(context, AppLocalizations.of(context)!.screenwriterLabel, team.screenwriter),
        _buildTeamItem(context, AppLocalizations.of(context)!.producersLabel, team.producers.join(', ')),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.of(context)!.mainActorsLabel,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        ...team.actors.entries.map((e) => 
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Text(
              '• ${e.key} : ${e.value}',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTeamItem(BuildContext context, String role, String name) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style.copyWith(color: AppTheme.textPrimary),
          children: [
            TextSpan(
              text: '$role : ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: name),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context, SeriesStats stats) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            _buildStatCard(AppLocalizations.of(context)!.viewsLabel, stats.views.toString()),
            _buildStatCard(AppLocalizations.of(context)!.likesLabel, stats.likes.toString()),
            _buildStatCard(AppLocalizations.of(context)!.commentsLabel, stats.comments.toString()),
            _buildStatCard(AppLocalizations.of(context)!.ratingLabel, stats.rating.toString()),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          AppLocalizations.of(context)!.publicationHistoryLabel,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        ...stats.publicationHistory.map((e) => 
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Text(
              '• ${e.action} : ${dateFormat.format(e.date)}',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Card(
      color: AppTheme.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeasonsSection(BuildContext context, Series series) {
    return Column(
      children: [
        if (onAddSeason != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: Text(AppLocalizations.of(context)!.addSeasonButton),
              onPressed: onAddSeason,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: AppTheme.textPrimary,
              ),
            ),
          ),
        
        ...series.seasons.map((season) => ExpansionTile(
          leading: CircleAvatar(
            backgroundColor: AppTheme.primary,
            child: Text(
              'S${season.number}',
              style: const TextStyle(color: AppTheme.textPrimary),
            ),
          ),
          title: Text(
            season.title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          subtitle: Text(
            '${season.episodes.length} ${AppLocalizations.of(context)!.episodesLabel}',
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
          children: [
            if (onAddEpisode != null)
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: TextButton.icon(
                    icon: const Icon(Icons.add, color: AppTheme.primary),
                    label: Text(
                      AppLocalizations.of(context)!.addEpisodeButton,
                      style: const TextStyle(color: AppTheme.primary)
                    ),
                    onPressed: () => onAddEpisode!(season.number),
                  ),
                ),
              ),
            
            ...season.episodes.map((episode) => _buildEpisodeTile(context, episode)),
          ],
        )).toList(),
      ],
    );
  }

  Widget _buildEpisodeTile(BuildContext context, Episode episode) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
        child: Image.asset(
          episode.thumbnailUrl,
          width: 60,
          height: 40,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: 60,
            height: 40,
            color: AppTheme.cardBackground,
            child: Icon(Icons.play_circle_outline, color: AppTheme.textSecondary),
          ),
        ),
      ),
      title: Text(
        '${AppLocalizations.of(context)!.episodeLabel} ${episode.number} : ${episode.title}',
        style: const TextStyle(color: AppTheme.textPrimary),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dateFormat.format(episode.releaseDate),
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
          if (episode.status == "Publié")
            Text(
              '${NumberFormat.compact().format(episode.views)} ${AppLocalizations.of(context)!.viewsLabel}',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          const SizedBox(height: 4),
          Text(
            episode.description,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      trailing: _buildEpisodeStatusChip(context, episode.status),
      onTap: () {
        if (episode.videoUrl.isNotEmpty) {
          // Ajouter la logique pour lire la vidéo
        }
      },
    );
  }

  Widget _buildEpisodeStatusChip(BuildContext context, String status) {
    Color color;
    String statusText;
    
    switch (status) {
      case 'Publié': 
        color = AppTheme.success;
        statusText = AppLocalizations.of(context)!.publishedStatus;
        break;
      case 'En attente': 
        color = AppTheme.warning;
        statusText = AppLocalizations.of(context)!.pendingStatus;
        break;
      case 'Rejeté': 
        color = AppTheme.error;
        statusText = AppLocalizations.of(context)!.rejectedStatus;
        break;
      default: 
        color = AppTheme.grey;
        statusText = status;
    }

    return Chip(
      label: Text(
        statusText,
        style: TextStyle(color: color),
      ),
      backgroundColor: color.withOpacity(0.2),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildCommentsSection(List<SeriesComment> comments) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    return Column(
      children: comments.take(10).map((comment) => Card(
        color: AppTheme.cardBackground,
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    comment.username,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    dateFormat.format(comment.date),
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                comment.text,
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: AppTheme.textPrimary,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: () {},
            icon: const Icon(Icons.edit),
            label: Text(AppLocalizations.of(context)!.editButton),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.textPrimary,
              side: const BorderSide(color: AppTheme.textPrimary),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            label: Text(AppLocalizations.of(context)!.closeButton),
          ),
        ),
      ],
    );
  }
}
