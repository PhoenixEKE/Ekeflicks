from django.db import IntegrityError, transaction
from django.test import TestCase

from core.models import (
    Content,
    Season,
    TrailerAnalysisReport,
)


class TrailerAnalysisReportModelTests(TestCase):
    @classmethod
    def setUpTestData(cls):
        cls.movie = Content.objects.create(
            title="Trailer QC Movie",
            type="movie",
        )

        cls.series = Content.objects.create(
            title="Trailer QC Series",
            type="series",
        )

        cls.season = Season.objects.create(
            content=cls.series,
            season_number=1,
            title="Season 1",
        )

    def test_content_target_is_allowed(self):
        report = TrailerAnalysisReport.objects.create(
            content=self.movie,
            source_path=(
                "uploads/test/movie/"
                "trailer_original.mov"
            ),
            source_size_bytes=123456,
        )

        self.assertEqual(
            report.status,
            TrailerAnalysisReport.STATUS_PENDING,
        )

        self.assertEqual(
            report.content,
            self.movie,
        )

        self.assertIsNone(
            report.season,
        )

        self.assertEqual(
            self.movie.trailer_analysis_report,
            report,
        )

    def test_season_target_is_allowed(self):
        report = TrailerAnalysisReport.objects.create(
            season=self.season,
            source_path=(
                "uploads/test/season/"
                "trailer_original.mp4"
            ),
            source_size_bytes=654321,
        )

        self.assertEqual(
            report.season,
            self.season,
        )

        self.assertIsNone(
            report.content,
        )

        self.assertEqual(
            self.season.trailer_analysis_report,
            report,
        )

    def test_report_without_target_is_rejected(self):
        with self.assertRaises(
            IntegrityError
        ):
            with transaction.atomic():
                TrailerAnalysisReport.objects.create(
                    source_path=(
                        "uploads/test/no-target.mov"
                    ),
                )

    def test_report_with_both_targets_is_rejected(self):
        with self.assertRaises(
            IntegrityError
        ):
            with transaction.atomic():
                TrailerAnalysisReport.objects.create(
                    content=self.movie,
                    season=self.season,
                    source_path=(
                        "uploads/test/"
                        "both-targets.mov"
                    ),
                )

    def test_content_has_only_one_report(self):
        TrailerAnalysisReport.objects.create(
            content=self.movie,
        )

        with self.assertRaises(
            IntegrityError
        ):
            with transaction.atomic():
                TrailerAnalysisReport.objects.create(
                    content=self.movie,
                )

    def test_season_has_only_one_report(self):
        TrailerAnalysisReport.objects.create(
            season=self.season,
        )

        with self.assertRaises(
            IntegrityError
        ):
            with transaction.atomic():
                TrailerAnalysisReport.objects.create(
                    season=self.season,
                )
