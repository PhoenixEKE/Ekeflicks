/*modal films*/
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:plateforme_producteurs/core/core.dart';
import 'package:plateforme_producteurs/gen/app_localizations.dart';

class FilmsTab extends StatefulWidget {
  const FilmsTab({super.key});

  @override
  State<FilmsTab> createState() => _FilmsTabState();
}

class _FilmsTabState extends State<FilmsTab> {
  final List<Film> films = [
    Film(
      title: "Le Dernier Voyage",
      originalTitle: "The Last Journey",
      description:
          "Un thriller psychologique explorant les limites de la réalité virtuelle.",
      synopsis:
          "Alex, un développeur de réalité virtuelle, se retrouve piégé dans son propre programme. Alors qu'il tente de distinguer la réalité de la simulation, il découvre des secrets qui pourraient changer le cours de l'humanité.",
      genres: ["Thriller", "Science-Fiction"],
      language: "Français",
      originalLanguage: "Français",
      spokenLanguages: ["Français", "Anglais"],
      releaseYear: 2023,
      duration: 102,
      country: "France",
      productionCountries: ["France", "Canada"],
      status: "Publié",
      ageRating: "Tous publics",
      certification: "U",
      budget: 2500000,
      revenue: 8500000,
      team: FilmTeam(
        director: "Jean Dupont",
        screenwriter: "Marie Lambert",
        producers: ["CinéFrance Productions", "Québec Films"],
        cast: {
          "Thomas Durand": "Alex",
          "Sophie Marceau": "Dr. Leroy",
          "Pierre Richard": "Professeur Martin",
        },
        cinematographer: "Luc Besson",
        composer: "Yann Tiersen",
        editor: "Claire Petit",
      ),
      media: FilmMedia(
        videoUrl: "videos/film1.mp4",
        posterUrl: "assets/posters/film1.jpg",
        bannerUrl: "assets/banners/film1.jpg",
        trailerUrl: "videos/trailer1.mp4",
        gallery: [
          "assets/gallery/film1_1.jpg",
          "assets/gallery/film1_2.jpg",
          "assets/gallery/film1_3.jpg",
        ],
        logoUrl: "assets/logos/film1_logo.png",
      ),
      technicalInfo: FilmTechnicalInfo(
        resolution: "1080p",
        format: "MP4",
        codec: "H.264",
        audioCodec: "AAC",
        audioChannels: "5.1",
        fileSize: "4.2 GB",
        aspectRatio: "16:9",
        frameRate: "24 fps",
      ),
      subtitles: [
        SubtitleTrack("Français", "assets/subs/film1_fr.srt", false),
        SubtitleTrack("English", "assets/subs/film1_en.vtt", false),
        SubtitleTrack("Français (SDH)", "assets/subs/film1_fr_sdh.srt", true),
      ],
      audioTracks: [
        AudioTrack("Français", "AAC", "5.1", true),
        AudioTrack("English", "AC3", "5.1", false),
      ],
      videoQualities: [
        VideoQuality("480p", "videos/film1_480p.mp4", "1.2 GB"),
        VideoQuality("720p", "videos/film1_720p.mp4", "2.1 GB"),
        VideoQuality("1080p", "videos/film1_1080p.mp4", "4.2 GB"),
        VideoQuality("4K", "videos/film1_4k.mp4", "8.5 GB"),
      ],
      distributionRights: [
        DistributionRight("France", DateTime(2023, 1, 1), DateTime(2033, 1, 1)),
        DistributionRight(
          "Monde Francophone",
          DateTime(2023, 1, 1),
          DateTime(2030, 1, 1),
        ),
      ],
      tags: [
        "réalité virtuelle",
        "thriller",
        "science-fiction",
        "psychologique",
      ],
      isExclusive: true,
      isFeatured: false,
      addedDate: DateTime(2023, 9, 15),
      stats: FilmStats(
        views: 12500,
        likes: 843,
        dislikes: 45,
        comments: 127,
        rating: 4.2,
        watchTime: 254800,
        completionRate: 78.5,
        publicationHistory: [
          PublicationEvent(
            "Soumission",
            DateTime(2023, 9, 15),
            "Producteur: Jean Films",
          ),
          PublicationEvent(
            "Validation technique",
            DateTime(2023, 9, 16),
            "Admin: Marie Tech",
          ),
          PublicationEvent(
            "Approbation contenu",
            DateTime(2023, 9, 18),
            "Admin: Pierre Content",
          ),
          PublicationEvent(
            "Publication",
            DateTime(2023, 10, 1),
            "Système automatique",
          ),
        ],
        recentComments: [
          FilmComment(
            "User123",
            "Excellent film, je recommande !",
            DateTime(2023, 10, 5),
            4.5,
          ),
          FilmComment(
            "Cinéphile22",
            "La fin m'a surpris, très bon scénario",
            DateTime(2023, 10, 4),
            4.0,
          ),
          FilmComment(
            "MovieLover",
            "Effets spéciaux impressionnants",
            DateTime(2023, 10, 3),
            5.0,
          ),
        ],
        ratingsDistribution: {"5": 45, "4": 35, "3": 15, "2": 3, "1": 2},
      ),
      metadata: FilmMetadata(
        imdbId: "tt1234567",
        tmdbId: "12345",
        productionCompanies: ["CinéFrance Productions", "Québec Films"],
        filmingLocations: ["Paris", "Montréal", "Lyon"],
        awards: [
          Award("Festival de Cannes", "Meilleur scénario", 2023, "Nomination"),
          Award("César du Cinéma", "Meilleurs effets visuels", 2024, "Lauréat"),
        ],
        festivals: [
          FestivalEvent("Festival de Cannes", "2023", "Section Officielle"),
          FestivalEvent("TIFF", "2023", "Contemporary World Cinema"),
        ],
        keywords: ["réalité virtuelle", "IA", "simulation", "conscience"],
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
            itemBuilder: (context, index) =>
                _buildFilmCard(context, films[index]),
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
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.searchFilmHint,
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
            Stack(
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
                        child: Icon(
                          Icons.live_tv,
                          size: 50,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ),
                ),
                if (film.isExclusive)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(
                          AppTheme.borderRadiusSmall,
                        ),
                      ),
                      child: Text(
                        'EXCLUSIF',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: AppTheme.fontSizeSmall,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(AppTheme.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              film.title,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            if (film.originalTitle != film.title)
                              Text(
                                film.originalTitle,
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: AppTheme.fontSizeSmall,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                          ],
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
                      _buildMetaChip(
                        Icons.calendar_today,
                        '${film.releaseYear}',
                      ),
                      _buildMetaChip(Icons.language, film.language),
                      _buildMetaChip(Icons.timer, '${film.duration} min'),
                      _buildMetaChip(Icons.place, film.country),
                      _buildMetaChip(
                        Icons.attach_money,
                        '${(film.budget / 1000000).toStringAsFixed(1)}M',
                      ),
                      ...film.genres.map(
                        (genre) => _buildMetaChip(Icons.category, genre),
                      ),
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
        statusText = 'Publié';
      case 'En attente':
        color = AppTheme.warning;
        statusText = 'En attente';
      case 'Rejeté':
        color = AppTheme.error;
        statusText = 'Rejeté';
      case 'En traitement':
        color = Colors.blue;
        statusText = 'En traitement';
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
        color: color.withValues(alpha: 0.2),
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
      label: Text(text, style: TextStyle(color: AppTheme.textPrimary)),
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
        _buildStatItem(
          Icons.remove_red_eye,
          formatter.format(film.stats.views),
        ),
        _buildStatItem(Icons.thumb_up, formatter.format(film.stats.likes)),
        _buildStatItem(Icons.comment, formatter.format(film.stats.comments)),
        _buildStatItem(Icons.star, film.stats.rating.toString()),
        _buildStatItem(
          Icons.trending_up,
          '${film.stats.completionRate.toInt()}%',
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

// MODÈLES DE DONNÉES ÉTENDUS

class Film {
  final String title;
  final String originalTitle;
  final String description;
  final String synopsis;
  final List<String> genres;
  final String language;
  final String originalLanguage;
  final List<String> spokenLanguages;
  final int releaseYear;
  final int duration;
  final String country;
  final List<String> productionCountries;
  final String status;
  final String ageRating;
  final String certification;
  final double budget;
  final double revenue;
  final FilmTeam team;
  final FilmMedia media;
  final FilmTechnicalInfo technicalInfo;
  final List<SubtitleTrack> subtitles;
  final List<AudioTrack> audioTracks;
  final List<VideoQuality> videoQualities;
  final List<DistributionRight> distributionRights;
  final List<String> tags;
  final bool isExclusive;
  final bool isFeatured;
  final DateTime addedDate;
  final FilmStats stats;
  final FilmMetadata metadata;

  Film({
    required this.title,
    required this.originalTitle,
    required this.description,
    required this.synopsis,
    required this.genres,
    required this.language,
    required this.originalLanguage,
    required this.spokenLanguages,
    required this.releaseYear,
    required this.duration,
    required this.country,
    required this.productionCountries,
    required this.status,
    required this.ageRating,
    required this.certification,
    required this.budget,
    required this.revenue,
    required this.team,
    required this.media,
    required this.technicalInfo,
    required this.subtitles,
    required this.audioTracks,
    required this.videoQualities,
    required this.distributionRights,
    required this.tags,
    required this.isExclusive,
    required this.isFeatured,
    required this.addedDate,
    required this.stats,
    required this.metadata,
  });
}

class FilmTeam {
  final String director;
  final String screenwriter;
  final List<String> producers;
  final Map<String, String> cast;
  final String cinematographer;
  final String composer;
  final String editor;

  FilmTeam({
    required this.director,
    required this.screenwriter,
    required this.producers,
    required this.cast,
    required this.cinematographer,
    required this.composer,
    required this.editor,
  });
}

class FilmMedia {
  final String videoUrl;
  final String posterUrl;
  final String bannerUrl;
  final String trailerUrl;
  final List<String> gallery;
  final String logoUrl;

  FilmMedia({
    required this.videoUrl,
    required this.posterUrl,
    required this.bannerUrl,
    required this.trailerUrl,
    required this.gallery,
    required this.logoUrl,
  });
}

class FilmTechnicalInfo {
  final String resolution;
  final String format;
  final String codec;
  final String audioCodec;
  final String audioChannels;
  final String fileSize;
  final String aspectRatio;
  final String frameRate;

  FilmTechnicalInfo({
    required this.resolution,
    required this.format,
    required this.codec,
    required this.audioCodec,
    required this.audioChannels,
    required this.fileSize,
    required this.aspectRatio,
    required this.frameRate,
  });
}

class SubtitleTrack {
  final String language;
  final String url;
  final bool isForced;

  SubtitleTrack(this.language, this.url, this.isForced);
}

class AudioTrack {
  final String language;
  final String codec;
  final String channels;
  final bool isOriginal;

  AudioTrack(this.language, this.codec, this.channels, this.isOriginal);
}

class VideoQuality {
  final String quality;
  final String url;
  final String fileSize;

  VideoQuality(this.quality, this.url, this.fileSize);
}

class DistributionRight {
  final String territory;
  final DateTime startDate;
  final DateTime endDate;

  DistributionRight(this.territory, this.startDate, this.endDate);
}

class FilmStats {
  final int views;
  final int likes;
  final int dislikes;
  final int comments;
  final double rating;
  final int watchTime; // en minutes
  final double completionRate; // pourcentage
  final List<PublicationEvent> publicationHistory;
  final List<FilmComment> recentComments;
  final Map<String, int> ratingsDistribution;

  FilmStats({
    required this.views,
    required this.likes,
    required this.dislikes,
    required this.comments,
    required this.rating,
    required this.watchTime,
    required this.completionRate,
    required this.publicationHistory,
    required this.recentComments,
    required this.ratingsDistribution,
  });
}

class FilmMetadata {
  final String imdbId;
  final String tmdbId;
  final List<String> productionCompanies;
  final List<String> filmingLocations;
  final List<Award> awards;
  final List<FestivalEvent> festivals;
  final List<String> keywords;

  FilmMetadata({
    required this.imdbId,
    required this.tmdbId,
    required this.productionCompanies,
    required this.filmingLocations,
    required this.awards,
    required this.festivals,
    required this.keywords,
  });
}

class PublicationEvent {
  final String action;
  final DateTime date;
  final String notes;

  PublicationEvent(this.action, this.date, this.notes);
}

class FilmComment {
  final String username;
  final String text;
  final DateTime date;
  final double rating;

  FilmComment(this.username, this.text, this.date, this.rating);
}

class Award {
  final String organization;
  final String category;
  final int year;
  final String result;

  Award(this.organization, this.category, this.year, this.result);
}

class FestivalEvent {
  final String name;
  final String year;
  final String section;

  FestivalEvent(this.name, this.year, this.section);
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
                background: Stack(
                  children: [
                    Image.asset(
                      film.media.bannerUrl,
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
                padding: const EdgeInsets.all(AppTheme.paddingMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // En-tête avec titre et badges
                    _buildHeaderSection(context),
                    const SizedBox(height: AppTheme.paddingLarge),

                    // Sections organisées dans des ExpansionTile
                    _buildSynopsisSection(context),
                    _buildInformationSection(context),
                    _buildTechnicalSection(context),
                    _buildTeamSection(context),
                    _buildDistributionSection(context),
                    _buildStatsSection(context),
                    _buildCommentsSection(context),
                    _buildMetadataSection(context),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    film.title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  if (film.originalTitle != film.title)
                    Text(
                      film.originalTitle,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: AppTheme.fontSizeMedium,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
            _buildStatusBadge(context, film.status),
          ],
        ),
        const SizedBox(height: AppTheme.paddingSmall),
        Wrap(
          spacing: AppTheme.paddingSmall,
          runSpacing: AppTheme.paddingSmall,
          children: [
            if (film.isExclusive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(
                    AppTheme.borderRadiusSmall,
                  ),
                ),
                child: Text(
                  'EXCLUSIF',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: AppTheme.fontSizeSmall,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (film.isFeatured)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.success,
                  borderRadius: BorderRadius.circular(
                    AppTheme.borderRadiusSmall,
                  ),
                ),
                child: Text(
                  'EN VEDETTE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: AppTheme.fontSizeSmall,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
              ),
              child: Text(
                film.ageRating,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: AppTheme.fontSizeSmall,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSynopsisSection(BuildContext context) {
    return ExpansionTile(
      title: Text(
        'Synopsis',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimary,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.paddingMedium),
          child: Text(
            film.synopsis,
            style: TextStyle(color: AppTheme.textSecondary, height: 1.6),
          ),
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
            _buildTableRow('Genres', film.genres.join(', ')),
            _buildTableRow('Langue', film.language),
            _buildTableRow('Langue originale', film.originalLanguage),
            _buildTableRow('Langues parlées', film.spokenLanguages.join(', ')),
            _buildTableRow('Année', film.releaseYear.toString()),
            _buildTableRow('Durée', '${film.duration} min'),
            _buildTableRow('Pays', film.country),
            _buildTableRow(
              'Pays de production',
              film.productionCountries.join(', '),
            ),
            _buildTableRow('Classification', film.ageRating),
            _buildTableRow('Certification', film.certification),
            _buildTableRow(
              'Budget',
              '${(film.budget / 1000000).toStringAsFixed(1)}M €',
            ),
            _buildTableRow(
              'Recettes',
              '${(film.revenue / 1000000).toStringAsFixed(1)}M €',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTechnicalSection(BuildContext context) {
    return ExpansionTile(
      title: Text(
        'Informations techniques',
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
            _buildTableRow('Résolution', film.technicalInfo.resolution),
            _buildTableRow('Format', film.technicalInfo.format),
            _buildTableRow('Codec vidéo', film.technicalInfo.codec),
            _buildTableRow('Codec audio', film.technicalInfo.audioCodec),
            _buildTableRow('Canaux audio', film.technicalInfo.audioChannels),
            _buildTableRow('Taille fichier', film.technicalInfo.fileSize),
            _buildTableRow('Ratio d\'aspect', film.technicalInfo.aspectRatio),
            _buildTableRow('Fréquence d\'images', film.technicalInfo.frameRate),
          ],
        ),
        const SizedBox(height: AppTheme.paddingMedium),
        Text(
          'Qualités disponibles:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        ...film.videoQualities.map(
          (quality) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text('• ${quality.quality} - ${quality.fileSize}'),
          ),
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
        _buildTeamItem('Réalisateur', film.team.director),
        _buildTeamItem('Scénariste', film.team.screenwriter),
        _buildTeamItem('Producteurs', film.team.producers.join(', ')),
        _buildTeamItem('Directeur photo', film.team.cinematographer),
        _buildTeamItem('Compositeur', film.team.composer),
        _buildTeamItem('Monteur', film.team.editor),
        const SizedBox(height: AppTheme.paddingMedium),
        Text(
          'Distribution principale:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        ...film.team.cast.entries.map(
          (e) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text('• ${e.key} : ${e.value}'),
          ),
        ),
      ],
    );
  }

  Widget _buildDistributionSection(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    return ExpansionTile(
      title: Text(
        'Droits de distribution',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimary,
        ),
      ),
      children: [
        ...film.distributionRights.map(
          (right) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  right.territory,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  '${dateFormat.format(right.startDate)} - ${dateFormat.format(right.endDate)}',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ],
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
          spacing: AppTheme.paddingMedium,
          runSpacing: AppTheme.paddingSmall,
          children: [
            _buildStatCard('Vues', formatter.format(film.stats.views)),
            _buildStatCard('J\'aime', formatter.format(film.stats.likes)),
            _buildStatCard(
              'Commentaires',
              formatter.format(film.stats.comments),
            ),
            _buildStatCard('Note', film.stats.rating.toString()),
            _buildStatCard(
              'Taux complétion',
              '${film.stats.completionRate.toInt()}%',
            ),
          ],
        ),
        const SizedBox(height: AppTheme.paddingMedium),
        Text(
          'Historique de publication:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        ...film.stats.publicationHistory.map(
          (e) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text('• ${e.action} - ${dateFormat.format(e.date)}'),
          ),
        ),
      ],
    );
  }

  Widget _buildCommentsSection(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    return ExpansionTile(
      title: Text(
        'Commentaires récents',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimary,
        ),
      ),
      children: film.stats.recentComments
          .map(
            (comment) => Card(
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
                          '⭐ ${comment.rating}',
                          style: TextStyle(color: AppTheme.warning),
                        ),
                        const SizedBox(width: 8),
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
            ),
          )
          .toList(),
    );
  }

  Widget _buildMetadataSection(BuildContext context) {
    return ExpansionTile(
      title: Text(
        'Métadonnées',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimary,
        ),
      ),
      children: [
        _buildMetadataItem('ID IMDb', film.metadata.imdbId),
        _buildMetadataItem('ID TMDb', film.metadata.tmdbId),
        _buildMetadataItem(
          'Sociétés de production',
          film.metadata.productionCompanies.join(', '),
        ),
        _buildMetadataItem(
          'Lieux de tournage',
          film.metadata.filmingLocations.join(', '),
        ),
        const SizedBox(height: AppTheme.paddingMedium),
        Text(
          'Récompenses:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        ...film.metadata.awards.map(
          (award) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              '• ${award.organization} (${award.year}) - ${award.category} - ${award.result}',
            ),
          ),
        ),
        const SizedBox(height: AppTheme.paddingMedium),
        Text(
          'Festivals:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        ...film.metadata.festivals.map(
          (festival) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              '• ${festival.name} (${festival.year}) - ${festival.section}',
            ),
          ),
        ),
      ],
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
            icon: Icon(Icons.edit, color: AppTheme.textPrimary),
            label: Text(
              'Modifier',
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
                vertical: AppTheme.paddingMedium,
              ),
            ),
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close, color: AppTheme.textPrimary),
            label: Text(
              'Fermer',
              style: TextStyle(color: AppTheme.textPrimary),
            ),
          ),
        ),
      ],
    );
  }

  TableRow _buildTableRow(String label, String value) {
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
          child: Text(value, style: TextStyle(color: AppTheme.textPrimary)),
        ),
      ],
    );
  }

  Widget _buildTeamItem(String role, String name) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.paddingSmall),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$role :',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(child: Text(name)),
        ],
      ),
    );
  }

  Widget _buildMetadataItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.paddingSmall),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              '$label :',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
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

  Widget _buildStatusBadge(BuildContext context, String status) {
    Color color;
    String statusText;

    switch (status) {
      case 'Publié':
        color = AppTheme.success;
        statusText = 'Publié';
      case 'En attente':
        color = AppTheme.warning;
        statusText = 'En attente';
      case 'Rejeté':
        color = AppTheme.error;
        statusText = 'Rejeté';
      case 'En traitement':
        color = Colors.blue;
        statusText = 'En traitement';
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
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
      ),
      child: Text(
        statusText,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}
