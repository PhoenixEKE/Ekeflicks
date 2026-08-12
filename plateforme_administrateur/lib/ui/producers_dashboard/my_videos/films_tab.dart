import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:plateforme_administrateur/core/core.dart';
import 'package:plateforme_administrateur/gen/app_localizations.dart';

class FilmsTab extends StatefulWidget {
  const FilmsTab({super.key});

  @override
  State<FilmsTab> createState() => _FilmsTabState();
}

class _FilmsTabState extends State<FilmsTab> {
  final List<Film> films = [
    Film(
      title: "Le Dernier Voyage",
      description: "Un thriller psychologique explorant les limites de la réalité virtuelle.",
      genres: ["Thriller", "Science-Fiction"],
      language: "Français",
      releaseYear: 2023,
      duration: 102,
      country: "France",
      status: "Publié",
      team: FilmTeam(
        director: "Jean Dupont",
        screenwriter: "Marie Lambert",
        producers: ["CinéFrance Productions"],
        actors: {
          "Thomas Durand": "Alex",
          "Sophie Marceau": "Dr. Leroy"
        },
      ),
      media: FilmMedia(
        videoUrl: "videos/film1.mp4",
        posterUrl: "assets/posters/film1.jpg",
        bannerUrl: "assets/banners/film1.jpg",
        trailerUrl: "videos/trailer1.mp4",
      ),
      stats: FilmStats(
        views: 12500,
        likes: 843,
        comments: 127,
        rating: 4.2,
        publicationHistory: [
          PublicationEvent("Soumission", DateTime(2023, 9, 15)),
          PublicationEvent("Validation", DateTime(2023, 9, 18)),
          PublicationEvent("Publication", DateTime(2023, 10, 1)),
        ],
        recentComments: [
          FilmComment("User123", "Excellent film, je recommande !", DateTime(2023, 10, 5)),
          FilmComment("Cinéphile22", "La fin m'a surpris", DateTime(2023, 10, 4)),
        ],
      ),
      metadata: FilmMetadata(
        resolution: "1080p",
        format: "MP4",
        codec: "H.264",
        subtitles: ["assets/subs/film1_fr.srt", "assets/subs/film1_en.vtt"],
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchBar(context),
        Expanded(
          child: ListView.builder(
            itemCount: films.length,
            itemBuilder: (context, index) => _buildFilmCard(context, films[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.paddingMedium),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: AppDecorations.inputDecoration.copyWith(
                hintText: AppLocalizations.of(context)!.searchFilmHint,
                prefixIcon: Icon(Icons.search, color: AppTheme.primary),
              ),
              style: TextStyle(color: AppTheme.textPrimary),
            ),
          ),
          IconButton(
            icon: Icon(Icons.filter_alt, color: AppTheme.primary),
            onPressed: _showFilters,
          ),
        ],
      ),
    );
  }

  Widget _buildFilmCard(BuildContext context, Film film) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.paddingMedium,
        vertical: AppTheme.paddingSmall,
      ),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
      ),
      color: AppTheme.cardBackground,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        onTap: () => _showFilmDetails(context, film),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppTheme.borderRadiusMedium),
              ),
              child: Image.asset(
                film.media.bannerUrl,
                height: 150,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 150,
                  color: Colors.grey[200],
                  child: Center(
                    child: Center(child: Icon(Icons.live_tv, size: 50, color: AppTheme.primary)),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppTheme.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          film.title,
                          style: AppTheme.textTitle,
                        ),
                      ),
                      _buildStatusBadge(context, film.status),
                    ],
                  ),
                  const SizedBox(height: AppTheme.paddingSmall),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _buildMetaChip(Icons.calendar_today, '${film.releaseYear}'),
                      _buildMetaChip(Icons.language, film.language),
                      _buildMetaChip(Icons.timer, '${film.duration} ${AppLocalizations.of(context)!.minutesLabel}'),
                      _buildMetaChip(Icons.place, film.country),
                      ...film.genres.map((genre) => _buildMetaChip(Icons.category, genre)),
                    ],
                  ),
                  const SizedBox(height: AppTheme.paddingMedium),
                  _buildStatsRow(context, film),
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
      case 'En attente': 
        color = AppTheme.warning;
        statusText = AppLocalizations.of(context)!.pendingStatus;
      case 'Rejeté': 
        color = AppTheme.error;
        statusText = AppLocalizations.of(context)!.rejectedStatus;
      default: 
        color = AppTheme.disabled;
        statusText = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.paddingSmall,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: AppTheme.fontSizeSmall,
        ),
      ),
    );
  }

  Widget _buildMetaChip(IconData icon, String text) {
    return Chip(
      avatar: Icon(icon, size: 16, color: AppTheme.textSecondary),
      label: Text(
        text,
        style: TextStyle(color: AppTheme.textPrimary),
      ),
      backgroundColor: AppTheme.background,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildStatsRow(BuildContext context, Film film) {
    final formatter = NumberFormat.compact();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem(Icons.remove_red_eye, formatter.format(film.stats.views)),
        _buildStatItem(Icons.thumb_up, formatter.format(film.stats.likes)),
        _buildStatItem(Icons.comment, formatter.format(film.stats.comments)),
        _buildStatItem(Icons.star, film.stats.rating.toString()),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, String value) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppTheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(color: AppTheme.textPrimary),
        ),
      ],
    );
  }

  void _showFilmDetails(BuildContext context, Film film) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilmDetailsModal(film: film),
    );
  }

  void _showFilters() {
    // Implémentation des filtres
  }
}

