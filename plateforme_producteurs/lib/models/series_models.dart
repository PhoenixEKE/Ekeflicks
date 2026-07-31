// lib/models/series_models.dart
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
  final String description;
  final String posterUrl;
  final String bannerUrl;
  final String trailerUrl;
  final List<Episode> episodes;

  Season({
    required this.number,
    required this.title,
    required this.description,
    required this.posterUrl,
    required this.bannerUrl,
    required this.trailerUrl,
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