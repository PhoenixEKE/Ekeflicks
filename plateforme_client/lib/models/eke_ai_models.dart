// Public client-side contract for EKE IA.
//
// The backend remains authoritative for catalogue eligibility and access.
// These models deliberately tolerate additive backend fields so the
// spectator client is not coupled to internal recommendation structures.

class EkeAIContent {
  final String id;
  final String title;
  final String? description;
  final String? posterUrl;
  final String? backdropUrl;
  final String? contentType;
  final double? score;
  final String? reason;
  final Map<String, dynamic> raw;

  const EkeAIContent({
    required this.id,
    required this.title,
    this.description,
    this.posterUrl,
    this.backdropUrl,
    this.contentType,
    this.score,
    this.reason,
    required this.raw,
  });

  factory EkeAIContent.fromJson(Map<String, dynamic> json) {
    final nestedContent = json['content'];
    final source =
        nestedContent is Map
            ? <String, dynamic>{
              ...json,
              ...nestedContent.map(
                (key, value) => MapEntry(key.toString(), value),
              ),
            }
            : json;

    return EkeAIContent(
      id:
          (source['id'] ??
                  source['content_id'] ??
                  source['uuid'] ??
                  source['pk'] ??
                  '')
              .toString(),
      title:
          (source['title'] ?? source['name'] ?? source['original_title'] ?? '')
              .toString(),
      description:
          (source['description'] ?? source['synopsis'] ?? source['overview'])
              ?.toString(),
      posterUrl:
          (source['poster_url'] ??
                  source['poster'] ??
                  source['image_url'] ??
                  source['image'])
              ?.toString(),
      backdropUrl:
          (source['backdrop_url'] ??
                  source['banner_url'] ??
                  source['cover_url'])
              ?.toString(),
      contentType: (source['type'] ?? source['content_type'])?.toString(),
      score: _asDouble(
        json['score'] ??
            json['final_score'] ??
            json['ranking_score'] ??
            source['score'],
      ),
      reason:
          (json['reason'] ??
                  json['explanation'] ??
                  json['why'] ??
                  source['reason'])
              ?.toString(),
      raw: Map<String, dynamic>.unmodifiable(source),
    );
  }

  static double? _asDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }
}

class EkeAIStatus {
  final String apiVersion;
  final List<String> capabilities;
  final Map<String, dynamic> raw;

  const EkeAIStatus({
    required this.apiVersion,
    required this.capabilities,
    required this.raw,
  });

  factory EkeAIStatus.fromJson(Map<String, dynamic> json) {
    final rawCapabilities = json['capabilities'];
    final capabilities =
        rawCapabilities is List
            ? rawCapabilities.map((item) => item.toString()).toList()
            : <String>[];

    return EkeAIStatus(
      apiVersion:
          (json['api_version'] ?? json['version'] ?? 'unknown').toString(),
      capabilities: List<String>.unmodifiable(capabilities),
      raw: Map<String, dynamic>.unmodifiable(json),
    );
  }
}

class EkeAIRecommendationResponse {
  final List<EkeAIContent> items;
  final String? message;
  final String? apiVersion;
  final Map<String, dynamic> raw;

  const EkeAIRecommendationResponse({
    required this.items,
    this.message,
    this.apiVersion,
    required this.raw,
  });

  factory EkeAIRecommendationResponse.fromJson(Map<String, dynamic> json) {
    return EkeAIRecommendationResponse(
      items: List<EkeAIContent>.unmodifiable(_extractContents(json)),
      message:
          (json['message'] ??
                  json['answer'] ??
                  json['response'] ??
                  json['text'])
              ?.toString(),
      apiVersion: json['api_version']?.toString(),
      raw: Map<String, dynamic>.unmodifiable(json),
    );
  }
}

class EkeAIExplanation {
  final String? explanation;
  final String? apiVersion;
  final Map<String, dynamic> raw;

  const EkeAIExplanation({
    this.explanation,
    this.apiVersion,
    required this.raw,
  });

  factory EkeAIExplanation.fromJson(Map<String, dynamic> json) {
    return EkeAIExplanation(
      explanation:
          (json['explanation'] ??
                  json['reason'] ??
                  json['message'] ??
                  json['text'])
              ?.toString(),
      apiVersion: json['api_version']?.toString(),
      raw: Map<String, dynamic>.unmodifiable(json),
    );
  }
}

List<EkeAIContent> _extractContents(Map<String, dynamic> json) {
  Object? candidate =
      json['results'] ??
      json['recommendations'] ??
      json['items'] ??
      json['contents'] ??
      json['candidates'];

  if (candidate is Map<String, dynamic>) {
    candidate =
        candidate['results'] ??
        candidate['items'] ??
        candidate['recommendations'] ??
        candidate['contents'];
  }

  if (candidate is! List) return const <EkeAIContent>[];

  return candidate
      .whereType<Map>()
      .map(
        (item) => EkeAIContent.fromJson(
          item.map((key, value) => MapEntry(key.toString(), value)),
        ),
      )
      .where((item) => item.id.isNotEmpty || item.title.isNotEmpty)
      .toList(growable: false);
}
