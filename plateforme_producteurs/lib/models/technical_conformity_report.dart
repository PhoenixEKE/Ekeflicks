enum TechnicalConformityDisplayStatus {
  conform,
  nonConform,
  reviewRequired,
  analyzing,
  notStarted,
  failed,
  unknown,
}

class TechnicalConformityCheck {
  const TechnicalConformityCheck({
    required this.ruleKey,
    required this.label,
    required this.status,
    required this.blocking,
    this.expected,
    this.actual,
    this.message,
  });

  final String ruleKey;
  final String label;
  final String status;
  final bool blocking;
  final dynamic expected;
  final dynamic actual;
  final String? message;

  bool get isPassed => status == 'passed';

  bool get isFailed => status == 'failed';

  bool get isReview => status == 'review' || status == 'review_required';

  factory TechnicalConformityCheck.fromJson(Map<String, dynamic> json) {
    return TechnicalConformityCheck(
      ruleKey: _stringValue(json['rule_key']),
      label: _stringValue(
        json['label'],
        fallback: _stringValue(
          json['rule_key'],
          fallback: 'Contrôle technique',
        ),
      ),
      status: _stringValue(json['status'], fallback: 'unknown').toLowerCase(),
      blocking: _boolValue(json['blocking']),
      expected: json['expected'],
      actual: json['actual'],
      message: _nullableString(json['message']),
    );
  }
}

class TechnicalConformityReport {
  const TechnicalConformityReport({
    required this.analysisStatus,
    required this.status,
    required this.blocking,
    required this.specificationVersion,
    required this.checks,
    required this.blockingErrors,
    required this.warnings,
  });

  final String analysisStatus;

  /// Valeur backend :
  /// conform / non_conform / review_required / ...
  final String? status;

  final bool blocking;
  final String? specificationVersion;
  final List<TechnicalConformityCheck> checks;
  final List<String> blockingErrors;
  final List<String> warnings;

  TechnicalConformityDisplayStatus get displayStatus {
    final normalizedAnalysis = analysisStatus.trim().toLowerCase();

    final normalizedConformity = status?.trim().toLowerCase();

    if (normalizedAnalysis == 'pending' || normalizedAnalysis == 'analyzing') {
      return TechnicalConformityDisplayStatus.analyzing;
    }

    if (normalizedAnalysis == 'failed' ||
        normalizedConformity == 'analysis_failed') {
      return TechnicalConformityDisplayStatus.failed;
    }

    if (normalizedConformity == 'non_conform' || blocking) {
      return TechnicalConformityDisplayStatus.nonConform;
    }

    if (normalizedConformity == 'conform') {
      return TechnicalConformityDisplayStatus.conform;
    }

    if (normalizedConformity == 'review_required' ||
        normalizedAnalysis == 'review_required') {
      return TechnicalConformityDisplayStatus.reviewRequired;
    }

    if (normalizedAnalysis == 'not_started' || normalizedAnalysis.isEmpty) {
      return TechnicalConformityDisplayStatus.notStarted;
    }

    return TechnicalConformityDisplayStatus.unknown;
  }

  String get displayLabel {
    switch (displayStatus) {
      case TechnicalConformityDisplayStatus.conform:
        return 'Conforme';

      case TechnicalConformityDisplayStatus.nonConform:
        return 'Non conforme';

      case TechnicalConformityDisplayStatus.reviewRequired:
        return 'À vérifier';

      case TechnicalConformityDisplayStatus.analyzing:
        return 'Analyse en cours';

      case TechnicalConformityDisplayStatus.notStarted:
        return 'Analyse à effectuer';

      case TechnicalConformityDisplayStatus.failed:
        return 'Analyse impossible';

      case TechnicalConformityDisplayStatus.unknown:
        return 'État technique inconnu';
    }
  }

  bool get submissionBlocking {
    if (blocking) {
      return true;
    }

    return displayStatus != TechnicalConformityDisplayStatus.conform &&
        displayStatus != TechnicalConformityDisplayStatus.reviewRequired;
  }

  bool get submissionAllowed => !submissionBlocking;

  bool get humanReviewRequired =>
      displayStatus == TechnicalConformityDisplayStatus.reviewRequired;

  bool get hasDetails {
    return checks.isNotEmpty ||
        blockingErrors.isNotEmpty ||
        warnings.isNotEmpty ||
        specificationVersion != null;
  }

  /// Adapte le contrat Trailer QC exposé par Content / Season
  /// vers le parseur technique commun déjà utilisé par VideoAsset.
  ///
  /// Backend Trailer QC :
  /// - trailer_analysis_status
  /// - trailer_technical_conformity
  ///
  /// Aucune logique de conformité n'est dupliquée ici.
  factory TechnicalConformityReport.fromTrailerOwner(
    Map<String, dynamic> owner,
  ) {
    return TechnicalConformityReport.fromVideoAsset(<String, dynamic>{
      'analysis_status': owner['trailer_analysis_status'],
      'technical_conformity': owner['trailer_technical_conformity'],
    });
  }

  factory TechnicalConformityReport.fromVideoAsset(Map<String, dynamic> asset) {
    final analysisStatus = _stringValue(
      asset['analysis_status'],
      fallback: 'not_started',
    ).toLowerCase();

    final rawConformity = asset['technical_conformity'];

    if (rawConformity is! Map) {
      return TechnicalConformityReport(
        analysisStatus: analysisStatus,
        status: null,
        blocking: false,
        specificationVersion: null,
        checks: const [],
        blockingErrors: const [],
        warnings: const [],
      );
    }

    final conformity = Map<String, dynamic>.from(rawConformity);

    final rawChecks = conformity['checks'];

    final checks = rawChecks is List
        ? rawChecks
              .whereType<Map>()
              .map(
                (item) => TechnicalConformityCheck.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList(growable: false)
        : const <TechnicalConformityCheck>[];

    return TechnicalConformityReport(
      analysisStatus: analysisStatus,
      status: _nullableString(conformity['status'])?.toLowerCase(),
      blocking: _boolValue(conformity['blocking']),
      specificationVersion: _nullableString(
        conformity['specification_version'],
      ),
      checks: checks,
      blockingErrors: _stringList(conformity['blocking_errors']),
      warnings: _stringList(conformity['warnings']),
    );
  }
}

String _stringValue(dynamic value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';

  return text.isEmpty ? fallback : text;
}

String? _nullableString(dynamic value) {
  final text = value?.toString().trim() ?? '';

  return text.isEmpty ? null : text;
}

bool _boolValue(dynamic value) {
  if (value is bool) {
    return value;
  }

  final normalized = value?.toString().trim().toLowerCase();

  return normalized == 'true' || normalized == '1';
}

List<String> _stringList(dynamic value) {
  if (value is! List) {
    return const [];
  }

  return value
      .map((item) => item?.toString().trim() ?? '')
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}
