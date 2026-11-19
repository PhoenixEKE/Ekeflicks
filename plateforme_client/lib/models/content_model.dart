enum ContentType { movie, series }

class Episode {
  const Episode({
    required this.id,
    required this.title,
    required this.number,
    required this.videoUrl,
    this.description = '',
    this.duration = Duration.zero,
    this.imageUrl = '',
    this.progress = 0,
  });

  final String id;
  final String title;
  final int number;
  final String videoUrl;
  final String description;
  final Duration duration;
  final String imageUrl;
  final double progress;

  factory Episode.fromJson(Map<String, dynamic> json) => Episode(
    id: '${json['id'] ?? ''}',
    title: json['title']?.toString() ?? '',
    number: _integer(json['number'] ?? json['episode_number']),
    videoUrl: json['video_url']?.toString() ?? json['stream_url']?.toString() ?? '',
    description: json['description']?.toString() ?? '',
    duration: _readDuration(json),
    imageUrl: json['image_url']?.toString() ?? json['thumbnail_url']?.toString() ?? '',
    progress: _decimal(json['progress']),
  );
}

class Season {
  const Season({
    required this.id,
    required this.number,
    required this.title,
    required this.episodes,
  });

  final String id;
  final int number;
  final String title;
  final List<Episode> episodes;

  factory Season.fromJson(Map<String, dynamic> json) => Season(
    id: '${json['id'] ?? ''}',
    number: _integer(json['number'] ?? json['season_number'] ?? json['season']),
    title: json['title']?.toString() ?? '',
    episodes: _maps(json['episodes']).map(Episode.fromJson).toList(),
  );
}

class Content {
  const Content({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.posterUrl,
    this.backdropUrl = '',
    required this.videoUrl,
    this.trailerUrl = '',
    this.country = '',
    this.emissions = const [],
    required this.type,
    required this.genres,
    required this.releaseYear,
    required this.duration,
    this.rating,
    this.userRating,
    this.ageRating,
    this.isHd = false,
    this.progress,
    this.cast,
    this.director,
    this.episodeCount,
    this.seasons,
    this.seasonInfo,
    this.seasonList = const [],
    this.isFavorite = false,
    this.nextEpisode,
  });

  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String posterUrl;
  final String backdropUrl;
  final String videoUrl;
  final String trailerUrl;
  final String country;
  final List<String> emissions;
  final String releaseYear;
  final ContentType type;
  final List<String> genres;
  final Duration duration;
  final double? rating;
  final double? userRating;
  final double? progress;
  final String? ageRating;
  final String? director;
  final String? seasonInfo;
  final bool isHd;
  final bool isFavorite;
  final List<String>? cast;
  final int? episodeCount;
  final int? seasons;
  final List<Season> seasonList;
  final Episode? nextEpisode;

  factory Content.fromJson(Map<String, dynamic> json) {
    final rawType = json['type']?.toString().toLowerCase();
    final seasonList = _maps(json['seasons']).map(Season.fromJson).toList();
    return Content(
      id: '${json['id'] ?? ''}',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? json['synopsis']?.toString() ?? '',
      imageUrl: json['image_url']?.toString() ?? json['backdrop_url']?.toString() ?? '',
      posterUrl: json['poster_url']?.toString() ?? json['image_url']?.toString() ?? '',
      backdropUrl: json['backdrop_url']?.toString() ?? '',
      videoUrl: json['video_url']?.toString() ?? json['stream_url']?.toString() ?? '',
      trailerUrl: json['trailer_url']?.toString() ?? '',
      country: json['country']?.toString().trim() ?? '',
      emissions: _strings(json['emissions']),
      type: rawType == 'series' || rawType == 'serie' ? ContentType.series : ContentType.movie,
      genres: _strings(json['genres']),
      releaseYear: (json['release_year'] ?? json['year'] ?? '').toString(),
      duration: _readDuration(json),
      rating: _nullableDecimal(json['rating'] ?? json['rating_avg'] ?? json['average_rating']),
      userRating: _nullableDecimal(json['user_rating']),
      ageRating: json['age_rating']?.toString(),
      isHd: json['is_hd'] == true,
      progress: _nullableDecimal(json['progress']),
      cast: json['cast'] is List ? _strings(json['cast']) : null,
      director: json['director'] is Map ? json['director']['name']?.toString() : (json['director_name'] ?? json['director'])?.toString(),
      episodeCount: json['episode_count'] == null ? _episodeCount(seasonList) : _integer(json['episode_count']),
      seasons: json['season_count'] == null ? (seasonList.isEmpty ? null : seasonList.length) : _integer(json['season_count']),
      seasonInfo: json['season_info']?.toString(),
      seasonList: seasonList,
      isFavorite: json['is_favorite'] == true,
      nextEpisode: json['next_episode'] is Map ? Episode.fromJson(Map<String, dynamic>.from(json['next_episode'])) : null,
    );
  }

