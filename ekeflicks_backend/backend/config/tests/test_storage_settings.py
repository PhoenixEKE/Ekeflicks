from django.test import SimpleTestCase

from config import settings


class B2StorageSettingsTests(SimpleTestCase):
    def test_media_bucket_defaults_are_explicit(self):
        self.assertEqual(
            settings.B2_BUCKET_DEFAULTS,
            {
                'videos': 'ekeflicks-videos',
                'trailers': 'ekeflicks-trailers',
                'subtitles': 'ekeflicks-subtitles',
                'posters': 'ekeflicks-posters',
                'backdrops': 'ekeflicks-backdrops',
                'avatars': 'ekeflicks-avatars',
            },
        )

    def test_final_storage_aliases_use_their_dedicated_bucket_setting(self):
        self.assertEqual(
            settings.B2_FINAL_BUCKETS,
            {
                'final_videos': settings.B2_VIDEO_BUCKET,
                'final_trailers': settings.B2_TRAILER_BUCKET,
                'final_subtitles': settings.B2_SUBTITLE_BUCKET,
                'final_posters': settings.B2_POSTER_BUCKET,
                'final_backdrops': settings.B2_BACKDROP_BUCKET,
                'final_avatars': settings.B2_AVATAR_BUCKET,
            },
        )

    def test_b2_storage_options_override_the_base_video_bucket(self):
        options = settings.b2_storage_options('ekeflicks-avatars')

        self.assertEqual(options['bucket_name'], 'ekeflicks-avatars')