class Film {
  final String title;
  final String description;
  final List<String> genres;
  final String language;
  final int releaseYear;
  final int duration;
  final String country;
  final String status;
  final FilmTeam team;
  final FilmMedia media;
  final FilmStats stats;
  final FilmMetadata metadata;

  Film({
    required this.title,
    required this.description,
    required this.genres,
    required this.language,
    required this.releaseYear,
    required this.duration,
    required this.country,
    required this.status,
    required this.team,
    required this.media,
    required this.stats,
    required this.metadata,
  });
}

class FilmTeam {
  final String director;
  final String screenwriter;
  final List<String> producers;
  final Map<String, String> actors;

  FilmTeam({
    required this.director,
    required this.screenwriter,
    required this.producers,
    required this.actors,
  });
}

class FilmMedia {
  final String videoUrl;
  final String posterUrl;
  final String bannerUrl;
  final String trailerUrl;

  FilmMedia({
    required this.videoUrl,
    required this.posterUrl,
    required this.bannerUrl,
    required this.trailerUrl,
  });
}

class FilmStats {
  final int views;
  final int likes;
  final int comments;
  final double rating;
  final List<PublicationEvent> publicationHistory;
  final List<FilmComment> recentComments;

  FilmStats({
    required this.views,
    required this.likes,
    required this.comments,
    required this.rating,
    required this.publicationHistory,
    required this.recentComments,
  });
}

class FilmMetadata {
  final String resolution;
  final String format;
  final String codec;
  final List<String> subtitles;

  FilmMetadata({
    required this.resolution,
    required this.format,
    required this.codec,
    required this.subtitles,
  });
}

class PublicationEvent {
  final String action;
  final DateTime date;

  PublicationEvent(this.action, this.date);
}

class FilmComment {
  final String username;
  final String text;
  final DateTime date;

  FilmComment(this.username, this.text, this.date);
}

class FilmDetailsModal extends StatelessWidget {
  final Film film;

