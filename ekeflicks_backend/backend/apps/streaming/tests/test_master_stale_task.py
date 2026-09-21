import json
from types import SimpleNamespace
from unittest.mock import patch

from django.test import TestCase
from django.utils import timezone

from apps.streaming.tasks import (
    _video_asset_source_identity,
    analyze_video_asset,
)
from core.models import (
    Content,
    MediaAnalysisReport,
    VideoAsset,
)


class MasterTaskRaceTests(TestCase):

    def setUp(self):
        self.content = Content.objects.create(
            title="V11D master race",
            type="movie",
        )

        self.asset = VideoAsset.objects.create(
            content=self.content,
            source_file_path=(
                "uploads/test/master.mp4"
            ),
            source_file_url="",
            source_file_size_bytes=100,
            source_uploaded_at=timezone.now(),
            delivery_level="distribution",
        )

        self.report = (
            MediaAnalysisReport.objects.create(
                asset=self.asset,
                status="pending",
            )
        )

        self.ffprobe_result = SimpleNamespace(
            stdout=json.dumps({
                "streams": [
                    {
                        "codec_type": "audio",
                        "codec_name": "aac",
                        "channels": 2,
                        "sample_rate": "48000",
                        "bit_rate": "128000",
                    },
                ],
                "format": {
                    "duration": "60.0",
                    "format_name": "mov",
                    "bit_rate": "128000",
                },
            }),
            stderr="",
            returncode=0,
        )

    def _replace_source_and_reset_report(self):
        replacement_time = timezone.now()

        VideoAsset.objects.filter(
            pk=self.asset.pk
        ).update(
            source_file_path=(
                "uploads/test/master.mp4"
            ),
            source_file_url="",
            source_file_size_bytes=200,
            source_uploaded_at=replacement_time,
        )

        MediaAnalysisReport.objects.filter(
            asset_id=self.asset.pk
        ).update(
            status="pending",
            error_message="",
            flags=[],
            moderation_scores={},
            detected_events=[],
            technical_metadata={},
            analyzed_at=None,
        )

    def _conformity(self):
        return {
            "status": "conform",
            "blocking": False,
            "blocking_errors": [],
            "warnings": [],
            "checks": [],
            "specification_version": "TEST",
        }

    @patch(
        "apps.streaming.tasks."
        "_master_technical_specification"
    )
    @patch(
        "apps.streaming.tasks."
        "evaluate_master_conformity"
    )
    @patch(
        "apps.streaming.tasks."
        "_run_advanced_qc"
    )
    @patch(
        "apps.streaming.tasks."
        "subprocess.run"
    )
    @patch(
        "apps.streaming.tasks."
        "_source_input"
    )
    def test_current_source_success_persists_identity(
        self,
        source_input,
        subprocess_run,
        advanced_qc,
        evaluate,
        specification,
    ):
        source_input.return_value = (
            "/tmp/v11-current.mov"
        )

        subprocess_run.return_value = (
            self.ffprobe_result
        )

        advanced_qc.return_value = (
            {},
            [],
        )

        specification.return_value = object()
        evaluate.return_value = self._conformity()

        expected_identity = (
            _video_asset_source_identity(
                self.asset
            )
        )

        result = analyze_video_asset.run(
            str(self.asset.pk)
        )

        self.report.refresh_from_db()

        self.assertEqual(
            self.report.technical_metadata.get(
                "source_identity"
            ),
            expected_identity,
        )

        self.assertNotEqual(
            result["status"],
            "stale",
        )

    @patch(
        "apps.streaming.tasks."
        "_master_technical_specification"
    )
    @patch(
        "apps.streaming.tasks."
        "evaluate_master_conformity"
    )
    @patch(
        "apps.streaming.tasks."
        "_run_advanced_qc"
    )
    @patch(
        "apps.streaming.tasks."
        "subprocess.run"
    )
    @patch(
        "apps.streaming.tasks."
        "_source_input"
    )
    def test_old_success_cannot_overwrite_replacement(
        self,
        source_input,
        subprocess_run,
        advanced_qc,
        evaluate,
        specification,
    ):
        source_input.return_value = (
            "/tmp/v11-old-success.mov"
        )

        subprocess_run.return_value = (
            self.ffprobe_result
        )

        advanced_qc.return_value = (
            {},
            [],
        )

        specification.return_value = object()

        def replace_then_conform(**kwargs):
            self._replace_source_and_reset_report()
            return self._conformity()

        evaluate.side_effect = replace_then_conform

        old_identity = (
            _video_asset_source_identity(
                self.asset
            )
        )

        result = analyze_video_asset.run(
            str(self.asset.pk)
        )

        self.asset.refresh_from_db()
        self.report.refresh_from_db()

        self.assertEqual(
            result["status"],
            "stale",
        )

        self.assertEqual(
            result["stage"],
            "before_commit",
        )

        self.assertNotEqual(
            _video_asset_source_identity(
                self.asset
            ),
            old_identity,
        )

        self.assertEqual(
            self.report.status,
            "pending",
        )

        self.assertEqual(
            self.report.technical_metadata,
            {},
        )

        self.assertIsNone(
            self.report.analyzed_at,
        )

        self.assertEqual(
            self.report.error_message,
            "",
        )

    @patch(
        "apps.streaming.tasks."
        "_run_advanced_qc"
    )
    @patch(
        "apps.streaming.tasks."
        "subprocess.run"
    )
    @patch(
        "apps.streaming.tasks."
        "_source_input"
    )
    def test_old_failure_cannot_overwrite_replacement(
        self,
        source_input,
        subprocess_run,
        advanced_qc,
    ):
        source_input.return_value = (
            "/tmp/v11-old-failure.mov"
        )

        subprocess_run.return_value = (
            self.ffprobe_result
        )

        def replace_then_fail(*args, **kwargs):
            self._replace_source_and_reset_report()

            raise RuntimeError(
                "old worker failure"
            )

        advanced_qc.side_effect = (
            replace_then_fail
        )

        old_identity = (
            _video_asset_source_identity(
                self.asset
            )
        )

        result = analyze_video_asset.run(
            str(self.asset.pk)
        )

        self.asset.refresh_from_db()
        self.report.refresh_from_db()

        self.assertEqual(
            result["status"],
            "stale",
        )

        self.assertEqual(
            result["stage"],
            "exception",
        )

        self.assertNotEqual(
            _video_asset_source_identity(
                self.asset
            ),
            old_identity,
        )

        self.assertEqual(
            self.report.status,
            "pending",
        )

        self.assertEqual(
            self.report.error_message,
            "",
        )

        self.assertEqual(
            self.report.technical_metadata,
            {},
        )

        self.assertIsNone(
            self.report.analyzed_at,
        )
