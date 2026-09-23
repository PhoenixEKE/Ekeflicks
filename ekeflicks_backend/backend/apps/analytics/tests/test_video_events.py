import uuid

from django.test import TestCase

from apps.analytics.services import (
    build_video_analytics_event,
)
from core.models import (
    Content,
    Genre,
    Profile,
    ProfileType,
    User,
    VideoAsset,
    ViewingSession,
)


class VideoAnalyticsEventTests(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            email='video-analytics@example.com',
            password='StrongPass123!',
            firstname='Video',
            country_code='CI',
        )

        self.profile = Profile.objects.get(
            user=self.user,
        )

        main_type, _ = ProfileType.objects.get_or_create(
            name='main',
            defaults={
                'description': 'Main',
                'can_create_lists': True,
                'can_rate_content': True,
            },
        )

        self.profile.type = main_type
        self.profile.save(update_fields=['type'])

        self.producer = User.objects.create_user(
            email='video-producer@example.com',
            password='StrongPass123!',
            firstname='Producer',
        )

        self.content = Content.objects.create(
            title='Analytics Movie',
            type='movie',
            producer=self.producer,
            duration=10,
        )

        self.genre = Genre.objects.create(
            name='Drama',
            slug='drama',
        )
        self.content.genres.add(self.genre)

        self.asset = VideoAsset.objects.create(
            content=self.content,
            title='Analytics Master',
            duration_seconds=600,
            is_default=True,
        )

        self.session = ViewingSession.objects.create(
            profile=self.profile,
            content=self.content,
            duration_watched=120,
            device_type='mobile',
            quality_played='1080p',
        )

    def test_video_event_maps_real_business_ids(self):
        event = build_video_analytics_event(
            'video_progress',
            self.session,
            position_seconds=180,
            platform='android',
            timezone_name='Africa/Abidjan',
            interface_language='fr',
        )

        self.assertEqual(
            event['user_id'],
            str(self.user.id),
        )
        self.assertEqual(
            event['profile_id'],
            str(self.profile.id),
        )
        self.assertEqual(
            event['profile_type'],
            'main',
        )
        self.assertEqual(
            event['content_id'],
            str(self.content.id),
        )
        self.assertIsNone(
            event['episode_id'],
        )
        self.assertEqual(
            event['producer_id'],
            str(self.producer.id),
        )

        self.assertEqual(
            event['viewing_session_id'],
            str(self.session.session_id),
        )

        # The PostgreSQL BigAutoField PK must never be
        # exported as the ClickHouse viewing session UUID.
        self.assertNotEqual(
            event['viewing_session_id'],
            str(self.session.id),
        )

        # Reserved for G5-1D5 application lifecycle.
        self.assertIsNone(
            event['session_id'],
        )

    def test_video_event_maps_catalog_context(self):
        event = build_video_analytics_event(
            'video_progress',
            self.session,
        )

        self.assertEqual(
            event['content_type'],
            'movie',
        )
        self.assertEqual(
            event['genres'],
            ['Drama'],
        )
        self.assertEqual(
            event['country_code'],
            'CI',
        )
        self.assertEqual(
            event['device_type'],
            'mobile',
        )

    def test_video_event_prefers_asset_duration_seconds(self):
        event = build_video_analytics_event(
            'video_progress',
            self.session,
            position_seconds=150,
        )

        self.assertEqual(
            event['duration_seconds'],
            600,
        )
        self.assertEqual(
            event['watch_seconds'],
            0,
        )
        self.assertEqual(
            event['position_seconds'],
            150,
        )
        self.assertAlmostEqual(
            event['completion_percent'],
            25.0,
        )

    def test_video_event_falls_back_to_content_minutes(self):
        self.asset.delete()

        event = build_video_analytics_event(
            'video_progress',
            self.session,
            position_seconds=300,
        )

        self.assertEqual(
            event['duration_seconds'],
            600,
        )
        self.assertAlmostEqual(
            event['completion_percent'],
            50.0,
        )

    def test_complete_without_known_duration_is_100(self):
        self.asset.delete()
        self.content.duration = None
        self.content.save(update_fields=['duration'])

        self.session.was_completed = True
        self.session.save(update_fields=['was_completed'])

        event = build_video_analytics_event(
            'video_complete',
            self.session,
        )

        self.assertEqual(
            event['duration_seconds'],
            0,
        )
        self.assertEqual(
            event['completion_percent'],
            100.0,
        )

    def test_event_id_can_be_stable_across_retry(self):
        event_id = uuid.uuid4()

        first = build_video_analytics_event(
            'video_progress',
            self.session,
            event_id=event_id,
        )

        second = build_video_analytics_event(
            'video_progress',
            self.session,
            event_id=event_id,
        )

        self.assertEqual(
            first['event_id'],
            str(event_id),
        )
        self.assertEqual(
            second['event_id'],
            str(event_id),
        )

    def test_rejects_unknown_video_event(self):
        with self.assertRaises(ValueError):
            build_video_analytics_event(
                'something_else',
                self.session,
            )

    def test_helper_does_not_write_clickhouse(self):
        event = build_video_analytics_event(
            'video_start',
            self.session,
        )

        self.assertEqual(
            event['event_name'],
            'video_start',
        )

        # Pure payload builder: no enqueue/write side effect.
        self.assertTrue(event['event_id'])


class VideoAnalyticsStrictMetricSemanticsTests(
    VideoAnalyticsEventTests
):
    def test_missing_metrics_do_not_use_session_duration(self):
        self.session.duration_watched = 333
        self.session.save(
            update_fields=['duration_watched']
        )

        event = build_video_analytics_event(
            'video_start',
            self.session,
        )

        self.assertEqual(
            event['watch_seconds'],
            0,
        )
        self.assertEqual(
            event['position_seconds'],
            0,
        )

    def test_watch_delta_does_not_become_position(self):
        event = build_video_analytics_event(
            'video_progress',
            self.session,
            watch_seconds=30,
        )

        self.assertEqual(
            event['watch_seconds'],
            30,
        )
        self.assertEqual(
            event['position_seconds'],
            0,
        )

    def test_position_does_not_become_watch_delta(self):
        event = build_video_analytics_event(
            'video_progress',
            self.session,
            position_seconds=240,
        )

        self.assertEqual(
            event['position_seconds'],
            240,
        )
        self.assertEqual(
            event['watch_seconds'],
            0,
        )

    def test_completion_uses_position_not_watch_delta(self):
        event = build_video_analytics_event(
            'video_progress',
            self.session,
            position_seconds=300,
            watch_seconds=30,
        )

        self.assertEqual(
            event['duration_seconds'],
            600,
        )
        self.assertAlmostEqual(
            event['completion_percent'],
            50.0,
        )