  const FilmDetailsModal({super.key, required this.film});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppTheme.borderRadiusLarge),
          ),
        ),
        child: CustomScrollView(
          controller: controller,
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              flexibleSpace: FlexibleSpaceBar(
                background: Image.asset(
                  film.media.bannerUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppTheme.cardBackground,
                    child: Center(
                      child: Center(child: Icon(Icons.live_tv, size: 50, color: AppTheme.primary)),
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.paddingMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            film.title,
                            style: AppTheme.textTitle,
                          ),
                        ),
                        _buildStatusBadge(context, film.status),
                      ],
                    ),
                    const SizedBox(height: AppTheme.paddingLarge),
                    _buildSection(AppLocalizations.of(context)!.synopsisTitle, film.description),
                    _buildSectionTitle(AppLocalizations.of(context)!.informationTitle),
                    _buildInfoTable(context, film),
                    const SizedBox(height: AppTheme.paddingLarge),
                    _buildSectionTitle(AppLocalizations.of(context)!.teamTitle),
                    _buildTeamSection(context, film.team),
                    const SizedBox(height: AppTheme.paddingLarge),
                    _buildSectionTitle(AppLocalizations.of(context)!.statsTitle),
                    _buildStatsSection(context, film.stats),
                    const SizedBox(height: AppTheme.paddingLarge),
                    _buildSectionTitle(AppLocalizations.of(context)!.commentsTitle),
                    _buildCommentsSection(film.stats.recentComments),
                    const SizedBox(height: AppTheme.paddingLarge),
                    _buildSectionTitle(AppLocalizations.of(context)!.metadataTitle),
                    _buildMetadataSection(context, film.metadata),
                    const SizedBox(height: AppTheme.paddingLarge),
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
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        const SizedBox(height: AppTheme.paddingMedium),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.paddingSmall),
      child: Text(
        title,
        style: AppTheme.textSubtitle.copyWith(
          fontWeight: FontWeight.bold,
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
      case 'En attente': 
        color = AppTheme.warning;
        statusText = AppLocalizations.of(context)!.pendingStatus;
      case 'Rejeté': 
        color = AppTheme.error;
        statusText = AppLocalizations.of(context)!.rejectedStatus;
      default: 
        color = AppTheme.disabled;
        statusText = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.paddingMedium,
        vertical: AppTheme.paddingSmall,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoTable(BuildContext context, Film film) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(1),
        1: FlexColumnWidth(2),
      },
      children: [
        _buildTableRow(context, AppLocalizations.of(context)!.genresLabel, film.genres.join(', ')),
        _buildTableRow(context, AppLocalizations.of(context)!.languageLabel, film.language),
        _buildTableRow(context, AppLocalizations.of(context)!.yearLabel, film.releaseYear.toString()),
        _buildTableRow(context, AppLocalizations.of(context)!.durationLabel, '${film.duration} ${AppLocalizations.of(context)!.minutesLabel}'),
        _buildTableRow(context, AppLocalizations.of(context)!.countryLabel, film.country),
      ],
    );
  }

  TableRow _buildTableRow(BuildContext context, String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppTheme.paddingSmall),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppTheme.paddingSmall),
          child: Text(
            value,
            style: TextStyle(color: AppTheme.textPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildTeamSection(BuildContext context, FilmTeam team) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTeamItem(context, AppLocalizations.of(context)!.directorLabel, team.director),
        _buildTeamItem(context, AppLocalizations.of(context)!.screenwriterLabel, team.screenwriter),
        _buildTeamItem(context, AppLocalizations.of(context)!.producersLabel, team.producers.join(', ')),
        const SizedBox(height: AppTheme.paddingMedium),
        Text(
          AppLocalizations.of(context)!.mainActorsLabel,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        ...team.actors.entries.map((e) => Padding(
          padding: const EdgeInsets.symmetric(vertical: AppTheme.paddingSmall),
          child: Text(
            '• ${e.key} : ${e.value}',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        )),
      ],
    );
  }

  Widget _buildTeamItem(BuildContext context, String role, String name) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.paddingSmall),
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style.copyWith(
                color: AppTheme.textPrimary,
              ),
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

  Widget _buildStatsSection(BuildContext context, FilmStats stats) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppTheme.paddingMedium,
          runSpacing: AppTheme.paddingSmall,
          children: [
            _buildStatCard(AppLocalizations.of(context)!.viewsLabel, stats.views.toString()),
            _buildStatCard(AppLocalizations.of(context)!.likesLabel, stats.likes.toString()),
            _buildStatCard(AppLocalizations.of(context)!.commentsLabel, stats.comments.toString()),
            _buildStatCard(AppLocalizations.of(context)!.ratingLabel, stats.rating.toString()),
          ],
        ),
        const SizedBox(height: AppTheme.paddingMedium),
        Text(
          AppLocalizations.of(context)!.publicationHistoryLabel,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        ...stats.publicationHistory.map((e) => Padding(
          padding: const EdgeInsets.symmetric(vertical: AppTheme.paddingSmall),
          child: Text(
            '• ${e.action} : ${dateFormat.format(e.date)}',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        )),
      ],
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Card(
      color: AppTheme.background,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingMedium),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: AppTheme.fontSizeSmall,
                color: AppTheme.textSecondary,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: AppTheme.fontSizeLarge,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsSection(List<FilmComment> comments) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    return Column(
      children: comments.take(10).map((comment) => Card(
        color: AppTheme.background,
        margin: const EdgeInsets.only(bottom: AppTheme.paddingSmall),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    comment.username,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    dateFormat.format(comment.date),
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: AppTheme.fontSizeSmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.paddingSmall),
              Text(
                comment.text,
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildMetadataSection(BuildContext context, FilmMetadata metadata) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMetadataItem(context, AppLocalizations.of(context)!.resolutionLabel, metadata.resolution),
        _buildMetadataItem(context, AppLocalizations.of(context)!.formatLabel, metadata.format),
        _buildMetadataItem(context, AppLocalizations.of(context)!.codecLabel, metadata.codec),
        const SizedBox(height: AppTheme.paddingMedium),
        Text(
          AppLocalizations.of(context)!.availableSubtitlesLabel,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        ...metadata.subtitles.map((sub) => Padding(
          padding: const EdgeInsets.symmetric(vertical: AppTheme.paddingSmall),
          child: Text(
            '• $sub',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        )),
      ],
    );
  }

  Widget _buildMetadataItem(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.paddingSmall),
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style.copyWith(
                color: AppTheme.textPrimary,
              ),
          children: [
            TextSpan(
              text: '$label : ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            style: AppDecorations.elevatedButtonStyle.copyWith(
              backgroundColor: MaterialStateProperty.all(AppTheme.primary),
            ),
            onPressed: () {},
            icon: Icon(Icons.edit, color: AppTheme.textPrimary),
            label: Text(
              AppLocalizations.of(context)!.editButton,
              style: TextStyle(color: AppTheme.textPrimary),
            ),
          ),
        ),
        const SizedBox(width: AppTheme.paddingMedium),
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.textPrimary,
              side: BorderSide(color: AppTheme.textPrimary),
              padding: const EdgeInsets.symmetric(
                vertical: AppTheme.paddingMedium),
            ),
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close, color: AppTheme.textPrimary),
            label: Text(
              AppLocalizations.of(context)!.closeButton,
              style: TextStyle(color: AppTheme.textPrimary),
            ),
          ),
        ),
      ],
    );
  }
}
