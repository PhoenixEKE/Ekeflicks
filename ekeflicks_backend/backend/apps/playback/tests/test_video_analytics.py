import uuid
from unittest.mock import patch

from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from core.models import (
    Content,
    Profile,
    ProfileType,
    User,
    VideoAsset,
    ViewingSession,
)


class VideoAnalyticsIngestionAPITests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            email='analytics-viewer@example.com',
            password='StrongPass123!',
            firstname='Viewer',
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
        self.profile.save(
            update_fields=['type']
        )

        self.producer = User.objects.create_user(
            email='analytics-producer@example.com',
            password='StrongPass123!',
            firstname='Producer',
        )

        self.content = Content.objects.create(
            title='Analytics API Movie',
            type='movie',
            producer=self.producer,
            duration=10,
        )

        self.asset = VideoAsset.objects.create(
            content=self.content,
            title='Analytics API Master',
            duration_seconds=600,
            is_default=True,
        )

        self.session = ViewingSession.objects.create(
            profile=self.profile,
            content=self.content,
            device_type='mobile',
            quality_played='1080p',
        )

        self.client.force_authenticate(
            user=self.user
        )

        self.url = reverse(
            'viewing-session-analytics-event',
            args=[self.session.pk],
        )

    @patch(
        'apps.analytics.tasks.'
        'write_analytics_event_task.delay'
    )
    def test_start_is_accepted(self, delay):
        event_id = uuid.uuid4()

        response = self.client.post(
            self.url,
            {
                'event': 'start',
                'event_id': str(event_id),
                'position_seconds': 0,
                'watch_seconds': 0,
                'platform': 'android',
                'timezone': 'Africa/Abidjan',
                'interface_language': 'fr',
                'app_version': '1.0.0',
            },
            format='json',
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_202_ACCEPTED,
        )

        self.assertTrue(
            response.data['accepted']
        )
        self.assertEqual(
            response.data['event_name'],
            'video_start',
        )
        self.assertEqual(
            response.data['event_id'],
            str(event_id),
        )
        self.assertEqual(
            response.data[
                'viewing_session_id'
            ],
            str(self.session.session_id),
        )

        delay.assert_called_once()

        payload = delay.call_args.args[0]

        self.assertEqual(
            payload['event_name'],
            'video_start',
        )
        self.assertEqual(
            payload['viewing_session_id'],
            str(self.session.session_id),
        )
        self.assertIsNone(
            payload['session_id'],
        )
        self.assertEqual(
            payload['platform'],
            'android',
        )
        self.assertEqual(
            payload['timezone'],
            'Africa/Abidjan',
        )
        self.assertEqual(
            payload['interface_language'],
            'fr',
        )
        self.assertEqual(
            payload['app_version'],
            '1.0.0',
        )
        self.assertNotIn(
            'app_version',
            payload['properties'],
        )

    @patch(
        'apps.analytics.tasks.'
        'write_analytics_event_task.delay'
    )
    def test_progress_is_accepted(self, delay):
        response = self.client.post(
            self.url,
            {
                'event': 'progress',
                'position_seconds': 150,
                'watch_seconds': 120,
            },
            format='json',
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_202_ACCEPTED,
        )

        payload = delay.call_args.args[0]

        self.assertEqual(
            payload['event_name'],
            'video_progress',
        )
        self.assertEqual(
            payload['position_seconds'],
            150,
        )
        self.assertEqual(
            payload['watch_seconds'],
            120,
        )
        self.assertEqual(
            payload['duration_seconds'],
            600,
        )
        self.assertAlmostEqual(
            payload['completion_percent'],
            25.0,
        )

    @patch(
        'apps.analytics.tasks.'
        'write_analytics_event_task.delay'
    )
    def test_complete_is_accepted(self, delay):
        response = self.client.post(
            self.url,
            {
                'event': 'complete',
                'position_seconds': 600,
                'watch_seconds': 570,
                'completion_percent': 100,
            },
            format='json',
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_202_ACCEPTED,
        )

        payload = delay.call_args.args[0]

        self.assertEqual(
            payload['event_name'],
            'video_complete',
        )
        self.assertEqual(
            payload['completion_percent'],
            100.0,
        )

    @patch(
        'apps.analytics.tasks.'
        'write_analytics_event_task.delay'
    )
    def test_abandon_is_accepted(self, delay):
        response = self.client.post(
            self.url,
            {
                'event': 'abandon',
                'position_seconds': 220,
                'watch_seconds': 180,
            },
            format='json',
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_202_ACCEPTED,
        )

        payload = delay.call_args.args[0]

        self.assertEqual(
            payload['event_name'],
            'video_abandon',
        )

    @patch(
        'apps.analytics.tasks.'
        'write_analytics_event_task.delay'
    )
    def test_progress_requires_position_or_watch(
        self,
        delay,
    ):
        response = self.client.post(
            self.url,
            {
                'event': 'progress',
            },
            format='json',
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_400_BAD_REQUEST,
        )

        delay.assert_not_called()

    @patch(
        'apps.analytics.tasks.'
        'write_analytics_event_task.delay'
    )
    def test_unknown_event_is_rejected(
        self,
        delay,
    ):
        response = self.client.post(
            self.url,
            {
                'event': 'pause',
                'position_seconds': 10,
            },
            format='json',
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_400_BAD_REQUEST,
        )

        delay.assert_not_called()

    @patch(
        'apps.analytics.tasks.'
        'write_analytics_event_task.delay'
    )
    def test_other_user_cannot_emit_event(
        self,
        delay,
    ):
        other = User.objects.create_user(
            email='other-viewer@example.com',
            password='StrongPass123!',
            firstname='Other',
        )

        self.client.force_authenticate(
            user=other
        )

        response = self.client.post(
            self.url,
            {
                'event': 'start',
            },
            format='json',
        )

        # get_object() operates on the ownership-filtered
        # queryset, therefore another user's session is hidden.
        self.assertEqual(
            response.status_code,
            status.HTTP_404_NOT_FOUND,
        )

        delay.assert_not_called()

    @patch(
        'apps.analytics.tasks.'
        'write_analytics_event_task.delay'
    )
    def test_same_event_id_is_forwarded_stably(
        self,
        delay,
    ):
        event_id = uuid.uuid4()

        for _ in range(2):
            response = self.client.post(
                self.url,
                {
                    'event': 'progress',
                    'event_id': str(event_id),
                    'position_seconds': 60,
                    'watch_seconds': 50,
                },
                format='json',
            )

            self.assertEqual(
                response.status_code,
                status.HTTP_202_ACCEPTED,
            )

        self.assertEqual(
            delay.call_count,
            2,
        )

        first = delay.call_args_list[0].args[0]
        second = delay.call_args_list[1].args[0]

        self.assertEqual(
            first['event_id'],
            str(event_id),
        )
        self.assertEqual(
            second['event_id'],
            str(event_id),
        )

    @patch(
        'apps.analytics.tasks.'
        'write_analytics_event_task.delay'
    )
    def test_endpoint_does_not_mutate_viewing_session(
        self,
        delay,
    ):
        before = {
            'duration_watched':
                self.session.duration_watched,
            'was_completed':
                self.session.was_completed,
            'end_time':
                self.session.end_time,
        }

        response = self.client.post(
            self.url,
            {
                'event': 'complete',
                'position_seconds': 600,
                'watch_seconds': 580,
                'completion_percent': 100,
            },
            format='json',
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_202_ACCEPTED,
        )

        self.session.refresh_from_db()

        self.assertEqual(
            self.session.duration_watched,
            before['duration_watched'],
        )
        self.assertEqual(
            self.session.was_completed,
            before['was_completed'],
        )
        self.assertEqual(
            self.session.end_time,
            before['end_time'],
        )

        delay.assert_called_once()