  bool get hasProgress => progress != null && progress! > 0;
  bool get isMovie => type == ContentType.movie;
  bool get isSeries => type == ContentType.series;
  String get typeString => isMovie ? 'Movie' : 'Series';
  String get formattedDuration {
    if (duration <= Duration.zero) return '';
    return duration.inHours > 0
        ? '${duration.inHours}h ${duration.inMinutes.remainder(60)}m'
        : '${duration.inMinutes}m';
  }

  Content copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    String? posterUrl,
    String? backdropUrl,
    String? videoUrl,
    String? trailerUrl,
    String? country,
    List<String>? emissions,
    ContentType? type,
    List<String>? genres,
    String? releaseYear,
    Duration? duration,
    double? rating,
    double? userRating,
    String? ageRating,
    bool? isHd,
    double? progress,
    List<String>? cast,
    String? director,
    int? episodeCount,
    int? seasons,
    String? seasonInfo,
    List<Season>? seasonList,
    bool? isFavorite,
    Episode? nextEpisode,
  }) => Content(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description ?? this.description,
    imageUrl: imageUrl ?? this.imageUrl,
    posterUrl: posterUrl ?? this.posterUrl,
    backdropUrl: backdropUrl ?? this.backdropUrl,
    videoUrl: videoUrl ?? this.videoUrl,
    trailerUrl: trailerUrl ?? this.trailerUrl,
    country: country ?? this.country,
    emissions: emissions ?? this.emissions,
    type: type ?? this.type,
    genres: genres ?? this.genres,
    releaseYear: releaseYear ?? this.releaseYear,
    duration: duration ?? this.duration,
    rating: rating ?? this.rating,
    userRating: userRating ?? this.userRating,
    ageRating: ageRating ?? this.ageRating,
    isHd: isHd ?? this.isHd,
    progress: progress ?? this.progress,
    cast: cast ?? this.cast,
    director: director ?? this.director,
    episodeCount: episodeCount ?? this.episodeCount,
    seasons: seasons ?? this.seasons,
    seasonInfo: seasonInfo ?? this.seasonInfo,
    seasonList: seasonList ?? this.seasonList,
    isFavorite: isFavorite ?? this.isFavorite,
    nextEpisode: nextEpisode ?? this.nextEpisode,
  );
}

Duration _readDuration(Map<String, dynamic> json) {
  final seconds = json['duration_seconds'];
  if (seconds != null) return Duration(seconds: _integer(seconds));
  final milliseconds = json['duration_milliseconds'];
  if (milliseconds != null) return Duration(milliseconds: _integer(milliseconds));

  // The API's Content.duration and Episode.duration are expressed in minutes.
  final raw = json['duration_minutes'] ?? json['duration'];
  if (raw is num) return Duration(minutes: raw.round());
  final value = raw?.toString().trim() ?? '';
  final numeric = double.tryParse(value.replaceAll(',', '.'));
  if (numeric != null) return Duration(minutes: numeric.round());
  final parts = value.split(':').map(int.tryParse).toList();
  if (parts.length == 3 && parts.every((part) => part != null)) {
    return Duration(hours: parts[0]!, minutes: parts[1]!, seconds: parts[2]!);
  }
  if (parts.length == 2 && parts.every((part) => part != null)) {
    return Duration(minutes: parts[0]!, seconds: parts[1]!);
  }
  return Duration.zero;
}

int _episodeCount(List<Season> seasons) =>
    seasons.fold<int>(0, (total, season) => total + season.episodes.length);

List<String> _strings(dynamic value) => (value as List? ?? const [])
    .map((item) => item is Map ? (item['display_name'] ?? item['name'] ?? '').toString() : item.toString())
    .map((item) => item.trim())
    .where((item) => item.isNotEmpty)
    .toSet()
    .toList();

List<Map<String, dynamic>> _maps(dynamic value) => (value as List? ?? const [])
    .whereType<Map>()
    .map((item) => Map<String, dynamic>.from(item))
    .toList();

int _integer(dynamic value) => value is num ? value.toInt() : int.tryParse('$value') ?? 0;
double _decimal(dynamic value) => value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
double? _nullableDecimal(dynamic value) => value == null ? null : _decimal(value);
