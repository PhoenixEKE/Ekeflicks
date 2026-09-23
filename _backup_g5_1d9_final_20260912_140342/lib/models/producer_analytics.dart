class ProducerAnalyticsEngagement {
  final int likes;
  final int unlikes;
  final int netLikes;
  final int uniqueLikers;
  final int uniqueViewers;
  final double engagementRatePercent;
  final int currentLikes;

  const ProducerAnalyticsEngagement({
    required this.likes,
    required this.unlikes,
    required this.netLikes,
    required this.uniqueLikers,
    required this.uniqueViewers,
    required this.engagementRatePercent,
    required this.currentLikes,
  });

  factory ProducerAnalyticsEngagement.empty() {
    return const ProducerAnalyticsEngagement(
      likes: 0,
      unlikes: 0,
      netLikes: 0,
      uniqueLikers: 0,
      uniqueViewers: 0,
      engagementRatePercent: 0,
      currentLikes: 0,
    );
  }

  factory ProducerAnalyticsEngagement.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return ProducerAnalyticsEngagement.empty();
    }

    return ProducerAnalyticsEngagement(
      likes: _asInt(json['likes']),
      unlikes: _asInt(json['unlikes']),
      netLikes: _asInt(json['net_likes']),
      uniqueLikers: _asInt(json['unique_likers']),
      uniqueViewers: _asInt(json['unique_viewers']),
      engagementRatePercent: _asDouble(json['engagement_rate_percent']),
      currentLikes: _asInt(json['current_likes']),
    );
  }
}

class ProducerContentAnalytics {
  final String contentId;
  final String title;
  final String contentType;

  final int playStarts;
  final int qualifiedViews;
  final int uniqueViewers;
  final double watchSeconds;
  final int completedViews;
  final double qualificationRatePercent;
  final double completionRatePercent;

  const ProducerContentAnalytics({
    required this.contentId,
    required this.title,
    required this.contentType,
    required this.playStarts,
    required this.qualifiedViews,
    required this.uniqueViewers,
    required this.watchSeconds,
    required this.completedViews,
    required this.qualificationRatePercent,
    required this.completionRatePercent,
  });

  factory ProducerContentAnalytics.fromJson(Map<String, dynamic> json) {
    final metricsRaw = json['metrics'];
    final metrics = metricsRaw is Map
        ? Map<String, dynamic>.from(metricsRaw)
        : json;

    final contentRaw = json['content'];
    final content = contentRaw is Map
        ? Map<String, dynamic>.from(contentRaw)
        : <String, dynamic>{};

    String firstString(List<dynamic> values) {
      for (final value in values) {
        if (value != null && value.toString().trim().isNotEmpty) {
          return value.toString();
        }
      }
      return '';
    }

    return ProducerContentAnalytics(
      contentId: firstString([
        json['content_id'],
        json['id'],
        content['content_id'],
        content['id'],
        metrics['content_id'],
      ]),
      title: firstString([
        json['title'],
        content['title'],
        json['content_title'],
      ]),
      contentType: firstString([
        json['content_type'],
        content['content_type'],
        content['type'],
      ]),
      playStarts: _asInt(metrics['play_starts'] ?? json['play_starts']),
      qualifiedViews: _asInt(
        metrics['qualified_views'] ?? json['qualified_views'],
      ),
      uniqueViewers: _asInt(
        metrics['unique_viewers'] ?? json['unique_viewers'],
      ),
      watchSeconds: _asDouble(
        metrics['watch_seconds'] ?? json['watch_seconds'],
      ),
      completedViews: _asInt(
        metrics['completed_views'] ?? json['completed_views'],
      ),
      qualificationRatePercent: _asDouble(
        metrics['qualification_rate_percent'] ??
            json['qualification_rate_percent'],
      ),
      completionRatePercent: _asDouble(
        metrics['completion_rate_percent'] ??
            metrics['completion_rate'] ??
            json['completion_rate_percent'],
      ),
    );
  }
}

class ProducerAnalyticsOverview {
  final DateTime? startAt;
  final DateTime? endAt;
  final List<ProducerContentAnalytics> contents;
  final ProducerAnalyticsEngagement engagement;

  const ProducerAnalyticsOverview({
    required this.startAt,
    required this.endAt,
    required this.contents,
    required this.engagement,
  });

  factory ProducerAnalyticsOverview.fromJson(Map<String, dynamic> json) {
    dynamic rawContents =
        json['contents'] ?? json['results'] ?? json['content_analytics'];

    if (rawContents is Map) {
      rawContents = rawContents['results'] ?? rawContents['contents'];
    }

    final contents = <ProducerContentAnalytics>[];

    if (rawContents is List) {
      for (final item in rawContents) {
        if (item is Map) {
          contents.add(
            ProducerContentAnalytics.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    final engagementRaw = json['engagement'];

    return ProducerAnalyticsOverview(
      startAt: _asDate(json['start_at']),
      endAt: _asDate(json['end_at']),
      contents: contents,
      engagement: ProducerAnalyticsEngagement.fromJson(
        engagementRaw is Map ? Map<String, dynamic>.from(engagementRaw) : null,
      ),
    );
  }
}

class ProducerAnalyticsDetail {
  final ProducerContentAnalytics content;
  final ProducerAnalyticsEngagement engagement;

  const ProducerAnalyticsDetail({
    required this.content,
    required this.engagement,
  });

  factory ProducerAnalyticsDetail.fromJson(Map<String, dynamic> json) {
    final engagementRaw = json['engagement'];

    return ProducerAnalyticsDetail(
      content: ProducerContentAnalytics.fromJson(json),
      engagement: ProducerAnalyticsEngagement.fromJson(
        engagementRaw is Map ? Map<String, dynamic>.from(engagementRaw) : null,
      ),
    );
  }
}

int _asInt(dynamic value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.round();
  }

  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _asDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime? _asDate(dynamic value) {
  if (value == null) {
    return null;
  }

  return DateTime.tryParse(value.toString());
}
