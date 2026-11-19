from unittest.mock import patch
from django.conf import settings
from django.core.files.storage import storages
from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import override_settings
from django.urls import reverse
from django.utils import timezone
from rest_framework import status
from rest_framework.test import APITestCase

from core.models import (
    Content,
    Genre,
    ProducerAccount,
    ProducerAgreement,
    Profile,
    Recommendation,
    User,
    WatchHistory,
)


TEST_FILE_STORAGES = {
    'default': {
        'BACKEND': 'django.core.files.storage.FileSystemStorage',
    },
    'staticfiles': {
        'BACKEND': 'django.contrib.staticfiles.storage.StaticFilesStorage',
    },
    'final_media': {
        'BACKEND': 'django.core.files.storage.FileSystemStorage',
    },
    'final_videos': {
        'BACKEND': 'django.core.files.storage.FileSystemStorage',
    },
    'final_posters': {
        'BACKEND': 'django.core.files.storage.FileSystemStorage',
    },
    'final_backdrops': {
        'BACKEND': 'django.core.files.storage.FileSystemStorage',
    },
    'final_trailers': {
        'BACKEND': 'django.core.files.storage.FileSystemStorage',
    },
    'final_avatars': {
        'BACKEND': 'django.core.files.storage.FileSystemStorage',
    },
    'final_subtitles': {
        'BACKEND': 'django.core.files.storage.FileSystemStorage',
    },
}


