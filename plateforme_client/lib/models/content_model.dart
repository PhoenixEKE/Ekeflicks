enum ContentType { movie, series }

class Content {
  final String id;
  final String title;
  final String description;
  final String imageUrl;    // Image principale (banner)
  final String posterUrl;   // Affiche
  final String backdropUrl; // Optionnel pour les détails
  final String videoUrl;
  final ContentType type;
  final List<String> genres;
  final String releaseYear;
  final Duration duration;
  final double? rating;
  final String? ageRating;
  final bool isHd;
  final double? progress;   // Pour "continuer à regarder"

  // --- Champs supplémentaires ---
  final List<String>? cast;       // Distribution
  final String? director;         // Réalisateur
  final int? episodeCount;        // Nombre total d’épisodes
  final int? seasons;             // Nombre de saisons
  final String? seasonInfo;       // Texte court type "3 seasons"
  
  Content({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.posterUrl,
    this.backdropUrl = '',
    required this.videoUrl,
    required this.type,
    required this.genres,
    required this.releaseYear,
    required this.duration,
    this.rating,
    this.ageRating,
    this.isHd = false,
    this.progress,
    this.cast,
    this.director,
    this.episodeCount,
    this.seasons,
    this.seasonInfo,
  });

  // --- Getters utiles ---
  bool get hasProgress => progress != null && progress! > 0;
  bool get isMovie => type == ContentType.movie;
  bool get isSeries => type == ContentType.series;
  String get typeString => isMovie ? 'Movie' : 'Series';

  /// Retourne une durée formatée comme "2h 15m"
  String get formattedDuration {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return "${hours}h ${minutes}m";
    }
    return "${minutes}m";
  }

  // --- CopyWith ---
  Content copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    String? posterUrl,
    String? backdropUrl,
    String? videoUrl,
    ContentType? type,
    List<String>? genres,
    String? releaseYear,
    Duration? duration,
    double? rating,
    String? ageRating,
    bool? isHd,
    double? progress,
    List<String>? cast,
    String? director,
    int? episodeCount,
    int? seasons,
    String? seasonInfo,
  }) {
    return Content(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      posterUrl: posterUrl ?? this.posterUrl,
      backdropUrl: backdropUrl ?? this.backdropUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      type: type ?? this.type,
      genres: genres ?? this.genres,
      releaseYear: releaseYear ?? this.releaseYear,
      duration: duration ?? this.duration,
      rating: rating ?? this.rating,
      ageRating: ageRating ?? this.ageRating,
      isHd: isHd ?? this.isHd,
      progress: progress ?? this.progress,
      cast: cast ?? this.cast,
      director: director ?? this.director,
      episodeCount: episodeCount ?? this.episodeCount,
      seasons: seasons ?? this.seasons,
      seasonInfo: seasonInfo ?? this.seasonInfo,
    );
  }
}
