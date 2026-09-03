import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:plateforme_producteurs/core/core.dart';
import 'package:plateforme_producteurs/models/series_models.dart';

class SeriesDetailsModal extends StatefulWidget {
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
  State<SeriesDetailsModal> createState() => _SeriesDetailsModalState();
}

class _SeriesDetailsModalState extends State<SeriesDetailsModal> {
  late Series _currentSeries;

  @override
  void initState() {
    super.initState();
    _currentSeries = widget.series;
  }

  @override
  void didUpdateWidget(SeriesDetailsModal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.series != oldWidget.series) {
      setState(() {
        _currentSeries = widget.series;
      });
    }
  }

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
                background: Stack(
                  children: [
                    Image.asset(
                      _currentSeries.media.bannerUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppTheme.cardBackground,
                        child: Center(
                          child: Icon(
                            Icons.live_tv,
                            size: 50,
                            color: AppTheme.primary,
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
                            Colors.black.withValues(alpha: 0.7),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderSection(context),
                    const SizedBox(height: 16),
                    _buildSynopsisSection(context),
                    const SizedBox(height: 16),
                    _buildInformationSection(context),
                    const SizedBox(height: 16),
                    _buildTeamSection(context),
                    const SizedBox(height: 16),
                    _buildStatsSection(context),
                    const SizedBox(height: 16),
                    _buildSeasonsSection(context),
                    const SizedBox(height: 16),
                    _buildCommentsSection(context),
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

  Widget _buildHeaderSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _currentSeries.title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            _buildStatusBadge(context, _currentSeries.status),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            _buildMetaChip(
              Icons.calendar_today,
              '${_currentSeries.releaseYear}',
            ),
            _buildMetaChip(Icons.language, _currentSeries.language),
            _buildMetaChip(Icons.place, _currentSeries.country),
            ..._currentSeries.genres.map(
              (genre) => _buildMetaChip(Icons.category, genre),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSynopsisSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Synopsis',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _currentSeries.description,
          style: TextStyle(color: AppTheme.textSecondary, height: 1.6),
        ),
      ],
    );
  }

  Widget _buildInformationSection(BuildContext context) {
    return ExpansionTile(
      title: Text(
        'Informations',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimary,
        ),
      ),
      children: [
        Table(
          columnWidths: const {0: FlexColumnWidth(1), 1: FlexColumnWidth(2)},
          children: [
            _buildTableRow('Genres', _currentSeries.genres.join(', ')),
            _buildTableRow('Langue', _currentSeries.language),
            _buildTableRow('Année', _currentSeries.releaseYear.toString()),
            _buildTableRow('Pays', _currentSeries.country),
          ],
        ),
      ],
    );
  }

  Widget _buildTeamSection(BuildContext context) {
    return ExpansionTile(
      title: Text(
        'Équipe',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimary,
        ),
      ),
      children: [
        _buildTeamItem('Réalisateur', _currentSeries.team.director),
        _buildTeamItem('Scénariste', _currentSeries.team.screenwriter),
        _buildTeamItem('Producteurs', _currentSeries.team.producers.join(', ')),
        const SizedBox(height: 12),
        Text(
          'Acteurs principaux',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        ..._currentSeries.team.actors.entries.map(
          (e) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Text(
              '• ${e.key} : ${e.value}',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final formatter = NumberFormat.compact();

    return ExpansionTile(
      title: Text(
        'Statistiques',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimary,
        ),
      ),
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            _buildStatCard(
              'Vues',
              formatter.format(_currentSeries.stats.views),
            ),
            _buildStatCard(
              'J\'aime',
              formatter.format(_currentSeries.stats.likes),
            ),
            _buildStatCard(
              'Commentaires',
              formatter.format(_currentSeries.stats.comments),
            ),
            _buildStatCard('Note', _currentSeries.stats.rating.toString()),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Historique de publication',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        ..._currentSeries.stats.publicationHistory.map(
          (e) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Text(
              '• ${e.action} : ${dateFormat.format(e.date)}',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSeasonsSection(BuildContext context) {
    final publishedEpisodes = _currentSeries.totalEpisodes
        .where((e) => e.status == "Publié")
        .length;
    final totalEpisodes = _currentSeries.totalEpisodes.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Saisons et Épisodes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const Spacer(),
            Text(
              '$publishedEpisodes/$totalEpisodes épisodes',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (widget.onAddSeason != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: ElevatedButton.icon(
              icon: Icon(Icons.add, color: AppTheme.textPrimary),
              label: Text('Ajouter une saison'),
              onPressed: () {
                widget.onAddSeason?.call();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: AppTheme.textPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ),

        if (_currentSeries.seasons.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(Icons.tv, size: 48, color: AppTheme.textSecondary),
                const SizedBox(height: 12),
                Text(
                  'Aucune saison disponible',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Commencez par ajouter votre première saison',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ..._currentSeries.seasons.map(
            (season) => _buildSeasonCard(context, season),
          ),
      ],
    );
  }

  Widget _buildSeasonCard(BuildContext context, Season season) {
    final publishedEpisodes = season.episodes
        .where((e) => e.status == "Publié")
        .length;
    final totalEpisodes = season.episodes.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppTheme.cardBackground,
      child: ExpansionTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            season.posterUrl,
            width: 40,
            height: 40,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 40,
              height: 40,
              color: AppTheme.primary.withValues(alpha: 0.1),
              child: Icon(Icons.tv, color: AppTheme.primary, size: 20),
            ),
          ),
        ),
        title: Text(
          season.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$totalEpisodes épisodes • $publishedEpisodes publiés',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
            if (season.description.isNotEmpty)
              Text(
                season.description,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        children: [
          // Section informations de la saison
          if (season.description.isNotEmpty || season.trailerUrl.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (season.description.isNotEmpty) ...[
                    Text(
                      'Description:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      season.description,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (season.trailerUrl.isNotEmpty)
                    Row(
                      children: [
                        Icon(
                          Icons.play_circle_outline,
                          color: AppTheme.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Bande-annonce disponible',
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

          // Bouton ajouter épisode
          if (widget.onAddEpisode != null)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  icon: Icon(Icons.add, size: 18),
                  label: Text('Ajouter un épisode'),
                  onPressed: () {
                    widget.onAddEpisode?.call(season.number);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: AppTheme.textPrimary,
                  ),
                ),
              ),
            ),

          // Liste des épisodes
          if (season.episodes.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppTheme.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Aucun épisode dans cette saison',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            ...season.episodes.map(
              (episode) => _buildEpisodeTile(context, episode),
            ),
        ],
      ),
    );
  }

  Widget _buildEpisodeTile(BuildContext context, Episode episode) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.cardBackground, width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Container(
            width: 60,
            height: 40,
            color: AppTheme.primary.withValues(alpha: 0.1),
            child: episode.thumbnailUrl.isNotEmpty
                ? Image.asset(
                    episode.thumbnailUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildEpisodePlaceholder(),
                  )
                : _buildEpisodePlaceholder(),
          ),
        ),
        title: Text(
          'Épisode ${episode.number} : ${episode.title}',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
            fontSize: 14,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              dateFormat.format(episode.releaseDate),
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
            if (episode.status == "Publié")
              Text(
                '${NumberFormat.compact().format(episode.views)} vues • ${episode.duration} min',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
            if (episode.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                episode.description,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: _buildEpisodeStatusChip(context, episode.status),
        onTap: () {
          if (episode.videoUrl.isNotEmpty) {
            _showVideoPlayer(context, episode);
          }
        },
      ),
    );
  }

  Widget _buildEpisodePlaceholder() {
    return Center(
      child: Icon(
        Icons.play_circle_outline,
        color: AppTheme.textSecondary,
        size: 24,
      ),
    );
  }

  void _showVideoPlayer(BuildContext context, Episode episode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: Text(
          episode.title,
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Lecture de l\'épisode ${episode.number}',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.play_circle_filled,
                      color: Colors.white,
                      size: 50,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Épisode ${episode.number}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      episode.title,
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            if (episode.description.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                episode.description,
                style: TextStyle(color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fermer', style: TextStyle(color: AppTheme.primary)),
          ),
          ElevatedButton(
            onPressed: () {
              // Action pour lire la vidéo
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: AppTheme.textPrimary,
            ),
            child: Text('Lire la vidéo'),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsSection(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final comments = _currentSeries.stats.recentComments;

    if (comments.isEmpty) {
      return const SizedBox.shrink();
    }

    return ExpansionTile(
      title: Text(
        'Commentaires récents',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimary,
        ),
      ),
      children: comments
          .take(5)
          .map(
            (comment) => Card(
              color: AppTheme.cardBackground,
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppTheme.primary,
                          radius: 16,
                          child: Text(
                            comment.username.substring(0, 1).toUpperCase(),
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            comment.username,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
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
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
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
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              _showEditSeriesDialog(context);
            },
            icon: Icon(Icons.edit, color: AppTheme.textPrimary),
            label: Text(
              'Modifier',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.textPrimary,
              side: BorderSide(color: AppTheme.textPrimary),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close, color: AppTheme.textPrimary),
            label: Text(
              'Fermer',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showEditSeriesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: Text(
          'Modifier la série',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: Text(
          'La fonctionnalité de modification arrive bientôt!',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fermer', style: TextStyle(color: AppTheme.primary)),
          ),
        ],
      ),
    );
  }

  // Méthodes helper
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
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
      label: Text(
        text,
        style: TextStyle(color: AppTheme.textPrimary, fontSize: 12),
      ),
      backgroundColor: AppTheme.cardBackground,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Card(
      color: AppTheme.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
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

  Widget _buildEpisodeStatusChip(BuildContext context, String status) {
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

    return Chip(
      label: Text(
        statusText,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: color.withValues(alpha: 0.2),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  TableRow _buildTableRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Text(value, style: TextStyle(color: AppTheme.textPrimary)),
        ),
      ],
    );
  }

  Widget _buildTeamItem(String role, String name) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$role :',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(name, style: TextStyle(color: AppTheme.textPrimary)),
          ),
        ],
      ),
    );
  }
}