class CatalogApiTests(APITestCase):
    def setUp(self):
        self.genre = Genre.objects.create(name='Action', slug='action')
        self.series_genre = Genre.objects.create(name='Drama', slug='drama')
        self.content = Content.objects.create(
            title='Eke Mission',
            description='Film de test',
            type='movie',
            release_year=2026,
            popularity_score=90,
            trending_score=95,
        )
        self.content.genres.add(self.genre)
        self.series = Content.objects.create(
            title='Eke Series',
            description='Serie de test',
            type='series',
            release_year=2026,
            popularity_score=70,
            trending_score=85,
            view_count=200,
        )
        self.series.genres.add(self.series_genre)

    def test_content_list_is_public(self):
        response = self.client.get(reverse('content-list'))

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        payload = response.data['results'] if 'results' in response.data else response.data
        self.assertEqual(payload[0]['title'], 'Eke Mission')

    def test_content_can_be_filtered_by_genre_slug(self):
        response = self.client.get(reverse('content-list'), {'genre': 'action'})

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        payload = response.data['results'] if 'results' in response.data else response.data
        self.assertEqual(len(payload), 1)
        self.assertEqual(payload[0]['id'], str(self.content.id))

    def test_advanced_search_returns_matching_content(self):
        response = self.client.get(
            reverse('content-search'),
            {'q': 'series', 'type': 'series'},
        )

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['count'], 1)
        self.assertEqual(response.data['results'][0]['id'], str(self.series.id))

    def test_home_returns_netflix_style_rows(self):
        user = User.objects.create_user(email='home@example.com', password='StrongPass123')
        profile = Profile.objects.get(user=user)
        WatchHistory.objects.create(
            profile=profile,
            content=self.content,
            progress=40,
            last_position=320,
        )
        Recommendation.objects.create(
            profile=profile,
            content=self.series,
            score=98,
            reason='ai_match',
            expires_at=timezone.now() + timezone.timedelta(days=1),
        )
        self.client.force_authenticate(user=user)

        response = self.client.get(reverse('content-home'), {'profile': str(profile.id)})
        legacy_response = self.client.get(
            reverse('catalog-home'),
            {'profile': str(profile.id)},
        )

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(legacy_response.status_code, status.HTTP_200_OK)
        self.assertEqual(legacy_response.data, response.data)
        row_keys = [row['key'] for row in response.data['rows']]
        self.assertIn('continue_watching', row_keys)
        self.assertIn('recommended', row_keys)
        self.assertIn('top_10', row_keys)

    def test_non_staff_cannot_create_content(self):
        user = User.objects.create_user(email='viewer@example.com', password='StrongPass123')
        self.client.force_authenticate(user=user)

        response = self.client.post(
            reverse('content-list'),
            {'title': 'Forbidden', 'type': 'movie'},
            format='json',
        )

        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    @override_settings(
        MEDIA_CDN_BASE_URL='https://cdn.ekeflicks.com',
        STORAGES=TEST_FILE_STORAGES,
    )
    def test_staff_uploads_content_media_to_temporary_storage_only(self):
        storages._storages.clear()

        user = User.objects.create_user(
            email='staff-media@example.com',
            password='StrongPass123',
            is_staff=True,
        )
        self.client.force_authenticate(user=user)

        cases = [
            (
                'content-upload-poster',
                'poster.jpg',
                b'poster',
                'poster_temp_path',
                'poster_url',
            ),
            (
                'content-upload-backdrop',
                'backdrop.jpg',
                b'backdrop',
                'backdrop_temp_path',
                'backdrop_url',
            ),
            (
                'content-upload-trailer',
                'trailer.mp4',
                b'trailer',
                'trailer_temp_path',
                'trailer_url',
            ),
        ]

        for route_name, filename, payload, temp_field, final_field in cases:
            uploaded_file = SimpleUploadedFile(filename, payload)

            response = self.client.post(
                reverse(route_name, args=[self.content.id]),
                {'file': uploaded_file},
                format='multipart',
            )

            self.assertEqual(response.status_code, status.HTTP_200_OK)
            self.assertEqual(response.data['field'], temp_field)
            self.assertEqual(response.data['final_field'], final_field)
            self.assertEqual(response.data['storage'], 'temporary')
            self.assertEqual(response.data['url'], '')

            temporary_path = response.data['temporary_path']
            self.assertTrue(temporary_path)

            self.content.refresh_from_db()

            self.assertEqual(
                getattr(self.content, temp_field),
                temporary_path,
            )
            self.assertEqual(
                getattr(self.content, final_field),
                '',
            )

            self.assertTrue(
                storages['default'].exists(temporary_path),
                temporary_path,
            )

    @patch(
        'apps.catalog.media_services.copy_internal_to_final'
    )
    def test_media_promotion_rolls_back_partial_final_copies(
        self,
        copy_mock,
    ):
        from apps.catalog.media_services import (
            promote_content_media_to_final,
        )

        self.content.poster_temp_path = 'temp/poster.jpg'
        self.content.backdrop_temp_path = 'temp/backdrop.jpg'
        self.content.trailer_temp_path = 'temp/trailer.mp4'
        self.content.poster_url = ''
        self.content.backdrop_url = ''
        self.content.trailer_url = ''
        self.content.save(
            update_fields=[
                'poster_temp_path',
                'backdrop_temp_path',
                'trailer_temp_path',
                'poster_url',
                'backdrop_url',
                'trailer_url',
                'updated_at',
            ]
        )

        created = []

        def fake_copy(
            internal_path,
            storage_alias,
            final_path,
            cdn_prefix='',
        ):
            if storage_alias == 'final_trailers':
                raise RuntimeError('trailer copy failure')

            storage = storages[storage_alias]
            storage.save(
                final_path,
                SimpleUploadedFile(
                    'final.bin',
                    b'final-data',
                ),
            )
            created.append((storage_alias, final_path))

            return (
                final_path,
                f'https://cdn.example.test/{final_path}',
            )

        copy_mock.side_effect = fake_copy

        with self.assertRaises(RuntimeError):
            promote_content_media_to_final(self.content)

        self.assertEqual(len(created), 2)

        for storage_alias, final_path in created:
            self.assertFalse(
                storages[storage_alias].exists(final_path),
                f'{storage_alias}:{final_path}',
            )

        self.content.refresh_from_db()

        self.assertEqual(self.content.poster_url, '')
        self.assertEqual(self.content.backdrop_url, '')
        self.assertEqual(self.content.trailer_url, '')

    @patch(
        'apps.catalog.views.promote_content_media_to_final'
    )
    def test_approval_promotes_media_before_approved(
        self,
        promote_mock,
    ):
        admin = User.objects.create_user(
            email='approval-admin@example.com',
            password='StrongPass123',
            is_staff=True,
        )
        self.client.force_authenticate(user=admin)

        self.content.producer_submission_status = 'pending'
        self.content.save(
            update_fields=[
                'producer_submission_status',
                'updated_at',
            ]
        )

        def assert_pending_during_promotion(content):
            content.refresh_from_db()
            self.assertEqual(
                content.producer_submission_status,
                'pending',
            )
            return {}

        promote_mock.side_effect = assert_pending_during_promotion

        response = self.client.post(
            reverse(
                'content-approve-submission',
                args=[self.content.id],
            ),
            {'reason': 'Validation OK'},
            format='json',
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_200_OK,
        )
        promote_mock.assert_called_once()

        self.content.refresh_from_db()
        self.assertEqual(
            self.content.producer_submission_status,
            'approved',
        )
        self.assertEqual(
            self.content.review_reason,
            'Validation OK',
        )

    @patch(
        'apps.catalog.views.promote_content_media_to_final'
    )
    def test_approval_failure_keeps_content_pending(
        self,
        promote_mock,
    ):
        admin = User.objects.create_user(
            email='approval-failure@example.com',
            password='StrongPass123',
            is_staff=True,
        )
        self.client.force_authenticate(user=admin)

        self.content.producer_submission_status = 'pending'
        self.content.save(
            update_fields=[
                'producer_submission_status',
                'updated_at',
            ]
        )

        promote_mock.side_effect = RuntimeError(
            'B2 promotion failure'
        )

        response = self.client.post(
            reverse(
                'content-approve-submission',
                args=[self.content.id],
            ),
            {'reason': 'Validation OK'},
            format='json',
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_503_SERVICE_UNAVAILABLE,
        )

        self.content.refresh_from_db()

        self.assertEqual(
            self.content.producer_submission_status,
            'pending',
        )
        self.assertIsNone(self.content.reviewed_at)
        self.assertIsNone(self.content.reviewed_by)

    @patch(
        'apps.catalog.views.promote_content_media_to_final'
    )
    def test_approval_rejects_non_pending_content(
        self,
        promote_mock,
    ):
        admin = User.objects.create_user(
            email='approval-conflict@example.com',
            password='StrongPass123',
            is_staff=True,
        )
        self.client.force_authenticate(user=admin)

        self.content.producer_submission_status = 'draft'
        self.content.save(
            update_fields=[
                'producer_submission_status',
                'updated_at',
            ]
        )

        response = self.client.post(
            reverse(
                'content-approve-submission',
                args=[self.content.id],
            ),
            {'reason': 'Validation OK'},
            format='json',
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_409_CONFLICT,
        )
        promote_mock.assert_not_called()

        self.content.refresh_from_db()
        self.assertEqual(
            self.content.producer_submission_status,
            'draft',
        )

    def test_producer_can_create_submit_and_view_own_content(self):
        producer = User.objects.create_user(
            email='producer@example.com',
            password='StrongPass123',
            is_producer=True,
            producer_company='Eke Studios',
        )
        producer.is_verified = True
        producer.save(update_fields=['is_verified'])

        producer_account = ProducerAccount.objects.create(
            user=producer,
            company_name='Test Producer Company',
            status=ProducerAccount.STATUS_ACTIVE,
            activated_at=timezone.now(),
        )

        ProducerAgreement.objects.create(
            producer_account=producer_account,
            contract_version=settings.PRODUCER_AGREEMENT_ACCEPTED_VERSIONS[0],
            contract_title='EKEFLICKS Producer Agreement - Test',
            status=ProducerAgreement.STATUS_SIGNED,
            accepted_at=timezone.now(),
            signed_at=timezone.now(),
        )

        self.client.force_authenticate(user=producer)

        create_response = self.client.post(
            reverse('content-list'),
            {
                'title': 'Producer Movie',
                'type': 'movie',
                'description': 'Depot producteur',
            },
            format='json',
        )

        self.assertEqual(create_response.status_code, status.HTTP_201_CREATED)
        content = Content.objects.get(id=create_response.data['id'])
        self.assertEqual(content.producer, producer)
        self.assertEqual(content.producer_submission_status, 'draft')

        submit_response = self.client.post(
            reverse('content-submit', args=[content.id]),
            {'producer_notes': 'Pret pour validation.'},
            format='json',
        )

        self.assertEqual(submit_response.status_code, status.HTTP_200_OK)
        content.refresh_from_db()
        self.assertEqual(content.producer_submission_status, 'pending')
        self.assertEqual(content.producer_notes, 'Pret pour validation.')
        self.assertIsNotNone(content.submitted_at)

        mine_response = self.client.get(reverse('content-mine'))
        payload = mine_response.data['results'] if 'results' in mine_response.data else mine_response.data
        self.assertEqual(mine_response.status_code, status.HTTP_200_OK)
        self.assertEqual(payload[0]['id'], str(content.id))

        dashboard_response = self.client.get(reverse('content-producer-dashboard'))
        self.assertEqual(dashboard_response.status_code, status.HTTP_200_OK)
        self.assertEqual(dashboard_response.data['content_total'], 1)
        self.assertEqual(
            dashboard_response.data['content_by_submission_status']['pending'],
            1,
        )


    def test_producer_cannot_submit_non_draft_content(self):
        producer = User.objects.create_user(
            email='producer-submit-status@example.com',
            password='StrongPass123',
            is_producer=True,
        )
        producer.is_verified = True
        producer.save(update_fields=['is_verified'])

        producer_account = ProducerAccount.objects.create(
            user=producer,
            company_name='Submit Status Producer',
            status=ProducerAccount.STATUS_ACTIVE,
            activated_at=timezone.now(),
        )

        ProducerAgreement.objects.create(
            producer_account=producer_account,
            contract_version=settings.PRODUCER_AGREEMENT_ACCEPTED_VERSIONS[0],
            contract_title='EKEFLICKS Producer Agreement - Submit Test',
            status=ProducerAgreement.STATUS_SIGNED,
            accepted_at=timezone.now(),
            signed_at=timezone.now(),
        )

        self.client.force_authenticate(user=producer)

        for submission_status in (
            'pending',
            'approved',
            'rejected',
        ):
            with self.subTest(
                submission_status=submission_status,
            ):
                content = Content.objects.create(
                    title=f'{submission_status} Movie',
                    type='movie',
                    producer=producer,
                    producer_submission_status=submission_status,
                )

                response = self.client.post(
                    reverse(
                        'content-submit',
                        args=[content.id],
                    ),
                    {
                        'producer_notes':
                            'Tentative de resoumission.',
                    },
                    format='json',
                )

                self.assertEqual(
                    response.status_code,
                    status.HTTP_409_CONFLICT,
                )

                content.refresh_from_db()

                self.assertEqual(
                    content.producer_submission_status,
                    submission_status,
                )


    def test_producer_cannot_update_pending_content(self):
        producer = User.objects.create_user(
            email='producer-pending-update@example.com',
            password='StrongPass123',
            is_producer=True,
        )
        producer.is_verified = True
        producer.save(update_fields=['is_verified'])

        producer_account = ProducerAccount.objects.create(
            user=producer,
            company_name='Workflow Producer 1',
            status=ProducerAccount.STATUS_ACTIVE,
            activated_at=timezone.now(),
        )

        ProducerAgreement.objects.create(
            producer_account=producer_account,
            contract_version=settings.PRODUCER_AGREEMENT_ACCEPTED_VERSIONS[0],
            contract_title='EKEFLICKS Producer Agreement - Workflow Test',
            status=ProducerAgreement.STATUS_SIGNED,
            accepted_at=timezone.now(),
            signed_at=timezone.now(),
        )

        self.client.force_authenticate(user=producer)

        content = Content.objects.create(
            title='Pending Movie',
            type='movie',
            producer=producer,
            producer_submission_status='pending',
        )

        response = self.client.patch(
            reverse('content-detail', args=[content.id]),
            {'title': 'Titre modifie'},
            format='json',
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_400_BAD_REQUEST,
        )

        content.refresh_from_db()

        self.assertEqual(content.title, 'Pending Movie')
        self.assertEqual(
            content.producer_submission_status,
            'pending',
        )

    def test_producer_cannot_update_approved_content(self):
        producer = User.objects.create_user(
            email='producer-approved-update@example.com',
            password='StrongPass123',
            is_producer=True,
        )
        producer.is_verified = True
        producer.save(update_fields=['is_verified'])

        producer_account = ProducerAccount.objects.create(
            user=producer,
            company_name='Workflow Producer 2',
            status=ProducerAccount.STATUS_ACTIVE,
            activated_at=timezone.now(),
        )

        ProducerAgreement.objects.create(
            producer_account=producer_account,
            contract_version=settings.PRODUCER_AGREEMENT_ACCEPTED_VERSIONS[0],
            contract_title='EKEFLICKS Producer Agreement - Workflow Test',
            status=ProducerAgreement.STATUS_SIGNED,
            accepted_at=timezone.now(),
            signed_at=timezone.now(),
        )

        self.client.force_authenticate(user=producer)

        content = Content.objects.create(
            title='Approved Movie',
            type='movie',
            producer=producer,
            producer_submission_status='approved',
        )

        response = self.client.patch(
            reverse('content-detail', args=[content.id]),
            {'title': 'Titre modifie'},
            format='json',
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_400_BAD_REQUEST,
        )

        content.refresh_from_db()

        self.assertEqual(content.title, 'Approved Movie')
        self.assertEqual(
            content.producer_submission_status,
            'approved',
        )

    def test_producer_can_correct_rejected_content(self):
        producer = User.objects.create_user(
            email='producer-rejected-update@example.com',
            password='StrongPass123',
            is_producer=True,
        )
        producer.is_verified = True
        producer.save(update_fields=['is_verified'])

        producer_account = ProducerAccount.objects.create(
            user=producer,
            company_name='Workflow Producer 3',
            status=ProducerAccount.STATUS_ACTIVE,
            activated_at=timezone.now(),
        )

        ProducerAgreement.objects.create(
            producer_account=producer_account,
            contract_version=settings.PRODUCER_AGREEMENT_ACCEPTED_VERSIONS[0],
            contract_title='EKEFLICKS Producer Agreement - Workflow Test',
            status=ProducerAgreement.STATUS_SIGNED,
            accepted_at=timezone.now(),
            signed_at=timezone.now(),
        )

        self.client.force_authenticate(user=producer)

        content = Content.objects.create(
            title='Rejected Movie',
            type='movie',
            producer=producer,
            producer_submission_status='rejected',
            review_reason='Affiche a corriger.',
        )

        response = self.client.patch(
            reverse('content-detail', args=[content.id]),
            {'title': 'Rejected Movie Corrige'},
            format='json',
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_200_OK,
        )

        content.refresh_from_db()

        self.assertEqual(
            content.title,
            'Rejected Movie Corrige',
        )
        self.assertEqual(
            content.producer_submission_status,
            'draft',
        )
        self.assertEqual(content.review_reason, '')


    @patch(
        'apps.catalog.views.minio_public_upload_client'
    )
    def test_trailer_direct_upload_session(
        self,
        mock_public_client,
    ):
        producer = User.objects.create_user(
            email='trailer-session@example.com',
            password='StrongPass123',
            is_producer=True,
        )
        self.client.force_authenticate(user=producer)

        content = Content.objects.create(
            title='Trailer direct',
            type='movie',
            producer=producer,
            producer_submission_status='draft',
        )

        client = mock_public_client.return_value
        client.generate_presigned_url.return_value = (
            'https://upload.example.test/presigned'
        )

        response = self.client.post(
            reverse(
                'content-trailer-upload-session',
                args=[content.id],
            ),
            {
                'filename': 'trailer.mp4',
                'size_bytes': 123456,
            },
            format='json',
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_200_OK,
        )
        self.assertIn('upload_url', response.data)
        self.assertIn(
            'completion_token',
            response.data,
        )
        self.assertEqual(
            response.data['size_bytes'],
            123456,
        )

        client.generate_presigned_url.assert_called_once()

        call_kwargs = (
            client.generate_presigned_url.call_args.kwargs
        )

        self.assertEqual(
            call_kwargs['ClientMethod'],
            'put_object',
        )

        params = call_kwargs['Params']

        self.assertEqual(
            params['Bucket'],
            settings.MINIO_BUCKET,
        )
        self.assertEqual(
            params['Key'],
            (
                f'uploads/producer_{producer.id}/'
                f'content_{content.id}/'
                'trailer_original.mp4'
            ),
        )

    def test_trailer_direct_upload_rejects_bad_extension(
        self,
    ):
        producer = User.objects.create_user(
            email='trailer-extension@example.com',
            password='StrongPass123',
            is_producer=True,
        )
        self.client.force_authenticate(user=producer)

        content = Content.objects.create(
            title='Bad trailer',
            type='movie',
            producer=producer,
            producer_submission_status='draft',
        )

        response = self.client.post(
            reverse(
                'content-trailer-upload-session',
                args=[content.id],
            ),
            {
                'filename': 'trailer.exe',
                'size_bytes': 1000,
            },
            format='json',
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_400_BAD_REQUEST,
        )

    def test_trailer_direct_upload_rejects_non_draft(
        self,
    ):
        producer = User.objects.create_user(
            email='trailer-pending@example.com',
            password='StrongPass123',
            is_producer=True,
        )
        self.client.force_authenticate(user=producer)

        content = Content.objects.create(
            title='Pending trailer',
            type='movie',
            producer=producer,
            producer_submission_status='pending',
        )

        response = self.client.post(
            reverse(
                'content-trailer-upload-session',
                args=[content.id],
            ),
            {
                'filename': 'trailer.mp4',
                'size_bytes': 1000,
            },
            format='json',
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_400_BAD_REQUEST,
        )

    def test_trailer_direct_upload_rejects_other_producer(
        self,
    ):
        owner = User.objects.create_user(
            email='trailer-owner@example.com',
            password='StrongPass123',
            is_producer=True,
        )
        other = User.objects.create_user(
            email='trailer-other@example.com',
            password='StrongPass123',
            is_producer=True,
        )

        content = Content.objects.create(
            title='Other producer trailer',
            type='movie',
            producer=owner,
            producer_submission_status='draft',
        )

        self.client.force_authenticate(user=other)

        response = self.client.post(
            reverse(
                'content-trailer-upload-session',
                args=[content.id],
            ),
            {
                'filename': 'trailer.mp4',
                'size_bytes': 1000,
            },
            format='json',
        )

        self.assertIn(
            response.status_code,
            {
                status.HTTP_403_FORBIDDEN,
                status.HTTP_404_NOT_FOUND,
            },
        )

    @patch(
        'apps.catalog.views.minio_internal_client'
    )
    @patch(
        'apps.catalog.views.minio_public_upload_client'
    )
    def test_trailer_direct_upload_session_and_complete(
        self,
        mock_public_client,
        mock_internal_client,
    ):
        producer = User.objects.create_user(
            email='trailer-complete@example.com',
            password='StrongPass123',
            is_producer=True,
        )
        self.client.force_authenticate(user=producer)

        content = Content.objects.create(
            title='Trailer complete',
            type='movie',
            producer=producer,
            producer_submission_status='draft',
            trailer_url='https://old.example/trailer.mp4',
        )

        public_client = (
            mock_public_client.return_value
        )
        public_client.generate_presigned_url.return_value = (
            'https://upload.example.test/presigned'
        )

        session_response = self.client.post(
            reverse(
                'content-trailer-upload-session',
                args=[content.id],
            ),
            {
                'filename': 'trailer.mp4',
                'size_bytes': 987654,
            },
            format='json',
        )

        self.assertEqual(
            session_response.status_code,
            status.HTTP_200_OK,
        )

        token = session_response.data[
            'completion_token'
        ]

        internal_client = (
            mock_internal_client.return_value
        )
        internal_client.head_object.return_value = {
            'ContentLength': 987654,
        }

        complete_response = self.client.post(
            reverse(
                'content-trailer-upload-complete',
                args=[content.id],
            ),
            {
                'completion_token': token,
            },
            format='json',
        )

        self.assertEqual(
            complete_response.status_code,
            status.HTTP_200_OK,
        )

        content.refresh_from_db()

        expected_path = (
            f'uploads/producer_{producer.id}/'
            f'content_{content.id}/'
            'trailer_original.mp4'
        )

        self.assertEqual(
            content.trailer_temp_path,
            expected_path,
        )
        self.assertEqual(
            content.trailer_url,
            '',
        )
        self.assertEqual(
            complete_response.data[
                'temporary_path'
            ],
            expected_path,
        )
        self.assertEqual(
            complete_response.data['storage'],
            'temporary',
        )
        self.assertEqual(
            complete_response.data['url'],
            '',
        )

        internal_client.head_object.assert_called_once_with(
            Bucket=settings.MINIO_BUCKET,
            Key=expected_path,
        )

    @patch(
        'apps.catalog.views.minio_internal_client'
    )
    @patch(
        'apps.catalog.views.minio_public_upload_client'
    )
    def test_trailer_direct_upload_rejects_size_mismatch(
        self,
        mock_public_client,
        mock_internal_client,
    ):
        producer = User.objects.create_user(
            email='trailer-size@example.com',
            password='StrongPass123',
            is_producer=True,
        )
        self.client.force_authenticate(user=producer)

        content = Content.objects.create(
            title='Trailer mismatch',
            type='movie',
            producer=producer,
            producer_submission_status='draft',
        )

        public_client = (
            mock_public_client.return_value
        )
        public_client.generate_presigned_url.return_value = (
            'https://upload.example.test/presigned'
        )

        session_response = self.client.post(
            reverse(
                'content-trailer-upload-session',
                args=[content.id],
            ),
            {
                'filename': 'trailer.mp4',
                'size_bytes': 5000,
            },
            format='json',
        )

        self.assertEqual(
            session_response.status_code,
            status.HTTP_200_OK,
        )

        mock_internal_client.return_value.head_object.return_value = {
            'ContentLength': 4999,
        }

        response = self.client.post(
            reverse(
                'content-trailer-upload-complete',
                args=[content.id],
            ),
            {
                'completion_token':
                    session_response.data[
                        'completion_token'
                    ],
            },
            format='json',
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_400_BAD_REQUEST,
        )

        content.refresh_from_db()

        self.assertEqual(
            content.trailer_temp_path,
            '',
        )

    def test_trailer_direct_upload_rejects_invalid_token(
        self,
    ):
        producer = User.objects.create_user(
            email='trailer-token@example.com',
            password='StrongPass123',
            is_producer=True,
        )
        self.client.force_authenticate(user=producer)

        content = Content.objects.create(
            title='Invalid token trailer',
            type='movie',
            producer=producer,
            producer_submission_status='draft',
        )

        response = self.client.post(
            reverse(
                'content-trailer-upload-complete',
                args=[content.id],
            ),
            {
                'completion_token':
                    'invalid-token',
            },
            format='json',
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_400_BAD_REQUEST,
        )


    def test_admin_can_approve_and_reject_producer_submissions(self):
        producer = User.objects.create_user(
            email='producer-review@example.com',
            password='StrongPass123',
            is_producer=True,
        )
        staff = User.objects.create_user(
            email='reviewer@example.com',
            password='StrongPass123',
            is_staff=True,
        )
        content = Content.objects.create(
            title='Pending Review',
            type='movie',
            producer=producer,
            producer_submission_status='pending',
            submitted_at=timezone.now(),
        )
        rejected_content = Content.objects.create(
            title='Rejected Review',
            type='movie',
            producer=producer,
            producer_submission_status='pending',
            submitted_at=timezone.now(),
        )
        self.client.force_authenticate(user=staff)

        pending_response = self.client.get(reverse('content-pending-submissions'))
        pending_payload = (
            pending_response.data['results']
            if 'results' in pending_response.data
            else pending_response.data
        )
        self.assertEqual(pending_response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(pending_payload), 2)

        approve_response = self.client.post(
            reverse('content-approve-submission', args=[content.id]),
            {'reason': 'Catalogue valide.'},
            format='json',
        )

        self.assertEqual(approve_response.status_code, status.HTTP_200_OK)
        content.refresh_from_db()
        self.assertEqual(content.producer_submission_status, 'approved')
        self.assertEqual(content.review_reason, 'Catalogue valide.')
        self.assertEqual(content.reviewed_by, staff)

        bad_reject_response = self.client.post(
            reverse('content-reject-submission', args=[rejected_content.id]),
            {},
            format='json',
        )
        self.assertEqual(bad_reject_response.status_code, status.HTTP_400_BAD_REQUEST)

        reject_response = self.client.post(
            reverse('content-reject-submission', args=[rejected_content.id]),
            {'reason': 'Poster manquant.'},
            format='json',
        )

        self.assertEqual(reject_response.status_code, status.HTTP_200_OK)
        rejected_content.refresh_from_db()
        self.assertEqual(rejected_content.producer_submission_status, 'rejected')
        self.assertEqual(rejected_content.review_reason, 'Poster manquant.')

    def test_producer_cannot_manage_another_producer_content(self):
        owner = User.objects.create_user(
            email='owner@example.com',
            password='StrongPass123',
            is_producer=True,
        )
        other = User.objects.create_user(
            email='other-producer@example.com',
            password='StrongPass123',
            is_producer=True,
        )
        content = Content.objects.create(title='Private Draft', type='series', producer=owner)
        self.client.force_authenticate(user=other)

        update_response = self.client.patch(
            reverse('content-detail', args=[content.id]),
            {'title': 'Hijacked'},
            format='json',
        )

        self.assertEqual(update_response.status_code, status.HTTP_403_FORBIDDEN)

        season_response = self.client.post(
            reverse('season-list'),
            {'content_id': str(content.id), 'season_number': 1, 'title': 'Season 1'},
            format='json',
        )

        self.assertEqual(season_response.status_code, status.HTTP_403_FORBIDDEN)

    def test_producer_can_manage_own_series_structure(self):
        producer = User.objects.create_user(
            email='series-producer@example.com',
            password='StrongPass123',
            is_producer=True,
        )
        series = Content.objects.create(title='Producer Series', type='series', producer=producer)
        self.client.force_authenticate(user=producer)

        season_response = self.client.post(
            reverse('season-list'),
            {'content_id': str(series.id), 'season_number': 1, 'title': 'Season 1'},
            format='json',
        )

        self.assertEqual(season_response.status_code, status.HTTP_201_CREATED)

        episode_response = self.client.post(
            reverse('episode-list'),
            {
                'season_id': season_response.data['id'],
                'episode_number': 1,
                'title': 'Pilot',
            },
            format='json',
        )

        self.assertEqual(episode_response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(str(episode_response.data['content']), str(series.id))