class VideoAnalyticsContractHardeningTests(
    VideoAnalyticsIngestionAPITests
):
    """
    Additional contract tests.

    watch_seconds is intentionally a delta representing active
    watch time since the previous analytics heartbeat.

    position_seconds is the absolute player position.

    The server does not infer one from the other.
    """

    @patch(
        'apps.analytics.tasks.'
        'write_analytics_event_task.delay'
    )
    def test_progress_preserves_watch_delta(
        self,
        delay,
    ):
        response = self.client.post(
            self.url,
            {
                'event': 'progress',
                'position_seconds': 300,
                'watch_seconds': 30,
            },
            format='json',
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_202_ACCEPTED,
        )

        payload = delay.call_args.args[0]

        self.assertEqual(
            payload['position_seconds'],
            300,
        )
        self.assertEqual(
            payload['watch_seconds'],
            30,
        )

    @patch(
        'apps.analytics.tasks.'
        'write_analytics_event_task.delay'
    )
    def test_old_occurred_at_is_rejected(
        self,
        delay,
    ):
        from datetime import timedelta
        from django.utils import timezone

        occurred_at = (
            timezone.now()
            - timedelta(hours=25)
        )

        response = self.client.post(
            self.url,
            {
                'event': 'start',
                'occurred_at':
                    occurred_at.isoformat(),
            },
            format='json',
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_400_BAD_REQUEST,
        )

        delay.assert_not_called()

    @patch(
        'apps.analytics.tasks.'
        'write_analytics_event_task.delay'
    )
    def test_far_future_occurred_at_is_rejected(
        self,
        delay,
    ):
        from datetime import timedelta
        from django.utils import timezone

        occurred_at = (
            timezone.now()
            + timedelta(minutes=6)
        )

        response = self.client.post(
            self.url,
            {
                'event': 'start',
                'occurred_at':
                    occurred_at.isoformat(),
            },
            format='json',
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_400_BAD_REQUEST,
        )

        delay.assert_not_called()

    @patch(
        'apps.analytics.tasks.'
        'write_analytics_event_task.delay'
    )
    def test_small_clock_skew_is_accepted(
        self,
        delay,
    ):
        from datetime import timedelta
        from django.utils import timezone

        occurred_at = (
            timezone.now()
            + timedelta(minutes=2)
        )

        response = self.client.post(
            self.url,
            {
                'event': 'start',
                'occurred_at':
                    occurred_at.isoformat(),
            },
            format='json',
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_202_ACCEPTED,
        )

        delay.assert_called_once()

    @patch(
        'apps.analytics.tasks.'
        'write_analytics_event_task.delay'
    )
    def test_app_version_uses_real_column(
        self,
        delay,
    ):
        response = self.client.post(
            self.url,
            {
                'event': 'start',
                'app_version': '2.4.1',
            },
            format='json',
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_202_ACCEPTED,
        )

        payload = delay.call_args.args[0]

        self.assertEqual(
            payload['app_version'],
            '2.4.1',
        )

        self.assertNotIn(
            'app_version',
            payload['properties'],
        )


