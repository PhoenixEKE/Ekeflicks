from datetime import (
    datetime,
    timedelta,
    timezone,
)
from unittest.mock import patch

from django.contrib.auth import get_user_model
from django.urls import (
    resolve,
    reverse,
)
from rest_framework import status
from rest_framework.test import APITestCase


User = get_user_model()


class AppSessionAnalyticsAPITests(
    APITestCase
):
    def setUp(self):
        self.admin = User.objects.create_user(
            email='d5-admin@example.com',
            password='StrongPassword123!',
            is_staff=True,
            is_superuser=True,
        )

        self.viewer = User.objects.create_user(
            email='d5-viewer@example.com',
            password='StrongPassword123!',
        )

        self.start_at = datetime(
            2026,
            9,
            10,
            0,
            0,
            0,
            tzinfo=timezone.utc,
        )

        self.end_at = (
            self.start_at
            + timedelta(days=1)
        )

        self.url = reverse(
            'app-session-analytics'
        )

    def _params(self):
        return {
            'start_at':
                self.start_at.isoformat(),

            'end_at':
                self.end_at.isoformat(),
        }

    def test_router_resolves_analytics_action(
        self,
    ):
        match = resolve(
            '/api/v1/app-sessions/analytics/'
        )

        self.assertEqual(
            match.url_name,
            'app-session-analytics',
        )

    def test_anonymous_cannot_read_global_analytics(
        self,
    ):
        response = self.client.get(
            self.url,
            self._params(),
        )

        self.assertIn(
            response.status_code,
            (
                status.HTTP_401_UNAUTHORIZED,
                status.HTTP_403_FORBIDDEN,
            ),
        )

    def test_authenticated_non_admin_cannot_read_global_analytics(
        self,
    ):
        self.client.force_authenticate(
            self.viewer
        )

        response = self.client.get(
            self.url,
            self._params(),
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_403_FORBIDDEN,
        )

    @patch(
        'apps.analytics.services.'
        'app_session_analytics'
    )
    def test_admin_analytics_delegates_to_b3_engine(
        self,
        engine,
    ):
        engine.return_value = {
            'sessions': 5,
            'unique_profiles': 3,
            'closed_sessions': 4,
            'open_sessions': 1,
            'avg_session_duration_seconds':
                90.0,
            'sessions_per_profile':
                5 / 3,
        }

        self.client.force_authenticate(
            self.admin
        )

        response = self.client.get(
            self.url,
            self._params(),
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_200_OK,
        )

        engine.assert_called_once()

        kwargs = engine.call_args.kwargs

        self.assertEqual(
            kwargs['start_at'],
            self.start_at,
        )

        self.assertEqual(
            kwargs['end_at'],
            self.end_at,
        )

        self.assertEqual(
            response.data['scope'],
            'global',
        )

        self.assertEqual(
            response.data['timezone'],
            'UTC',
        )

        self.assertEqual(
            response.data['metrics']['sessions'],
            5,
        )

        self.assertEqual(
            response.data['metrics'][
                'unique_profiles'
            ],
            3,
        )

        self.assertEqual(
            response.data['metrics'][
                'closed_sessions'
            ],
            4,
        )

        self.assertEqual(
            response.data['metrics'][
                'open_sessions'
            ],
            1,
        )

    def test_missing_window_is_400(
        self,
    ):
        self.client.force_authenticate(
            self.admin
        )

        response = self.client.get(
            self.url
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_400_BAD_REQUEST,
        )

        self.assertIn(
            'start_at',
            response.data,
        )

        self.assertIn(
            'end_at',
            response.data,
        )

    def test_invalid_window_is_400(
        self,
    ):
        self.client.force_authenticate(
            self.admin
        )

        response = self.client.get(
            self.url,
            {
                'start_at':
                    self.end_at.isoformat(),

                'end_at':
                    self.start_at.isoformat(),
            },
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_400_BAD_REQUEST,
        )

        self.assertIn(
            'end_at',
            response.data,
        )

    def test_equal_window_is_400(
        self,
    ):
        self.client.force_authenticate(
            self.admin
        )

        point = (
            self.start_at.isoformat()
        )

        response = self.client.get(
            self.url,
            {
                'start_at': point,
                'end_at': point,
            },
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_400_BAD_REQUEST,
        )

    @patch(
        'apps.analytics.services.'
        'app_session_analytics'
    )
    def test_empty_metrics_are_returned_without_fabrication(
        self,
        engine,
    ):
        engine.return_value = {
            'sessions': 0,
            'unique_profiles': 0,
            'closed_sessions': 0,
            'open_sessions': 0,
            'avg_session_duration_seconds':
                0.0,
            'sessions_per_profile':
                0.0,
        }

        self.client.force_authenticate(
            self.admin
        )

        response = self.client.get(
            self.url,
            self._params(),
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_200_OK,
        )

        self.assertEqual(
            response.data['metrics'],
            engine.return_value,
        )

    def test_events_action_remains_authenticated_not_admin_only(
        self,
    ):
        """
        Permission regression only.

        A normal authenticated viewer must reach the events
        action. An intentionally invalid payload should therefore
        produce 400, not 403.
        """

        self.client.force_authenticate(
            self.viewer
        )

        response = self.client.post(
            reverse(
                'app-session-events'
            ),
            data={},
            format='json',
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_400_BAD_REQUEST,
        )

    def test_analytics_endpoint_does_not_accept_post(
        self,
    ):
        self.client.force_authenticate(
            self.admin
        )

        response = self.client.post(
            self.url,
            data=self._params(),
            format='json',
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_405_METHOD_NOT_ALLOWED,
        )
