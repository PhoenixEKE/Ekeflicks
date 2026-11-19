import 'package:app_ekeflicks/models/content_model.dart';
import 'package:flutter_test/flutter_test.dart';

Content content({
  ContentType type = ContentType.movie,
  Duration duration = const Duration(minutes: 95),
  double? progress,
}) => Content(
  id: 'film-1',
  title: 'Test film',
  description: 'Description',
  imageUrl: '/banner.jpg',
  posterUrl: '/poster.jpg',
  videoUrl: '/film.m3u8',
  type: type,
  genres: const ['Drama'],
  releaseYear: '2026',
  duration: duration,
  progress: progress,
);

void main() {
  group('Content', () {
    test('parses API detail including seasons, progress and next episode', () {
      final parsed = Content.fromJson({
        'id': 42,
        'title': 'API series',
        'type': 'series',
        'duration_seconds': 2700,
        'genres': [
          {'name': 'Drame'},
        ],
        'progress': 0.5,
        'is_favorite': true,
        'user_rating': 4,
        'seasons': [
          {
            'id': 1,
            'season_number': 1,
            'title': 'Saison 1',
            'episodes': [
              {
                'id': 8,
                'episode_number': 2,
                'title': 'Retour',
                'stream_url': '/e8.m3u8',
              },
            ],
          },
        ],
        'next_episode': {
          'id': 9,
          'episode_number': 3,
          'title': 'Après',
          'stream_url': '/e9.m3u8',
        },
      });

      expect(parsed.id, '42');
      expect(parsed.isSeries, isTrue);
      expect(parsed.seasonList.single.episodes.single.number, 2);
      expect(parsed.nextEpisode?.id, '9');
      expect(parsed.isFavorite, isTrue);
      expect(parsed.userRating, 4);
    });

    test('formats durations with and without hours', () {
      expect(content().formattedDuration, '1h 35m');
      expect(
        content(duration: const Duration(minutes: 42)).formattedDuration,
        '42m',
      );
    });

    test('exposes type helpers', () {
      expect(content().isMovie, isTrue);
      expect(content(type: ContentType.series).isSeries, isTrue);
      expect(content(type: ContentType.series).typeString, 'Series');
    });

    test('only reports strictly positive progress', () {
      expect(content().hasProgress, isFalse);
      expect(content(progress: 0).hasProgress, isFalse);
      expect(content(progress: .25).hasProgress, isTrue);
    });

    test('copyWith changes requested fields and preserves the others', () {
      final original = content(progress: .25);
      final copy = original.copyWith(title: 'Updated', isHd: true);

      expect(copy.title, 'Updated');
      expect(copy.isHd, isTrue);
      expect(copy.id, original.id);
      expect(copy.progress, original.progress);
    });
  });
}