class VideoAnalyticsStrictPositionContractTests(
    VideoAnalyticsIngestionAPITests
):
    def test_progress_rejects_watch_seconds_without_position(self):
        response = self.client.post(
            f'/api/v1/viewing-sessions/{self.session.pk}/analytics/',
            {
                'event': 'progress',
                'watch_seconds': 30,
            },
            format='json',
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_400_BAD_REQUEST,
        )

        self.assertIn(
            'position_seconds',
            response.data,
        )

    def test_complete_rejects_watch_seconds_without_position(self):
        response = self.client.post(
            f'/api/v1/viewing-sessions/{self.session.pk}/analytics/',
            {
                'event': 'complete',
                'watch_seconds': 30,
            },
            format='json',
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_400_BAD_REQUEST,
        )

        self.assertIn(
            'position_seconds',
            response.data,
        )

    def test_abandon_rejects_watch_seconds_without_position(self):
        response = self.client.post(
            f'/api/v1/viewing-sessions/{self.session.pk}/analytics/',
            {
                'event': 'abandon',
                'watch_seconds': 15,
            },
            format='json',
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_400_BAD_REQUEST,
        )

        self.assertIn(
            'position_seconds',
            response.data,
        )

    def test_progress_accepts_position_without_watch_seconds(self):
        with patch(
            'apps.analytics.tasks.'
            'write_analytics_event_task.delay'
        ):
            response = self.client.post(
                f'/api/v1/viewing-sessions/{self.session.pk}/analytics/',
                {
                    'event': 'progress',
                    'position_seconds': 30,
                },
                format='json',
            )

        self.assertEqual(
            response.status_code,
            status.HTTP_202_ACCEPTED,
        )

    def test_complete_accepts_position_without_watch_seconds(self):
        with patch(
            'apps.analytics.tasks.'
            'write_analytics_event_task.delay'
        ):
            response = self.client.post(
                f'/api/v1/viewing-sessions/{self.session.pk}/analytics/',
                {
                    'event': 'complete',
                    'position_seconds': 120,
                },
                format='json',
            )

        self.assertEqual(
            response.status_code,
            status.HTTP_202_ACCEPTED,
        )

    def test_abandon_accepts_position_without_watch_seconds(self):
        with patch(
            'apps.analytics.tasks.'
            'write_analytics_event_task.delay'
        ):
            response = self.client.post(
                f'/api/v1/viewing-sessions/{self.session.pk}/analytics/',
                {
                    'event': 'abandon',
                    'position_seconds': 75,
                },
                format='json',
            )

        self.assertEqual(
            response.status_code,
            status.HTTP_202_ACCEPTED,
        )
