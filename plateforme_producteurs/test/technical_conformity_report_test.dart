import 'package:flutter_test/flutter_test.dart';
import 'package:plateforme_producteurs/models/technical_conformity_report.dart';

void main() {
  group('TechnicalConformityReport', () {
    test('conform => Conforme', () {
      final report = TechnicalConformityReport.fromVideoAsset({
        'analysis_status': 'passed',
        'technical_conformity': {
          'status': 'conform',
          'blocking': false,
          'specification_version': '1.3',
          'checks': [
            {
              'rule_key': 'master.container.distribution',
              'label': 'Conteneur',
              'status': 'passed',
              'blocking': true,
              'expected': ['mp4'],
              'actual': 'mp4',
            },
          ],
          'blocking_errors': [],
          'warnings': [],
        },
      });

      expect(report.displayStatus, TechnicalConformityDisplayStatus.conform);

      expect(report.displayLabel, 'Conforme');

      expect(report.submissionBlocking, isFalse);

      expect(report.specificationVersion, '1.3');

      expect(report.checks.length, 1);
    });

    test('non conform blocking => Non conforme', () {
      final report = TechnicalConformityReport.fromVideoAsset({
        'analysis_status': 'passed',
        'technical_conformity': {
          'status': 'non_conform',
          'blocking': true,
          'checks': [
            {
              'rule_key': 'master.constant_frame_rate',
              'label': 'Framerate constant',
              'status': 'failed',
              'blocking': true,
            },
          ],
          'blocking_errors': ['Le master utilise un framerate variable.'],
          'warnings': [],
        },
      });

      expect(report.displayStatus, TechnicalConformityDisplayStatus.nonConform);

      expect(report.displayLabel, 'Non conforme');

      expect(report.submissionBlocking, isTrue);

      expect(report.blockingErrors, isNotEmpty);

      expect(report.checks.single.isFailed, isTrue);
    });

    test('review required => À vérifier', () {
      final report = TechnicalConformityReport.fromVideoAsset({
        'analysis_status': 'review_required',
        'technical_conformity': {
          'status': 'review_required',
          'blocking': false,
          'checks': [],
          'blocking_errors': [],
          'warnings': ['Métadonnée colorimétrique absente.'],
        },
      });

      expect(
        report.displayStatus,
        TechnicalConformityDisplayStatus.reviewRequired,
      );

      expect(report.displayLabel, 'À vérifier');

      expect(report.submissionBlocking, isTrue);
    });

    test('analysis pending sans conformité => Analyse en cours', () {
      final report = TechnicalConformityReport.fromVideoAsset({
        'analysis_status': 'analyzing',
        'technical_conformity': null,
      });

      expect(report.displayStatus, TechnicalConformityDisplayStatus.analyzing);

      expect(report.displayLabel, 'Analyse en cours');

      expect(report.submissionBlocking, isTrue);
    });

    test('not started sans conformité => Analyse à effectuer', () {
      final report = TechnicalConformityReport.fromVideoAsset({
        'analysis_status': 'not_started',
        'technical_conformity': null,
      });

      expect(report.displayStatus, TechnicalConformityDisplayStatus.notStarted);

      expect(report.displayLabel, 'Analyse à effectuer');

      expect(report.submissionBlocking, isTrue);
    });

    test('failed => Analyse impossible', () {
      final report = TechnicalConformityReport.fromVideoAsset({
        'analysis_status': 'failed',
        'technical_conformity': null,
      });

      expect(report.displayStatus, TechnicalConformityDisplayStatus.failed);

      expect(report.displayLabel, 'Analyse impossible');

      expect(report.submissionBlocking, isTrue);
    });

    test('audit production review_required + null reste À vérifier', () {
      final report = TechnicalConformityReport.fromVideoAsset({
        'analysis_status': 'review_required',
        'technical_conformity': null,
        'delivery_level': 'distribution',
      });

      expect(
        report.displayStatus,
        TechnicalConformityDisplayStatus.reviewRequired,
      );

      expect(report.displayLabel, 'À vérifier');

      expect(report.submissionBlocking, isTrue);
    });

    test('trailer owner passed => Conforme', () {
      final report = TechnicalConformityReport.fromTrailerOwner({
        'trailer_analysis_status': 'passed',
        'trailer_technical_conformity': {
          'status': 'conform',
          'blocking': false,
          'specification_version': 'eke-trailer-qc-v1',
          'checks': [
            {
              'rule_key': 'trailer.video_codec',
              'label': 'Codec vidéo',
              'status': 'passed',
              'blocking': true,
            },
          ],
          'blocking_errors': [],
          'warnings': [],
        },
      });

      expect(report.displayStatus, TechnicalConformityDisplayStatus.conform);
      expect(report.displayLabel, 'Conforme');
      expect(report.submissionBlocking, isFalse);
      expect(report.specificationVersion, 'eke-trailer-qc-v1');
      expect(report.checks.length, 1);
    });

    test('trailer owner analyzing => Analyse en cours', () {
      final report = TechnicalConformityReport.fromTrailerOwner({
        'trailer_analysis_status': 'analyzing',
        'trailer_technical_conformity': null,
      });

      expect(report.displayStatus, TechnicalConformityDisplayStatus.analyzing);
      expect(report.displayLabel, 'Analyse en cours');
      expect(report.submissionBlocking, isTrue);
    });

    test('trailer owner review required sans conformité', () {
      final report = TechnicalConformityReport.fromTrailerOwner({
        'trailer_analysis_status': 'review_required',
        'trailer_technical_conformity': null,
      });

      expect(
        report.displayStatus,
        TechnicalConformityDisplayStatus.reviewRequired,
      );
      expect(report.displayLabel, 'À vérifier');
      expect(report.submissionBlocking, isTrue);
    });

    test('trailer owner sans rapport => Analyse à effectuer', () {
      final report = TechnicalConformityReport.fromTrailerOwner({
        'trailer_analysis_status': 'not_started',
        'trailer_technical_conformity': null,
      });

      expect(report.displayStatus, TechnicalConformityDisplayStatus.notStarted);
      expect(report.displayLabel, 'Analyse à effectuer');
      expect(report.submissionBlocking, isTrue);
    });

    test('trailer owner conformité malformée => null toléré', () {
      final report = TechnicalConformityReport.fromTrailerOwner({
        'trailer_analysis_status': 'passed',
        'trailer_technical_conformity': 'invalid',
      });

      expect(report.displayStatus, TechnicalConformityDisplayStatus.unknown);
      expect(report.checks, isEmpty);
      expect(report.blockingErrors, isEmpty);
      expect(report.warnings, isEmpty);
      expect(report.submissionBlocking, isTrue);
    });

    test('parser tolère payload incomplet', () {
      final report = TechnicalConformityReport.fromVideoAsset(
        <String, dynamic>{},
      );

      expect(report.displayStatus, TechnicalConformityDisplayStatus.notStarted);

      expect(report.checks, isEmpty);

      expect(report.blockingErrors, isEmpty);

      expect(report.warnings, isEmpty);
    });
  });
}
