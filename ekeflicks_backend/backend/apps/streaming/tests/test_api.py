from django.core.files.uploadedfile import SimpleUploadedFile
from django.core.files.storage import storages
from django.test import override_settings
from django.urls import reverse
from django.utils import timezone
from rest_framework import status
from rest_framework.test import APITestCase

from core.models import (
    Content,
    Episode,
    Profile,
    Season,
    Subscription,
    SubscriptionPlan,
    User,
    VideoAsset,
    VideoRendition,
)
from apps.streaming.storage_paths import build_final_hls_path
from apps.streaming.tasks import _upload_hls_tree


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


class StreamingApiTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            email='streamer@example.com',
            password='StrongPass123',
            firstname='Streamer',
        )
        self.profile = Profile.objects.get(user=self.user)
        self.plan = SubscriptionPlan.objects.create(
            name='Premium',
            slug='premium-streaming',
            price='19.99',
            duration_days=30,
            max_quality='1080p',
            download_enabled=True,
        )
        self.subscription = Subscription.objects.create(
            user=self.user,
            plan=self.plan,
            status='active',
            expires_at=timezone.now() + timezone.timedelta(days=30),
        )
        self.content = Content.objects.create(title='Stream Ready', type='movie')
        self.asset = VideoAsset.objects.create(
            content=self.content,
            hls_master_url=f'https://cdn.ekeflicks.com/movies/{self.content.id}/manifest.m3u8',
            status='ready',
            moderation_status='approved',
            published_at=timezone.now(),
            is_downloadable=True,
        )
        VideoRendition.objects.create(
            asset=self.asset,
            quality='720p',
            width=1280,
            height=720,
            bandwidth=2800000,
            hls_playlist_url=f'https://cdn.ekeflicks.com/movies/{self.content.id}/720p/index.m3u8',
        )

    def test_manifest_requires_authentication(self):
        response = self.client.get(reverse('video-asset-manifest', args=[self.asset.id]))

        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_manifest_returns_hls_data_for_active_subscription(self):
        self.client.force_authenticate(user=self.user)

        response = self.client.get(
            reverse('video-asset-manifest', args=[self.asset.id]),
            {'profile': str(self.profile.id)},
        )

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(response.data['hls_master_url'].startswith(self.asset.hls_master_url))
        self.assertIn('ef_sig=', response.data['hls_master_url'])
        self.assertTrue(response.data['signed_urls_enabled'])
        self.assertTrue(response.data['offline_allowed'])
        self.assertEqual(response.data['renditions'][0]['quality'], '720p')
        self.assertIn('ef_sig=', response.data['renditions'][0]['hls_playlist_url'])

    def test_playback_license_can_be_created_for_active_subscription(self):
        self.asset.drm_provider = 'aes_128'
        self.asset.save(update_fields=['drm_provider', 'updated_at'])
        self.client.force_authenticate(user=self.user)

        response = self.client.post(
            reverse('video-asset-license', args=[self.asset.id]),
            {
                'profile_id': str(self.profile.id),
                'device_id': 'tv-001',
                'device_type': 'tv',
            },
            format='json',
        )

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data['drm_provider'], 'aes_128')
        self.assertTrue(response.data['license_token'])
        self.assertTrue(response.data['key_id'])
        self.assertIn('/drm-key/', response.data['key_url'])
        self.asset.refresh_from_db()
        self.assertEqual(response.data['key_id'], self.asset.encryption_key_id)

    def test_drm_key_requires_valid_license(self):
        self.asset.drm_provider = 'aes_128'
        self.asset.save(update_fields=['drm_provider', 'updated_at'])

        response = self.client.get(reverse('video-asset-drm-key', args=[self.asset.id]))

        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_drm_key_returns_aes_key_for_valid_license(self):
        self.asset.drm_provider = 'aes_128'
        self.asset.save(update_fields=['drm_provider', 'updated_at'])
        self.client.force_authenticate(user=self.user)
        license_response = self.client.post(
            reverse('video-asset-license', args=[self.asset.id]),
            {
                'profile_id': str(self.profile.id),
                'device_id': 'mobile-001',
                'device_type': 'mobile',
            },
            format='json',
        )

        self.client.force_authenticate(user=None)
        response = self.client.get(
            reverse('video-asset-drm-key', args=[self.asset.id]),
            {'license_token': license_response.data['license_token']},
        )

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response['Content-Type'], 'application/octet-stream')
        self.assertEqual(len(response.content), 16)

    def test_offline_license_can_be_created_for_active_subscription(self):
        self.client.force_authenticate(user=self.user)

        response = self.client.post(
            reverse('video-asset-request-offline', args=[self.asset.id]),
            {
                'profile_id': str(self.profile.id),
                'device_id': 'phone-001',
                'device_type': 'mobile',
            },
            format='json',
        )

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data['device_id'], 'phone-001')
        self.assertEqual(response.data['status'], 'active')

    @override_settings(
        AXINOM_DRM_ENABLED=True,
        AXINOM_TENANT_ID='tenant-123',
        AXINOM_POLICY_ID='policy-456',
        AXINOM_COMMUNICATION_KEY_ID='key-1',
        AXINOM_COMMUNICATION_KEY='secret',
        AXINOM_WIDEVINE_LICENSE_URL='https://drm.ekeflicks.test/widevine',
        AXINOM_FAIRPLAY_LICENSE_URL='https://drm.ekeflicks.test/fairplay',
        AXINOM_FAIRPLAY_CERTIFICATE_URL='https://drm.ekeflicks.test/fairplay.cer',
        DRM_ANDROID_OFFLINE_LICENSE_DAYS=21,
    )
    def test_axinom_android_offline_license_returns_widevine_entitlement(self):
        self.asset.drm_provider = 'axinom'
        self.asset.save(update_fields=['drm_provider', 'updated_at'])
        self.client.force_authenticate(user=self.user)

        response = self.client.post(
            reverse('video-asset-offline-license', args=[self.asset.id]),
            {
                'profile_id': str(self.profile.id),
                'device_id': 'android-phone-001',
                'device_type': 'mobile',
                'platform': 'android',
            },
            format='json',
        )

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data['license_mode'], 'offline')
        self.assertEqual(response.data['drm_provider'], 'axinom')
        self.assertEqual(response.data['drm']['provider'], 'axinom')
        self.assertEqual(response.data['drm']['drm_system'], 'widevine')
        self.assertEqual(response.data['drm']['license_url'], 'https://drm.ekeflicks.test/widevine')
        self.assertTrue(response.data['drm']['entitlement_token'])
        self.assertEqual(response.data['offline_license_days'], 21)

    @override_settings(
        AXINOM_DRM_ENABLED=True,
        AXINOM_COMMUNICATION_KEY='secret',
        AXINOM_WIDEVINE_LICENSE_URL='https://drm.ekeflicks.test/widevine',
        AXINOM_FAIRPLAY_LICENSE_URL='https://drm.ekeflicks.test/fairplay',
        AXINOM_FAIRPLAY_CERTIFICATE_URL='https://drm.ekeflicks.test/fairplay.cer',
        DRM_IOS_OFFLINE_LICENSE_DAYS=14,
    )
    def test_axinom_ios_offline_license_returns_fairplay_configuration(self):
        self.asset.drm_provider = 'axinom'
        self.asset.save(update_fields=['drm_provider', 'updated_at'])
        self.client.force_authenticate(user=self.user)

        response = self.client.post(
            reverse('video-asset-license', args=[self.asset.id]),
            {
                'profile_id': str(self.profile.id),
                'device_id': 'ios-phone-001',
                'device_type': 'mobile',
                'platform': 'ios',
                'offline': True,
            },
            format='json',
        )

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data['license_mode'], 'offline')
        self.assertEqual(response.data['drm']['drm_system'], 'fairplay')
        self.assertEqual(response.data['drm']['license_url'], 'https://drm.ekeflicks.test/fairplay')
        self.assertEqual(response.data['drm']['fairplay_certificate_url'], 'https://drm.ekeflicks.test/fairplay.cer')
        self.assertEqual(response.data['drm']['ios']['license_duration_days'], 14)

    @override_settings(STORAGES=TEST_FILE_STORAGES)
    def test_staff_can_upload_video_source(self):
        storages._storages.clear()
        self.user.is_staff = True
        self.user.save(update_fields=['is_staff'])
        self.client.force_authenticate(user=self.user)
        uploaded_file = SimpleUploadedFile(
            'source.mp4',
            b'fake video bytes',
            content_type='video/mp4',
        )

        response = self.client.post(
            reverse('video-asset-upload-source', args=[self.asset.id]),
            {'file': uploaded_file},
            format='multipart',
        )

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.asset.refresh_from_db()
        self.assertTrue(
            self.asset.source_file_path.startswith(f'uploads/producer_{self.user.id}/')
        )
        self.assertIn(f'asset_{self.asset.id}/video_original.mp4', self.asset.source_file_path)
        self.assertEqual(self.asset.source_file_size_bytes, len(b'fake video bytes'))

    @override_settings(STORAGES=TEST_FILE_STORAGES)
    def test_producer_can_create_and_upload_own_video_asset(self):
        storages._storages.clear()
        producer = User.objects.create_user(
            email='producer-video@example.com',
            password='StrongPass123',
            is_producer=True,
        )
        content = Content.objects.create(
            title='Producer Video',
            type='movie',
            producer=producer,
        )
        self.client.force_authenticate(user=producer)

        create_response = self.client.post(
            reverse('video-asset-list'),
            {
                'content_id': str(content.id),
                'title': 'Master source',
                'is_downloadable': True,
            },
            format='json',
        )

        self.assertEqual(create_response.status_code, status.HTTP_201_CREATED)
        asset = VideoAsset.objects.get(id=create_response.data['id'])
        self.assertEqual(asset.content, content)
        self.assertEqual(asset.moderation_status, 'pending')

        uploaded_file = SimpleUploadedFile(
            'source.mp4',
            b'producer video bytes',
            content_type='video/mp4',
        )
        upload_response = self.client.post(
            reverse('video-asset-upload-source', args=[asset.id]),
            {'file': uploaded_file},
            format='multipart',
        )

        self.assertEqual(upload_response.status_code, status.HTTP_200_OK)
        asset.refresh_from_db()
        self.assertEqual(asset.source_uploaded_by, producer)
        self.assertEqual(asset.moderation_status, 'pending')
        self.assertIn(f'asset_{asset.id}/video_original.mp4', asset.source_file_path)

        mine_response = self.client.get(reverse('video-asset-mine'))
        mine_payload = mine_response.data['results'] if 'results' in mine_response.data else mine_response.data
        self.assertEqual(mine_response.status_code, status.HTTP_200_OK)
        self.assertEqual(mine_payload[0]['id'], str(asset.id))

        dashboard_response = self.client.get(reverse('video-asset-producer-dashboard'))
        self.assertEqual(dashboard_response.status_code, status.HTTP_200_OK)
        self.assertEqual(dashboard_response.data['video_asset_total'], 1)
        self.assertEqual(dashboard_response.data['by_moderation_status']['pending'], 1)

    def test_producer_cannot_create_asset_for_another_producer_content(self):
        owner = User.objects.create_user(
            email='asset-owner@example.com',
            password='StrongPass123',
            is_producer=True,
        )
        other = User.objects.create_user(
            email='asset-other@example.com',
            password='StrongPass123',
            is_producer=True,
        )
        content = Content.objects.create(title='Owned Asset Content', type='movie', producer=owner)
        self.client.force_authenticate(user=other)

        response = self.client.post(
            reverse('video-asset-list'),
            {'content_id': str(content.id), 'title': 'Forbidden asset'},
            format='json',
        )

        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_producer_cannot_start_transcode_or_approve_video_asset(self):
        producer = User.objects.create_user(
            email='no-review@example.com',
            password='StrongPass123',
            is_producer=True,
        )
        content = Content.objects.create(title='No Review', type='movie', producer=producer)
        asset = VideoAsset.objects.create(
            content=content,
            source_file_path='uploads/source.mp4',
            moderation_status='pending',
        )
        self.client.force_authenticate(user=producer)

        transcode_response = self.client.post(
            reverse('video-asset-start-transcode', args=[asset.id]),
        )
        approve_response = self.client.post(
            reverse('video-asset-approve', args=[asset.id]),
            {'reason': 'Self review'},
            format='json',
        )

        self.assertEqual(transcode_response.status_code, status.HTTP_403_FORBIDDEN)
        self.assertEqual(approve_response.status_code, status.HTTP_403_FORBIDDEN)

    def test_staff_can_list_pending_video_submissions(self):
        staff = User.objects.create_user(
            email='video-reviewer@example.com',
            password='StrongPass123',
            is_staff=True,
        )
        producer = User.objects.create_user(
            email='pending-video@example.com',
            password='StrongPass123',
            is_producer=True,
        )
        content = Content.objects.create(title='Pending Video', type='movie', producer=producer)
        asset = VideoAsset.objects.create(
            content=content,
            title='Pending source',
            source_uploaded_by=producer,
            moderation_status='pending',
        )
        self.client.force_authenticate(user=staff)

        response = self.client.get(reverse('video-asset-pending-submissions'))
        payload = response.data['results'] if 'results' in response.data else response.data

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(payload[0]['id'], str(asset.id))

    @override_settings(
        MEDIA_CDN_BASE_URL='https://cdn.ekeflicks.com',
        STORAGES=TEST_FILE_STORAGES,
    )
    def test_staff_can_upload_subtitle_track(self):
        storages._storages.clear()
        self.user.is_staff = True
        self.user.save(update_fields=['is_staff'])
        self.client.force_authenticate(user=self.user)
        uploaded_file = SimpleUploadedFile(
            'fr.vtt',
            b'WEBVTT\n\n00:00:00.000 --> 00:00:02.000\nBonjour\n',
            content_type='text/vtt',
        )

        response = self.client.post(
            reverse('video-asset-upload-subtitle', args=[self.asset.id]),
            {
                'file': uploaded_file,
                'language': 'fr',
                'label': 'Francais',
                'is_default': True,
            },
            format='multipart',
        )

        expected_url = f'https://cdn.ekeflicks.com/subtitles/{self.content.id}/fr.vtt'
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['url'], expected_url)
        self.assertEqual(response.data['subtitle_track']['url'], expected_url)
        self.assertEqual(response.data['subtitle_track']['language'], 'fr')
        self.assertTrue(response.data['subtitle_track']['is_default'])

    def test_staff_can_approve_video_asset(self):
        self.user.is_staff = True
        self.user.save(update_fields=['is_staff'])
        self.client.force_authenticate(user=self.user)

        response = self.client.post(
            reverse('video-asset-approve', args=[self.asset.id]),
            {'reason': 'Qualite video validee'},
            format='json',
        )

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.asset.refresh_from_db()
        self.assertEqual(self.asset.moderation_status, 'approved')
        self.assertEqual(self.asset.moderation_reason, 'Qualite video validee')
        self.assertEqual(self.asset.moderated_by, self.user)

    def test_staff_reject_requires_reason(self):
        self.user.is_staff = True
        self.user.save(update_fields=['is_staff'])
        self.client.force_authenticate(user=self.user)

        response = self.client.post(
            reverse('video-asset-reject', args=[self.asset.id]),
            {},
            format='json',
        )

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_video_asset_must_be_approved_before_publish(self):
        self.user.is_staff = True
        self.user.save(update_fields=['is_staff'])
        self.asset.moderation_status = 'pending'
        self.asset.published_at = None
        self.asset.save(update_fields=['moderation_status', 'published_at', 'updated_at'])
        self.client.force_authenticate(user=self.user)

        response = self.client.post(reverse('video-asset-publish', args=[self.asset.id]))

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.asset.refresh_from_db()
        self.assertNotEqual(self.asset.moderation_status, 'approved')

    def test_staff_can_reject_video_asset_with_reason(self):
        self.user.is_staff = True
        self.user.save(update_fields=['is_staff'])
        self.client.force_authenticate(user=self.user)

        response = self.client.post(
            reverse('video-asset-reject', args=[self.asset.id]),
            {'reason': 'Audio non conforme'},
            format='json',
        )

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.asset.refresh_from_db()
        self.assertEqual(self.asset.moderation_status, 'rejected')
        self.assertEqual(self.asset.moderation_reason, 'Audio non conforme')

    def test_series_asset_uses_episode_final_storage_path(self):
        series = Content.objects.create(title='Series Ready', type='series')
        season = Season.objects.create(content=series, season_number=1, title='Season 1')
        episode = Episode.objects.create(
            content=series,
            season=season,
            episode_number=2,
            title='Episode 2',
        )
        asset = VideoAsset.objects.create(content=series, episode=episode)

        final_path = build_final_hls_path(asset, 'master.m3u8')

        self.assertEqual(
            final_path,
            f'series/{series.id}/season_01/episode_02/manifest.m3u8',
        )

    @override_settings(
        STREAMING_CDN_BASE_URL='https://cdn.ekeflicks.com',
        STORAGES=TEST_FILE_STORAGES,
    )
    def test_upload_hls_tree_saves_files_to_storage(self):
        storages._storages.clear()
        output_root = timezone.datetime.now().strftime('test-hls-%Y%m%d%H%M%S%f')
        from pathlib import Path
        from django.conf import settings
        root = Path(settings.MEDIA_ROOT) / output_root
        rendition_dir = root / '720p'
        rendition_dir.mkdir(parents=True, exist_ok=True)
        (root / 'master.m3u8').write_text('#EXTM3U\n720p/index.m3u8\n', encoding='utf-8')
        (rendition_dir / 'index.m3u8').write_text('#EXTM3U\nsegment_00000.ts\n', encoding='utf-8')
        (rendition_dir / 'segment_00000.ts').write_bytes(b'video segment')

        uploaded = _upload_hls_tree(self.asset, root)

        self.assertEqual(
            uploaded['master.m3u8'],
            f'https://cdn.ekeflicks.com/movies/{self.content.id}/manifest.m3u8',
        )
        self.assertEqual(
            uploaded['720p/index.m3u8'],
            f'https://cdn.ekeflicks.com/movies/{self.content.id}/720p/index.m3u8',
        )

    @override_settings(STREAMING_CDN_BASE_URL='')
    def test_upload_hls_tree_uses_final_media_storage(self):
        import tempfile
        from pathlib import Path

        with tempfile.TemporaryDirectory() as output_dir:
            with tempfile.TemporaryDirectory() as internal_dir:
                with tempfile.TemporaryDirectory() as final_dir:
                    root = Path(output_dir)
                    (root / 'master.m3u8').write_text('#EXTM3U\n', encoding='utf-8')
                    storage_path = f'movies/{self.content.id}/manifest.m3u8'
                    storage_config = {
                        'default': {
                            'BACKEND': 'django.core.files.storage.FileSystemStorage',
                            'OPTIONS': {'location': internal_dir, 'base_url': '/internal-media/'},
                        },
                        'staticfiles': {
                            'BACKEND': 'django.contrib.staticfiles.storage.StaticFilesStorage',
                        },
                        'final_media': {
                            'BACKEND': 'django.core.files.storage.FileSystemStorage',
                            'OPTIONS': {'location': final_dir, 'base_url': '/final-media/'},
                        },
                        'final_videos': {
                            'BACKEND': 'django.core.files.storage.FileSystemStorage',
                            'OPTIONS': {'location': final_dir, 'base_url': '/final-media/'},
                        },
                    }

                    storages._storages.clear()
                    with self.settings(STORAGES=storage_config):
                        storages._storages.clear()
                        uploaded = _upload_hls_tree(self.asset, root)

                    self.assertTrue((Path(final_dir) / storage_path).exists())
                    self.assertFalse((Path(internal_dir) / storage_path).exists())
                    self.assertEqual(uploaded['master.m3u8'], f'/final-media/{storage_path}')

        storages._storages.clear()
