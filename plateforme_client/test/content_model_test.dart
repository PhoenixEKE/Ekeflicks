import 'package:app_ekeflicks/models/content_model.dart';
import 'package:flutter_test/flutter_test.dart';

Content content({
  ContentType type = ContentType.movie,
  Duration duration = const Duration(minutes: 95),
  double? progress,
}) =>
    Content(
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
    test('formats durations with and without hours', () {
      expect(content().formattedDuration, '1h 35m');
      expect(content(duration: const Duration(minutes: 42)).formattedDuration, '42m');
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
