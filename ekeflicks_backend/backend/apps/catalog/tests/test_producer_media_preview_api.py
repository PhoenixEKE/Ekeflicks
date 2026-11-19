from unittest.mock import patch

from django.contrib.auth import get_user_model
from django.conf import settings
from django.test import override_settings
from django.utils import timezone
from rest_framework import status
from rest_framework.test import APITestCase

from core.models import (
    Content,
    Season,
    ProducerAccount,
    ProducerAgreement,
)



User = get_user_model()


@override_settings(
    MINIO_BUCKET='test-private-media',
)
class ProducerMediaPreviewAPITests(APITestCase):
    def setUp(self):
        self.owner = self._create_producer(
            email='preview-owner@example.com',
        )
        self.other = self._create_producer(
            email='preview-other@example.com',
        )

        self.content = Content.objects.create(
            title='Preview Content',
            type='movie',
            producer=self.owner,
            producer_submission_status='draft',
            poster_temp_path=(
                f'uploads/producer_{self.owner.id}/'
                'content_preview/poster.jpg'
            ),
            backdrop_temp_path=(
                f'uploads/producer_{self.owner.id}/'
                'content_preview/backdrop.jpg'
            ),
            trailer_temp_path=(
                f'uploads/producer_{self.owner.id}/'
                'content_preview/trailer.mp4'
            ),
        )

        # The preview helper validates the real content_<uuid>/ segment.
        prefix = (
            f'uploads/producer_{self.owner.id}/'
            f'content_{self.content.id}/'
        )

        self.content.poster_temp_path = f'{prefix}poster.jpg'
        self.content.backdrop_temp_path = f'{prefix}backdrop.jpg'
        self.content.trailer_temp_path = f'{prefix}trailer.mp4'
        self.content.save(
            update_fields=[
                'poster_temp_path',
                'backdrop_temp_path',
                'trailer_temp_path',
            ]
        )

        self.season = Season.objects.create(
            content=self.content,
            season_number=1,
            title='Season 1',
            poster_temp_path=f'{prefix}season_1/poster.jpg',
            backdrop_temp_path=f'{prefix}season_1/backdrop.jpg',
            trailer_temp_path=f'{prefix}season_1/trailer.mp4',
        )

    def _create_producer(self, *, email):
        producer = User.objects.create_user(
            email=email,
            password='StrongPass123',
            is_producer=True,
        )
        producer.is_verified = True
        producer.save(update_fields=['is_verified'])

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

    def _content_url(self, path):
        return (
            f'/api/v1/contents/{self.content.id}/media-preview/'
            f'?path={path}'
        )

    def _season_url(self, path):
        return (
            f'/api/v1/seasons/{self.season.id}/media-preview/'
            f'?path={path}'
        )

    @patch('apps.catalog.views.minio_public_upload_client')
    def test_owner_can_preview_content_temporary_media(self, minio_client):
        signed_url = 'https://preview.invalid/content-poster'
        minio_client.return_value.generate_presigned_url.return_value = (
            signed_url
        )

        self.client.force_authenticate(user=self.owner)

        for temporary_path in (
            self.content.poster_temp_path,
            self.content.backdrop_temp_path,
            self.content.trailer_temp_path,
        ):
            with self.subTest(path=temporary_path):
                response = self.client.get(
                    self._content_url(temporary_path)
                )

                self.assertEqual(
                    response.status_code,
                    status.HTTP_200_OK,
                    response.data,
                )
                self.assertEqual(
                    response.data['preview_url'],
                    signed_url,
                )
                self.assertEqual(
                    response.data['expires_in'],
                    900,
                )

    @patch('apps.catalog.views.minio_public_upload_client')
    def test_foreign_producer_cannot_preview_content_media(
        self,
        minio_client,
    ):
        self.client.force_authenticate(user=self.other)

        response = self.client.get(
            self._content_url(self.content.poster_temp_path)
        )

        self.assertIn(
            response.status_code,
            (
                status.HTTP_403_FORBIDDEN,
                status.HTTP_404_NOT_FOUND,
            ),
            response.data,
        )
        minio_client.assert_not_called()

    @patch('apps.catalog.views.minio_public_upload_client')
    def test_owner_cannot_preview_arbitrary_content_path(
        self,
        minio_client,
    ):
        self.client.force_authenticate(user=self.owner)

        arbitrary_path = (
            f'uploads/producer_{self.owner.id}/'
            f'content_{self.content.id}/not-owned.mp4'
        )

        response = self.client.get(
            self._content_url(arbitrary_path)
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_403_FORBIDDEN,
            response.data,
        )
        minio_client.assert_not_called()

    @patch('apps.catalog.views.minio_public_upload_client')
    def test_owner_can_preview_season_temporary_media(self, minio_client):
        signed_url = 'https://preview.invalid/season-media'
        minio_client.return_value.generate_presigned_url.return_value = (
            signed_url
        )

        self.client.force_authenticate(user=self.owner)

        for temporary_path in (
            self.season.poster_temp_path,
            self.season.backdrop_temp_path,
            self.season.trailer_temp_path,
        ):
            with self.subTest(path=temporary_path):
                response = self.client.get(
                    self._season_url(temporary_path)
                )

                self.assertEqual(
                    response.status_code,
                    status.HTTP_200_OK,
                    response.data,
                )
                self.assertEqual(
                    response.data['preview_url'],
                    signed_url,
                )
                self.assertEqual(
                    response.data['expires_in'],
                    900,
                )

    @patch('apps.catalog.views.minio_public_upload_client')
    def test_foreign_producer_cannot_preview_season_media(
        self,
        minio_client,
    ):
        self.client.force_authenticate(user=self.other)

        response = self.client.get(
            self._season_url(self.season.poster_temp_path)
        )

        self.assertIn(
            response.status_code,
            (
                status.HTTP_403_FORBIDDEN,
                status.HTTP_404_NOT_FOUND,
            ),
            response.data,
        )
        minio_client.assert_not_called()

    @patch('apps.catalog.views.minio_public_upload_client')
    def test_final_media_contract_is_not_replaced_by_preview(
        self,
        minio_client,
    ):
        final_poster = 'https://cdn.invalid/final-poster.jpg'

        self.content.poster_url = final_poster
        self.content.poster_temp_path = ''
        self.content.save(
            update_fields=[
                'poster_url',
                'poster_temp_path',
            ]
        )

        self.client.force_authenticate(user=self.owner)

        detail_response = self.client.get(
            f'/api/v1/contents/{self.content.id}/'
        )

        self.assertEqual(
            detail_response.status_code,
            status.HTTP_200_OK,
            detail_response.data,
        )
        self.assertEqual(
            detail_response.data.get('poster_url'),
            final_poster,
        )
        self.assertFalse(
            detail_response.data.get('poster_temp_path')
        )

        preview_response = self.client.get(
            self._content_url(
                f'uploads/producer_{self.owner.id}/'
                f'content_{self.content.id}/poster.jpg'
            )
        )

        self.assertIn(
            preview_response.status_code,
            (
                status.HTTP_400_BAD_REQUEST,
                status.HTTP_403_FORBIDDEN,
            ),
            preview_response.data,
        )

        minio_client.assert_not_called()
