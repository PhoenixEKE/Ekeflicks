enum ContentType { movie, series }

class Episode {
  const Episode({required this.id, required this.title, required this.number,
    required this.videoUrl, this.description = '', this.duration = Duration.zero,
    this.imageUrl = '', this.progress = 0});

  final String id;
  final String title;
  final int number;
  final String videoUrl;
  final String description;
  final Duration duration;
  final String imageUrl;
  final double progress;

  factory Episode.fromJson(Map<String, dynamic> json) => Episode(
    id: '${json['id']}', title: json['title']?.toString() ?? '',
    number: _integer(json['number'] ?? json['episode_number']),
    videoUrl: json['video_url']?.toString() ?? json['stream_url']?.toString() ?? '',
    description: json['description']?.toString() ?? '',
    duration: Duration(seconds: _integer(json['duration_seconds'] ?? json['duration'])),
    imageUrl: json['image_url']?.toString() ?? json['thumbnail_url']?.toString() ?? '',
    progress: _decimal(json['progress']),
  );
}

class Season {
  const Season({required this.id, required this.number, required this.title, required this.episodes});
  final String id;
  final int number;
  final String title;
  final List<Episode> episodes;

  factory Season.fromJson(Map<String, dynamic> json) => Season(
    id: '${json['id']}', number: _integer(json['number'] ?? json['season_number']),
    title: json['title']?.toString() ?? '',
    episodes: _maps(json['episodes']).map(Episode.fromJson).toList(),
  );
}

class Content {
  const Content({required this.id, required this.title, required this.description,
    required this.imageUrl, required this.posterUrl, this.backdropUrl = '',
    required this.videoUrl, required this.type, required this.genres,
    required this.releaseYear, required this.duration, this.rating, this.userRating,
    this.ageRating, this.isHd = false, this.progress, this.cast, this.director,
    this.episodeCount, this.seasons, this.seasonInfo, this.seasonList = const [],
    this.isFavorite = false, this.nextEpisode});

  final String id, title, description, imageUrl, posterUrl, backdropUrl, videoUrl, releaseYear;
  final ContentType type;
  final List<String> genres;
  final Duration duration;
  final double? rating, userRating, progress;
  final String? ageRating, director, seasonInfo;
  final bool isHd, isFavorite;
  final List<String>? cast;
  final int? episodeCount, seasons;
  final List<Season> seasonList;
  final Episode? nextEpisode;

  factory Content.fromJson(Map<String, dynamic> json) {
    final rawType = json['type']?.toString().toLowerCase();
    final seasonList = _maps(json['seasons']).map(Season.fromJson).toList();
    return Content(
      id: '${json['id']}', title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? json['synopsis']?.toString() ?? '',
      imageUrl: json['image_url']?.toString() ?? json['backdrop_url']?.toString() ?? '',
      posterUrl: json['poster_url']?.toString() ?? json['image_url']?.toString() ?? '',
      backdropUrl: json['backdrop_url']?.toString() ?? '',
      videoUrl: json['video_url']?.toString() ?? json['stream_url']?.toString() ?? '',
      type: rawType == 'series' || rawType == 'serie' ? ContentType.series : ContentType.movie,
      genres: (json['genres'] as List? ?? const []).map((e) => e is Map ? (e['name'] ?? '').toString() : e.toString()).where((e) => e.isNotEmpty).toList(),
      releaseYear: (json['release_year'] ?? json['year'] ?? '').toString(),
      duration: Duration(seconds: _integer(json['duration_seconds'] ?? json['duration'])),
      rating: _nullableDecimal(json['rating'] ?? json['average_rating']),
      userRating: _nullableDecimal(json['user_rating']), ageRating: json['age_rating']?.toString(),
      isHd: json['is_hd'] == true, progress: _nullableDecimal(json['progress']),
      cast: (json['cast'] as List?)?.map((e) => e is Map ? (e['name'] ?? '').toString() : e.toString()).toList(),
      director: json['director'] is Map ? json['director']['name']?.toString() : json['director']?.toString(),
      episodeCount: json['episode_count'] == null ? null : _integer(json['episode_count']),
      seasons: json['season_count'] == null ? (seasonList.isEmpty ? null : seasonList.length) : _integer(json['season_count']),
      seasonInfo: json['season_info']?.toString(), seasonList: seasonList,
      isFavorite: json['is_favorite'] == true,
      nextEpisode: json['next_episode'] is Map ? Episode.fromJson(Map<String, dynamic>.from(json['next_episode'])) : null,
    );
  }

  bool get hasProgress => progress != null && progress! > 0;
  bool get isMovie => type == ContentType.movie;
  bool get isSeries => type == ContentType.series;
  String get typeString => isMovie ? 'Movie' : 'Series';
  String get formattedDuration => duration.inHours > 0 ? '${duration.inHours}h ${duration.inMinutes.remainder(60)}m' : '${duration.inMinutes}m';

  Content copyWith({String? id, String? title, String? description, String? imageUrl,
    String? posterUrl, String? backdropUrl, String? videoUrl, ContentType? type,
    List<String>? genres, String? releaseYear, Duration? duration, double? rating,
    double? userRating, String? ageRating, bool? isHd, double? progress,
    List<String>? cast, String? director, int? episodeCount, int? seasons,
    String? seasonInfo, List<Season>? seasonList, bool? isFavorite, Episode? nextEpisode}) => Content(
      id: id ?? this.id, title: title ?? this.title, description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl, posterUrl: posterUrl ?? this.posterUrl,
      backdropUrl: backdropUrl ?? this.backdropUrl, videoUrl: videoUrl ?? this.videoUrl,
      type: type ?? this.type, genres: genres ?? this.genres, releaseYear: releaseYear ?? this.releaseYear,
      duration: duration ?? this.duration, rating: rating ?? this.rating, userRating: userRating ?? this.userRating,
      ageRating: ageRating ?? this.ageRating, isHd: isHd ?? this.isHd, progress: progress ?? this.progress,
      cast: cast ?? this.cast, director: director ?? this.director, episodeCount: episodeCount ?? this.episodeCount,
      seasons: seasons ?? this.seasons, seasonInfo: seasonInfo ?? this.seasonInfo,
      seasonList: seasonList ?? this.seasonList, isFavorite: isFavorite ?? this.isFavorite,
      nextEpisode: nextEpisode ?? this.nextEpisode);
}

List<Map<String, dynamic>> _maps(dynamic value) => (value as List? ?? const [])
    .whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
int _integer(dynamic value) => value is num ? value.toInt() : int.tryParse('$value') ?? 0;
double _decimal(dynamic value) => value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
double? _nullableDecimal(dynamic value) => value == null ? null : _decimal(value);
