from unittest.mock import patch

from django.contrib.auth import get_user_model
from django.conf import settings
from django.urls import reverse
from django.utils import timezone
from rest_framework.test import APITestCase

from core.models import Content, ProducerAccount, ProducerAgreement, VideoAsset


User = get_user_model()


class ProducerSourcePreviewApiTests(APITestCase):
    def _producer(self, email):
        user = User.objects.create_user(
            email=email,
            password='Test-pass-123!',
            is_producer=True,
        )

        user.is_verified = True
        user.save(update_fields=['is_verified'])

        producer_account = ProducerAccount.objects.create(
            user=user,
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

        return user

    def _content(self, producer, title):
        return Content.objects.create(
            title=title,
            type='movie',
            producer=producer,
        )

    @patch(
        'apps.streaming.views.minio_public_upload_client'
    )
    def test_owner_can_preview_private_master(self, minio_client):
        producer = self._producer('owner-preview@example.com')
        content = self._content(producer, 'Owner preview')

        asset = VideoAsset.objects.create(
            content=content,
            source_file_path=(
                f'uploads/producer_{producer.id}/'
                f'content_{content.id}/master.mp4'
            ),
        )

        minio_client.return_value.generate_presigned_url.return_value = (
            'https://signed.example/master.mp4'
        )

        self.client.force_authenticate(producer)

        response = self.client.get(
            reverse(
                'video-asset-source-preview',
                kwargs={'pk': asset.id},
            )
        )

        self.assertEqual(response.status_code, 200)
        self.assertEqual(
            response.data['preview_url'],
            'https://signed.example/master.mp4',
        )
        self.assertEqual(response.data['expires_in'], 900)

        minio_client.return_value.generate_presigned_url.assert_called_once()

    @patch(
        'apps.streaming.views.minio_public_upload_client'
    )
    def test_foreign_producer_cannot_preview_master(self, minio_client):
        owner = self._producer('owner-foreign@example.com')
        foreign = self._producer('foreign-preview@example.com')

        content = self._content(owner, 'Foreign preview')

        asset = VideoAsset.objects.create(
            content=content,
            source_file_path=(
                f'uploads/producer_{owner.id}/'
                f'content_{content.id}/master.mp4'
            ),
        )

        self.client.force_authenticate(foreign)

        response = self.client.get(
            reverse(
                'video-asset-source-preview',
                kwargs={'pk': asset.id},
            )
        )

        self.assertIn(response.status_code, {403, 404})
        minio_client.return_value.generate_presigned_url.assert_not_called()

    @patch(
        'apps.streaming.views.minio_public_upload_client'
    )
    def test_arbitrary_source_path_is_rejected(self, minio_client):
        producer = self._producer('owner-invalid@example.com')
        content = self._content(producer, 'Invalid preview')

        asset = VideoAsset.objects.create(
            content=content,
            source_file_path='uploads/producer_other/master.mp4',
        )

        self.client.force_authenticate(producer)

        response = self.client.get(
            reverse(
                'video-asset-source-preview',
                kwargs={'pk': asset.id},
            )
        )

        self.assertEqual(response.status_code, 403)
        minio_client.return_value.generate_presigned_url.assert_not_called()

    @patch(
        'apps.streaming.views.minio_public_upload_client'
    )
    def test_missing_private_source_returns_404(self, minio_client):
        producer = self._producer('owner-empty@example.com')
        content = self._content(producer, 'Empty preview')

        asset = VideoAsset.objects.create(
            content=content,
            source_file_path='',
        )

        self.client.force_authenticate(producer)

        response = self.client.get(
            reverse(
                'video-asset-source-preview',
                kwargs={'pk': asset.id},
            )
        )

        self.assertEqual(response.status_code, 404)
        minio_client.return_value.generate_presigned_url.assert_not_called()
