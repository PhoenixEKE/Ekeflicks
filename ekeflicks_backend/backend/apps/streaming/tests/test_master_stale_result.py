from unittest.mock import patch

from django.test import TestCase
from django.utils import timezone

from apps.streaming.tasks import (
    _video_asset_source_identity,
)
from core.models import (
    Content,
    MediaAnalysisReport,
    VideoAsset,
)


class MasterSourceIdentityTests(TestCase):

    def setUp(self):
        self.content = Content.objects.create(
            title="V11 stale master",
            type="movie",
        )

        self.asset = VideoAsset.objects.create(
            content=self.content,
            source_file_path=(
                "uploads/test/master.mp4"
            ),
            source_file_size_bytes=100,
            source_uploaded_at=timezone.now(),
        )

    def test_source_identity_changes_when_upload_generation_changes(
        self,
    ):
        first = _video_asset_source_identity(
            self.asset
        )

        self.asset.source_uploaded_at = (
            timezone.now()
        )
        self.asset.save(
            update_fields=[
                "source_uploaded_at",
                "updated_at",
            ]
        )

        second = _video_asset_source_identity(
            self.asset
        )

        self.assertNotEqual(
            first,
            second,
        )


class MasterSubmissionFreshnessTests(TestCase):

    def setUp(self):
        self.content = Content.objects.create(
            title="V11 submission freshness",
            type="movie",
        )

        self.asset = VideoAsset.objects.create(
            content=self.content,
            source_file_path=(
                "uploads/test/current.mp4"
            ),
            source_file_size_bytes=100,
            source_uploaded_at=timezone.now(),
        )

    def test_passed_report_for_old_source_is_not_current(
        self,
    ):
        from apps.catalog.submission_conformity import (
            _report_matches_current_source,
        )

        old_identity = {
            "path": "uploads/test/current.mp4",
            "url": "",
            "size_bytes": 100,
            "uploaded_at": (
                "2000-01-01T00:00:00+00:00"
            ),
        }

        report = (
            MediaAnalysisReport.objects.create(
                asset=self.asset,
                status="passed",
                technical_metadata={
                    "source_identity": old_identity,
                },
            )
        )

        self.assertFalse(
            _report_matches_current_source(
                report,
                self.asset,
            )
        )

    def test_passed_report_for_current_source_is_current(
        self,
    ):
        from apps.catalog.submission_conformity import (
            _report_matches_current_source,
        )

        identity = (
            _video_asset_source_identity(
                self.asset
            )
        )

        report = (
            MediaAnalysisReport.objects.create(
                asset=self.asset,
                status="passed",
                technical_metadata={
                    "source_identity": identity,
                },
            )
        )

        self.assertTrue(
            _report_matches_current_source(
                report,
                self.asset,
            )
        )
