from unittest.mock import patch

from django.conf import settings
from django.contrib.auth import get_user_model
from django.urls import reverse
from django.utils import timezone
from rest_framework import status
from rest_framework.test import APITestCase

from core.models import (
    Content,
    ProducerAccount,
    ProducerAgreement,
    Season,
    TrailerAnalysisReport,
)


User = get_user_model()


class TrailerAnalysisRetryApiTests(APITestCase):
    def _create_active_producer(self, email):
        producer = User.objects.create_user(
            email=email,
            password="test-password",
            is_producer=True,
        )
        producer.is_verified = True
        producer.save(update_fields=["is_verified"])

        producer_account = ProducerAccount.objects.create(
            user=producer,
            status=ProducerAccount.STATUS_ACTIVE,
            activated_at=timezone.now(),
        )

        ProducerAgreement.objects.create(
            producer_account=producer_account,
            contract_version=(
                settings.PRODUCER_AGREEMENT_ACCEPTED_VERSIONS[0]
            ),
            status=ProducerAgreement.STATUS_SIGNED,
            accepted_at=timezone.now(),
            signed_at=timezone.now(),
        )

        return producer

    def setUp(self):
        self.producer = self._create_active_producer(
            "retry@example.com"
        )

        self.other_producer = self._create_active_producer(
            "retry-other@example.com"
        )

        self.movie = Content.objects.create(
            title="Retry Trailer Movie",
            type="movie",
            producer=self.producer,
            producer_submission_status="draft",
            trailer_temp_path=(
                "uploads/test/retry-content.mp4"
            ),
        )

        self.series = Content.objects.create(
            title="Retry Trailer Series",
            type="series",
            producer=self.producer,
            producer_submission_status="draft",
        )

        self.season = Season.objects.create(
            content=self.series,
            season_number=1,
            title="Season 1",
            trailer_temp_path=(
                "uploads/test/retry-season.mp4"
            ),
        )

    def _content_url(self):
        return reverse(
            "content-trailer-analysis-retry",
            kwargs={"pk": self.movie.pk},
        )

    def _season_url(self):
        return reverse(
            "season-trailer-analysis-retry",
            kwargs={"pk": self.season.pk},
        )

    @patch(
        "apps.catalog.trailer_analysis."
        "analyze_trailer.delay"
    )
    def test_content_failed_can_retry(
        self,
        mocked_delay,
    ):
        report = TrailerAnalysisReport.objects.create(
            content=self.movie,
            source_path=self.movie.trailer_temp_path,
            status=TrailerAnalysisReport.STATUS_FAILED,
            technical_metadata={"old": True},
            flags=["old"],
            error_message="old error",
        )

        self.client.force_authenticate(
            user=self.producer
        )

        with self.captureOnCommitCallbacks(
            execute=True
        ):
            response = self.client.post(
                self._content_url(),
                {},
                format="json",
            )

        self.assertEqual(
            response.status_code,
            status.HTTP_200_OK,
        )

        report.refresh_from_db()

        self.assertEqual(
            report.status,
            TrailerAnalysisReport.STATUS_PENDING,
        )
        self.assertEqual(
            report.technical_metadata,
            {},
        )
        self.assertEqual(report.flags, [])
        self.assertEqual(report.error_message, "")
        self.assertIsNone(report.analyzed_at)

        mocked_delay.assert_called_once_with(
            str(report.pk)
        )

    @patch(
        "apps.catalog.trailer_analysis."
        "analyze_trailer.delay"
    )
    def test_season_failed_can_retry(
        self,
        mocked_delay,
    ):
        report = TrailerAnalysisReport.objects.create(
            season=self.season,
            source_path=self.season.trailer_temp_path,
            status=TrailerAnalysisReport.STATUS_FAILED,
            technical_metadata={"old": True},
            flags=["old"],
            error_message="old error",
        )

        self.client.force_authenticate(
            user=self.producer
        )

        with self.captureOnCommitCallbacks(
            execute=True
        ):
            response = self.client.post(
                self._season_url(),
                {},
                format="json",
            )

        self.assertEqual(
            response.status_code,
            status.HTTP_200_OK,
        )

        report.refresh_from_db()

        self.assertEqual(
            report.status,
            TrailerAnalysisReport.STATUS_PENDING,
        )
        self.assertEqual(
            report.technical_metadata,
            {},
        )
        self.assertEqual(report.flags, [])
        self.assertEqual(report.error_message, "")
        self.assertIsNone(report.analyzed_at)

        mocked_delay.assert_called_once_with(
            str(report.pk)
        )

    def test_content_non_failed_cannot_retry(self):
        TrailerAnalysisReport.objects.create(
            content=self.movie,
            source_path=self.movie.trailer_temp_path,
            status=TrailerAnalysisReport.STATUS_PENDING,
        )

        self.client.force_authenticate(
            user=self.producer
        )

        response = self.client.post(
            self._content_url(),
            {},
            format="json",
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_400_BAD_REQUEST,
        )

    def test_season_non_failed_cannot_retry(self):
        TrailerAnalysisReport.objects.create(
            season=self.season,
            source_path=self.season.trailer_temp_path,
            status=TrailerAnalysisReport.STATUS_PASSED,
        )

        self.client.force_authenticate(
            user=self.producer
        )

        response = self.client.post(
            self._season_url(),
            {},
            format="json",
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_400_BAD_REQUEST,
        )

    def test_content_other_producer_cannot_retry(self):
        TrailerAnalysisReport.objects.create(
            content=self.movie,
            source_path=self.movie.trailer_temp_path,
            status=TrailerAnalysisReport.STATUS_FAILED,
        )

        self.client.force_authenticate(
            user=self.other_producer
        )

        response = self.client.post(
            self._content_url(),
            {},
            format="json",
        )

        self.assertIn(
            response.status_code,
            (
                status.HTTP_403_FORBIDDEN,
                status.HTTP_404_NOT_FOUND,
            ),
        )

    def test_season_other_producer_cannot_retry(self):
        TrailerAnalysisReport.objects.create(
            season=self.season,
            source_path=self.season.trailer_temp_path,
            status=TrailerAnalysisReport.STATUS_FAILED,
        )

        self.client.force_authenticate(
            user=self.other_producer
        )

        response = self.client.post(
            self._season_url(),
            {},
            format="json",
        )

        self.assertIn(
            response.status_code,
            (
                status.HTTP_403_FORBIDDEN,
                status.HTTP_404_NOT_FOUND,
            ),
        )

    def test_content_without_report_cannot_retry(self):
        self.client.force_authenticate(
            user=self.producer
        )

        response = self.client.post(
            self._content_url(),
            {},
            format="json",
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_400_BAD_REQUEST,
        )

    def test_season_without_report_cannot_retry(self):
        self.client.force_authenticate(
            user=self.producer
        )

        response = self.client.post(
            self._season_url(),
            {},
            format="json",
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_400_BAD_REQUEST,
        )
