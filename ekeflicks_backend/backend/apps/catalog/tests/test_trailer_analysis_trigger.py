import ast
import inspect
from unittest.mock import patch

from django.test import TestCase

from apps.catalog import views
from apps.catalog.trailer_analysis import (
    schedule_trailer_analysis,
)
from core.models import (
    Content,
    Season,
    TrailerAnalysisReport,
)


class TrailerAnalysisTriggerTests(TestCase):
    def setUp(self):
        self.movie = Content.objects.create(
            title="Trailer trigger movie",
            type="movie",
            producer_submission_status="draft",
        )

        self.series = Content.objects.create(
            title="Trailer trigger series",
            type="series",
            producer_submission_status="draft",
        )

        self.season = Season.objects.create(
            content=self.series,
            season_number=1,
            title="Saison 1",
        )

    @patch(
        "apps.catalog.trailer_analysis."
        "analyze_trailer.delay"
    )
    def test_content_report_created_and_task_after_commit(
        self,
        mocked_delay,
    ):
        self.movie.trailer_temp_path = (
            "uploads/test/content-trailer.mp4"
        )
        self.movie.save(
            update_fields=[
                "trailer_temp_path",
                "updated_at",
            ]
        )

        with self.captureOnCommitCallbacks(
            execute=True
        ) as callbacks:
            report = schedule_trailer_analysis(
                self.movie
            )

        self.assertIsNotNone(report)

        report.refresh_from_db()

        self.assertEqual(
            report.content_id,
            self.movie.pk,
        )
        self.assertIsNone(
            report.season_id
        )
        self.assertEqual(
            report.source_path,
            self.movie.trailer_temp_path,
        )
        self.assertEqual(
            report.status,
            TrailerAnalysisReport.STATUS_PENDING,
        )

        self.assertEqual(
            len(callbacks),
            1,
        )

        mocked_delay.assert_called_once_with(
            str(report.pk)
        )

    @patch(
        "apps.catalog.trailer_analysis."
        "analyze_trailer.delay"
    )
    def test_season_report_created_and_task_after_commit(
        self,
        mocked_delay,
    ):
        self.season.trailer_temp_path = (
            "uploads/test/season-trailer.mp4"
        )
        self.season.save(
            update_fields=[
                "trailer_temp_path",
                "updated_at",
            ]
        )

        with self.captureOnCommitCallbacks(
            execute=True
        ) as callbacks:
            report = schedule_trailer_analysis(
                self.season
            )

        report.refresh_from_db()

        self.assertEqual(
            report.season_id,
            self.season.pk,
        )
        self.assertIsNone(
            report.content_id
        )
        self.assertEqual(
            report.source_path,
            self.season.trailer_temp_path,
        )
        self.assertEqual(
            report.status,
            TrailerAnalysisReport.STATUS_PENDING,
        )

        self.assertEqual(
            len(callbacks),
            1,
        )

        mocked_delay.assert_called_once_with(
            str(report.pk)
        )

    @patch(
        "apps.catalog.trailer_analysis."
        "analyze_trailer.delay"
    )
    def test_replacement_resets_existing_content_report(
        self,
        mocked_delay,
    ):
        old = TrailerAnalysisReport.objects.create(
            content=self.movie,
            source_path="uploads/test/old.mp4",
            status=TrailerAnalysisReport.STATUS_FAILED,
            technical_metadata={
                "old": True,
            },
            flags=[
                "old-flag",
            ],
            error_message="old error",
        )

        self.movie.trailer_temp_path = (
            "uploads/test/new.mp4"
        )
        self.movie.save(
            update_fields=[
                "trailer_temp_path",
                "updated_at",
            ]
        )

        with self.captureOnCommitCallbacks(
            execute=True
        ):
            report = schedule_trailer_analysis(
                self.movie
            )

        self.assertEqual(
            report.pk,
            old.pk,
        )

        report.refresh_from_db()

        self.assertEqual(
            report.source_path,
            "uploads/test/new.mp4",
        )
        self.assertEqual(
            report.status,
            TrailerAnalysisReport.STATUS_PENDING,
        )
        self.assertEqual(
            report.technical_metadata,
            {},
        )
        self.assertEqual(
            report.flags,
            [],
        )
        self.assertEqual(
            report.error_message,
            "",
        )
        self.assertIsNone(
            report.analyzed_at
        )

        mocked_delay.assert_called_once_with(
            str(report.pk)
        )

    @patch(
        "apps.catalog.trailer_analysis."
        "analyze_trailer.delay"
    )
    def test_replacement_resets_existing_season_report(
        self,
        mocked_delay,
    ):
        old = TrailerAnalysisReport.objects.create(
            season=self.season,
            source_path="uploads/test/season-old.mp4",
            status=TrailerAnalysisReport.STATUS_FAILED,
            technical_metadata={
                "old": True,
            },
            flags=[
                "old-season-flag",
            ],
            error_message="old season error",
        )

        self.season.trailer_temp_path = (
            "uploads/test/season-new.mp4"
        )
        self.season.save(
            update_fields=[
                "trailer_temp_path",
                "updated_at",
            ]
        )

        with self.captureOnCommitCallbacks(
            execute=True
        ):
            report = schedule_trailer_analysis(
                self.season
            )

        self.assertEqual(
            report.pk,
            old.pk,
        )

        report.refresh_from_db()

        self.assertEqual(
            report.source_path,
            "uploads/test/season-new.mp4",
        )
        self.assertEqual(
            report.status,
            TrailerAnalysisReport.STATUS_PENDING,
        )
        self.assertEqual(
            report.technical_metadata,
            {},
        )
        self.assertEqual(
            report.flags,
            [],
        )
        self.assertEqual(
            report.error_message,
            "",
        )
        self.assertIsNone(
            report.analyzed_at
        )

        mocked_delay.assert_called_once_with(
            str(report.pk)
        )

    @patch(
        "apps.catalog.trailer_analysis."
        "analyze_trailer.delay"
    )
    def test_empty_source_creates_no_report_and_no_task(
        self,
        mocked_delay,
    ):
        self.movie.trailer_temp_path = ""

        result = schedule_trailer_analysis(
            self.movie
        )

        self.assertIsNone(result)

        self.assertFalse(
            TrailerAnalysisReport.objects.filter(
                content=self.movie
            ).exists()
        )

        mocked_delay.assert_not_called()

    def test_views_have_exactly_content_and_season_trigger(
        self,
    ):
        source = inspect.getsource(
            views
        )

        tree = ast.parse(source)

        calls = []

        for node in ast.walk(tree):
            if not (
                isinstance(node, ast.Call)
                and isinstance(node.func, ast.Name)
                and node.func.id
                == "_schedule_trailer_analysis"
                and len(node.args) == 1
                and isinstance(
                    node.args[0],
                    ast.Name,
                )
            ):
                continue

            calls.append(
                node.args[0].id
            )

        self.assertEqual(
            calls.count("content"),
            1,
        )

        self.assertEqual(
            calls.count("season"),
            1,
        )

        self.assertEqual(
            len(calls),
            2,
        )
