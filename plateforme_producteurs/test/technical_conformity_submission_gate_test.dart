import 'package:flutter_test/flutter_test.dart';
import 'package:plateforme_producteurs/models/technical_conformity_report.dart';

TechnicalConformityReport report({
  required String analysisStatus,
  String? status,
  bool blocking = false,
}) {
  return TechnicalConformityReport(
    analysisStatus: analysisStatus,
    status: status,
    blocking: blocking,
    specificationVersion: '1.3',
    checks: const [],
    blockingErrors: const [],
    warnings: const [],
  );
}

void main() {
  group('A5.11F submission gate', () {
    test('conform is not blocking', () {
      final value = report(analysisStatus: 'passed', status: 'conform');

      expect(value.displayStatus, TechnicalConformityDisplayStatus.conform);
      expect(value.submissionBlocking, isFalse);
    });

    test('passed non-blocking review required is blocked', () {
      final value = report(analysisStatus: 'passed', status: 'review_required');

      expect(
        value.displayStatus,
        TechnicalConformityDisplayStatus.reviewRequired,
      );
      expect(value.submissionBlocking, isTrue);
    });

    test('analysis-level review required remains blocking', () {
      final value = report(
        analysisStatus: 'review_required',
        status: 'review_required',
      );

      expect(
        value.displayStatus,
        TechnicalConformityDisplayStatus.reviewRequired,
      );
      expect(value.submissionBlocking, isTrue);
    });

    test('blocking review required remains blocking', () {
      final value = report(
        analysisStatus: 'passed',
        status: 'review_required',
        blocking: true,
      );

      expect(value.submissionBlocking, isTrue);
    });

    test('non conform is blocking', () {
      final value = report(
        analysisStatus: 'passed',
        status: 'non_conform',
        blocking: true,
      );

      expect(value.submissionBlocking, isTrue);
    });

    test('analyzing is blocking', () {
      final value = report(analysisStatus: 'analyzing');

      expect(value.submissionBlocking, isTrue);
    });

    test('not started is blocking', () {
      final value = report(analysisStatus: 'not_started');

      expect(value.submissionBlocking, isTrue);
    });

    test('failed is blocking', () {
      final value = report(analysisStatus: 'failed');

      expect(value.submissionBlocking, isTrue);
    });

    test('unknown is blocking', () {
      final value = report(
        analysisStatus: 'unexpected_state',
        status: 'unexpected_state',
      );

      expect(value.displayStatus, TechnicalConformityDisplayStatus.unknown);
      expect(value.submissionBlocking, isTrue);
    });
  });
}
