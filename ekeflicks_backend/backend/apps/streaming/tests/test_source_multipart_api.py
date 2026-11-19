from unittest.mock import Mock, patch

from django.conf import settings
from django.core import signing
from django.test import override_settings
from django.urls import reverse
from django.utils import timezone
from rest_framework import status
from rest_framework.test import APITestCase

from core.models import (
    Content,
    MediaAnalysisReport,
    ProducerAccount,
    ProducerAgreement,
    User,
    VideoAsset,
)


@override_settings(
    MINIO_BUCKET='test-video-bucket',
)
class SourceMultipartApiTests(APITestCase):
    def setUp(self):
        self.producer = User.objects.create_user(
            email='multipart-producer@example.com',
            password='StrongPass123',
            is_producer=True,
        )
        self.producer.is_verified = True
        self.producer.save(
            update_fields=['is_verified']
        )

        account = ProducerAccount.objects.create(
            user=self.producer,
            status=ProducerAccount.STATUS_ACTIVE,
            activated_at=timezone.now(),
        )

        ProducerAgreement.objects.create(
            producer_account=account,
            contract_version=(
                settings
                .PRODUCER_AGREEMENT_ACCEPTED_VERSIONS[0]
            ),
            status=ProducerAgreement.STATUS_SIGNED,
            accepted_at=timezone.now(),
            signed_at=timezone.now(),
        )

        self.content = Content.objects.create(
            title='Multipart Movie',
            type='movie',
            producer=self.producer,
        )

        self.asset = VideoAsset.objects.create(
            content=self.content,
            title='Multipart Master',
        )

        self.client.force_authenticate(
            user=self.producer
        )

    def _url(self, action):
        return reverse(
            f'video-asset-{action}',
            args=[self.asset.id],
        )

    def _payload(
        self,
        *,
        user_id=None,
        size_bytes=100,
        part_size=64,
        part_count=2,
    ):
        return {
            'asset_id': str(self.asset.id),
            'user_id': str(
                user_id or self.producer.id
            ),
            'bucket': 'test-video-bucket',
            'object_key': (
                f'uploads/producer_{self.producer.id}/'
                f'asset_{self.asset.id}/video_original.mp4'
            ),
            'upload_id': 'upload-123',
            'size_bytes': size_bytes,
            'part_size': part_size,
            'part_count': part_count,
        }

    def _token(self, **kwargs):
        return signing.dumps(
            self._payload(**kwargs),
            salt='streaming-source-multipart',
            compress=True,
        )

    @patch(
        'apps.streaming.views.'
        'minio_internal_client'
    )
    def test_start_creates_multipart_session(
        self,
        internal_factory,
    ):
        storage = internal_factory.return_value
        storage.create_multipart_upload.return_value = {
            'UploadId': 'upload-123',
        }

        response = self.client.post(
            self._url('source-multipart-start'),
            {
                'filename': 'master.mp4',
                'size_bytes': 4276912571,
            },
            format='json',
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_200_OK,
        )
        self.assertTrue(
            response.data['upload_token']
        )
        self.assertEqual(
            response.data['part_size'],
            64 * 1024 * 1024,
        )
        self.assertGreater(
            response.data['part_count'],
            1,
        )

        storage.create_multipart_upload.assert_called_once()

    @patch(
        'apps.streaming.views.'
        'minio_public_upload_client'
    )
    def test_part_returns_presigned_upload_url(
        self,
        public_factory,
    ):
        storage = public_factory.return_value
        storage.generate_presigned_url.return_value = (
            'https://upload.test/part-2'
        )

        response = self.client.post(
            self._url('source-multipart-part'),
            {
                'upload_token': self._token(),
                'part_number': 2,
            },
            format='json',
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_200_OK,
        )
        self.assertEqual(
            response.data['part_number'],
            2,
        )
        self.assertEqual(
            response.data['upload_url'],
            'https://upload.test/part-2',
        )

        storage.generate_presigned_url.assert_called_once()

    @patch(
        'apps.streaming.views.'
        'minio_public_upload_client'
    )
    def test_part_rejects_out_of_range_number(
        self,
        public_factory,
    ):
        response = self.client.post(
            self._url('source-multipart-part'),
            {
                'upload_token': self._token(),
                'part_number': 3,
            },
            format='json',
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_400_BAD_REQUEST,
        )

        public_factory.return_value \
            .generate_presigned_url \
            .assert_not_called()

    def test_tampered_token_is_rejected(self):
        token = self._token() + 'tampered'

        response = self.client.post(
            self._url('source-multipart-part'),
            {
                'upload_token': token,
                'part_number': 1,
            },
            format='json',
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_400_BAD_REQUEST,
        )

    def test_token_from_other_user_is_rejected(self):
        other = User.objects.create_user(
            email='other-multipart@example.com',
            password='StrongPass123',
        )

        response = self.client.post(
            self._url('source-multipart-part'),
            {
                'upload_token': self._token(
                    user_id=other.id,
                ),
                'part_number': 1,
            },
            format='json',
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_403_FORBIDDEN,
        )

    @patch(
        'apps.streaming.views.notify_user'
    )
    @patch(
        'apps.streaming.views.'
        'analyze_video_asset.delay'
    )
    @patch(
        'apps.streaming.views.'
        'minio_internal_client'
    )
    def test_complete_finalizes_asset_and_starts_analysis_once(
        self,
        internal_factory,
        analyze_delay,
        notify_user,
    ):
        storage = internal_factory.return_value

        storage.complete_multipart_upload.return_value = {
            'ETag': '"complete"',
        }
        storage.head_object.return_value = {
            'ContentLength': 100,
        }

        response = self.client.post(
            self._url('source-multipart-complete'),
            {
                'upload_token': self._token(),
                'parts': [
                    {
                        'part_number': 1,
                        'etag': '"etag-1"',
                    },
                    {
                        'part_number': 2,
                        'etag': '"etag-2"',
                    },
                ],
            },
            format='json',
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_200_OK,
        )

        self.asset.refresh_from_db()

        self.assertEqual(
            self.asset.source_file_size_bytes,
            100,
        )
        self.assertEqual(
            self.asset.source_uploaded_by,
            self.producer,
        )
        self.assertTrue(
            self.asset.source_file_path
        )
        self.assertEqual(
            self.asset.moderation_status,
            'pending',
        )

        report = MediaAnalysisReport.objects.get(
            asset=self.asset
        )
        self.assertEqual(
            report.status,
            'pending',
        )

        analyze_delay.assert_called_once_with(
            str(self.asset.id)
        )
        notify_user.assert_called_once()

        storage.complete_multipart_upload \
            .assert_called_once()
        storage.head_object.assert_called_once()

    @patch(
        'apps.streaming.views.'
        'analyze_video_asset.delay'
    )
    @patch(
        'apps.streaming.views.'
        'minio_internal_client'
    )
    def test_complete_rejects_wrong_final_size(
        self,
        internal_factory,
        analyze_delay,
    ):
        storage = internal_factory.return_value
        storage.head_object.return_value = {
            'ContentLength': 99,
        }

        response = self.client.post(
            self._url('source-multipart-complete'),
            {
                'upload_token': self._token(),
                'parts': [
                    {
                        'part_number': 1,
                        'etag': '"etag-1"',
                    },
                    {
                        'part_number': 2,
                        'etag': '"etag-2"',
                    },
                ],
            },
            format='json',
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_400_BAD_REQUEST,
        )

        analyze_delay.assert_not_called()

        self.asset.refresh_from_db()
        self.assertFalse(
            self.asset.source_file_path
        )

    @patch(
        'apps.streaming.views.'
        'analyze_video_asset.delay'
    )
    @patch(
        'apps.streaming.views.'
        'minio_internal_client'
    )
    def test_complete_rejects_missing_part(
        self,
        internal_factory,
        analyze_delay,
    ):
        response = self.client.post(
            self._url('source-multipart-complete'),
            {
                'upload_token': self._token(),
                'parts': [
                    {
                        'part_number': 1,
                        'etag': '"etag-1"',
                    },
                ],
            },
            format='json',
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_400_BAD_REQUEST,
        )

        internal_factory.return_value \
            .complete_multipart_upload \
            .assert_not_called()

        analyze_delay.assert_not_called()

    @patch(
        'apps.streaming.views.'
        'minio_internal_client'
    )
    def test_abort_calls_storage(
        self,
        internal_factory,
    ):
        storage = internal_factory.return_value

        response = self.client.post(
            self._url('source-multipart-abort'),
            {
                'upload_token': self._token(),
            },
            format='json',
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_204_NO_CONTENT,
        )

        storage.abort_multipart_upload \
            .assert_called_once_with(
                Bucket='test-video-bucket',
                Key=(
                    f'uploads/producer_'
                    f'{self.producer.id}/'
                    f'asset_{self.asset.id}/'
                    'video_original.mp4'
                ),
                UploadId='upload-123',
            )
