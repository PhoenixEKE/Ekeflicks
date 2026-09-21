from unittest.mock import patch

from django.core.files.base import ContentFile
from django.test import TestCase

from core.models import (
    Content,
    TechnicalSpecification,
    TrailerAnalysisReport,
)

from apps.streaming.tasks import (
    analyze_trailer,
)


class TrailerAnalysisTaskTests(TestCase):
    def setUp(self):
        self.content = Content.objects.create(
            title="Trailer task test",
            type="movie",
            producer_submission_status="draft",
        )

        self.path = (
            "uploads/test/"
            "trailer-task-source.mp4"
        )

        self.content.trailer_temp_path = (
            self.path
        )
        self.content.save(
            update_fields=[
                "trailer_temp_path",
                "updated_at",
            ]
        )

        self.report = (
            TrailerAnalysisReport.objects.create(
                content=self.content,
                source_path=self.path,
                status=(
                    TrailerAnalysisReport
                    .STATUS_PENDING
                ),
            )
        )

        TechnicalSpecification.objects.create(
            title="Trailer QC V1.7",
            version="1.7",
            is_published=True,
            sections=[
                {
                    "key": "trailer",
                    "items": [
                        {
                            "label": "Durée",
                            "value": "30-150",
                            "required": True,
                            "rule_key": (
                                "trailer.duration"
                            ),
                            "rule_type": (
                                "duration_range"
                            ),
                            "expected": {
                                "min_seconds": 30,
                                "max_seconds": 150,
                            },
                            "severity": "blocking",
                            "auto_validation": True,
                            "delivery_levels": [
                                "distribution"
                            ],
                        }
                    ],
                }
            ],
        )

    def _metadata(self):
        return {
            "format": {
                "format_name": "mp4",
                "filename": "test.mp4",
                "duration": "60",
                "bit_rate": "50000000",
            },
            "streams": [
                {
                    "codec_type": "video",
                    "codec_name": "h264",
                    "width": 1920,
                    "height": 1080,
                    "field_order": (
                        "progressive"
                    ),
                    "avg_frame_rate": "25/1",
                    "r_frame_rate": "25/1",
                    "bit_rate": "45000000",
                },
                {
                    "codec_type": "audio",
                    "codec_name": "aac",
                    "sample_rate": "48000",
                    "channels": 2,
                    "bit_rate": "256000",
                },
            ],
        }

    @patch(
        "apps.streaming.tasks."
        "_materialize_storage_input"
    )
    @patch(
        "apps.streaming.tasks."
        "_probe_output_media"
    )
    @patch(
        "apps.streaming.tasks."
        "_probe_frame_timing"
    )
    @patch(
        "apps.streaming.tasks."
        "default_storage.size"
    )
    def test_conform_report_is_saved(
        self,
        mocked_size,
        mocked_timing,
        mocked_probe,
        mocked_materialize,
    ):
        mocked_materialize.return_value = (
            "/tmp/trailer.mp4"
        )
        mocked_probe.return_value = (
            self._metadata()
        )
        mocked_timing.return_value = {
            "available": True,
            "is_constant": True,
        }
        mocked_size.return_value = 123456

        result = analyze_trailer(
            str(self.report.pk)
        )

        self.report.refresh_from_db()

        self.assertEqual(
            result["status"],
            TrailerAnalysisReport.STATUS_PASSED,
        )

        self.assertEqual(
            self.report.status,
            TrailerAnalysisReport.STATUS_PASSED,
        )

        self.assertEqual(
            self.report.source_path,
            self.path,
        )

        self.assertEqual(
            self.report.duration_seconds,
            60,
        )

        self.assertIn(
            "technical_specification_conformity",
            self.report.technical_metadata,
        )

    @patch(
        "apps.streaming.tasks."
        "_materialize_storage_input"
    )
    def test_stale_before_analysis_is_ignored(
        self,
        mocked_materialize,
    ):
        self.content.trailer_temp_path = (
            "uploads/test/new-trailer.mp4"
        )
        self.content.save(
            update_fields=[
                "trailer_temp_path",
                "updated_at",
            ]
        )

        result = analyze_trailer(
            str(self.report.pk)
        )

        self.report.refresh_from_db()

        self.assertEqual(
            result["status"],
            "stale",
        )

        mocked_materialize.assert_not_called()

        self.assertEqual(
            self.report.status,
            TrailerAnalysisReport.STATUS_PENDING,
        )

    @patch(
        "apps.streaming.tasks."
        "_materialize_storage_input"
    )
    @patch(
        "apps.streaming.tasks."
        "_probe_output_media"
    )
    @patch(
        "apps.streaming.tasks."
        "_probe_frame_timing"
    )
    @patch(
        "apps.streaming.tasks."
        "default_storage.size"
    )
    def test_stale_result_is_not_committed(
        self,
        mocked_size,
        mocked_timing,
        mocked_probe,
        mocked_materialize,
    ):
        mocked_materialize.return_value = (
            "/tmp/trailer.mp4"
        )

        def probe_side_effect(*args, **kwargs):
            self.content.refresh_from_db()

            self.content.trailer_temp_path = (
                "uploads/test/"
                "replacement.mp4"
            )

            self.content.save(
                update_fields=[
                    "trailer_temp_path",
                    "updated_at",
                ]
            )

            return self._metadata()

        mocked_probe.side_effect = (
            probe_side_effect
        )

        mocked_timing.return_value = {
            "available": True,
            "is_constant": True,
        }

        mocked_size.return_value = 123

        result = analyze_trailer(
            str(self.report.pk)
        )

        self.report.refresh_from_db()

        self.assertEqual(
            result["status"],
            "stale",
        )

        self.assertNotEqual(
            self.report.status,
            TrailerAnalysisReport.STATUS_PASSED,
        )

    @patch(
        "apps.streaming.tasks."
        "_materialize_storage_input"
    )
    def test_analysis_failure_is_persisted(
        self,
        mocked_materialize,
    ):
        mocked_materialize.side_effect = (
            RuntimeError(
                "Storage unavailable"
            )
        )

        result = analyze_trailer(
            str(self.report.pk)
        )

        self.report.refresh_from_db()

        self.assertEqual(
            result["status"],
            "failed",
        )

        self.assertEqual(
            self.report.status,
            TrailerAnalysisReport.STATUS_FAILED,
        )

        self.assertIn(
            "Storage unavailable",
            self.report.error_message,
        )
