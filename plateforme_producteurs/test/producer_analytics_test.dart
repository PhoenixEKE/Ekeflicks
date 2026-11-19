import 'package:flutter_test/flutter_test.dart';

import 'package:plateforme_producteurs/models/producer_analytics.dart';

void main() {
  test('parses producer overview analytics', () {
    final result = ProducerAnalyticsOverview.fromJson({
      'start_at': '2026-09-01T00:00:00Z',
      'end_at': '2026-09-12T00:00:00Z',
      'results': [
        {
          'content_id': '00000000-0000-0000-0000-000000000001',
          'title': 'Film test',
          'content_type': 'movie',
          'qualified_views': 120,
          'unique_viewers': 90,
          'watch_seconds': 3600,
          'completed_views': 50,
          'qualification_rate_percent': 80.5,
          'play_starts': 150,
        },
      ],
      'engagement': {
        'likes': 20,
        'unlikes': 3,
        'net_likes': 17,
        'unique_likers': 18,
        'unique_viewers': 90,
        'engagement_rate_percent': 20.0,
        'current_likes': 19,
      },
    });

    expect(result.contents, hasLength(1));
    expect(result.contents.first.qualifiedViews, 120);
    expect(result.engagement.likes, 20);
    expect(result.engagement.netLikes, 17);
    expect(result.engagement.engagementRatePercent, 20);
  });

  test('empty engagement defaults to zero', () {
    final result = ProducerAnalyticsOverview.fromJson({'results': <dynamic>[]});

    expect(result.contents, isEmpty);
    expect(result.engagement.likes, 0);
    expect(result.engagement.currentLikes, 0);
  });

  test('detail accepts nested metrics', () {
    final result = ProducerAnalyticsDetail.fromJson({
      'content': {
        'id': '00000000-0000-0000-0000-000000000001',
        'title': 'Série test',
        'content_type': 'series',
      },
      'metrics': {
        'play_starts': 100,
        'qualified_views': 80,
        'unique_viewers': 70,
        'watch_seconds': 7200,
        'completed_views': 40,
        'qualification_rate_percent': 80,
      },
      'engagement': {
        'likes': 10,
        'unlikes': 2,
        'net_likes': 8,
        'unique_likers': 9,
        'unique_viewers': 70,
        'engagement_rate_percent': 12.86,
        'current_likes': 8,
      },
    });

    expect(result.content.title, 'Série test');
    expect(result.content.playStarts, 100);
    expect(result.content.qualifiedViews, 80);
    expect(result.engagement.currentLikes, 8);
  });
}
