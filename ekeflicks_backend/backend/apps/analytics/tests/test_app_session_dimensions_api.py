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


class AppSessionDimensionsAPITests(
    APITestCase
):
    def setUp(self):
        self.admin = User.objects.create_user(
            email='d5-dim-admin@example.com',
            password='StrongPassword123!',
            is_staff=True,
            is_superuser=True,
        )

        self.viewer = User.objects.create_user(
            email='d5-dim-viewer@example.com',
            password='StrongPassword123!',
        )

        self.start_at = datetime(
            2026,
            9,
            10,
            tzinfo=timezone.utc,
        )

        self.end_at = (
            self.start_at
            + timedelta(days=1)
        )

        self.url = reverse(
            'app-session-dimensions'
        )

    def _params(self):
        return {
            'start_at':
                self.start_at.isoformat(),

            'end_at':
                self.end_at.isoformat(),

            'dimension':
                'platform',
        }

    def test_router_resolves(self):
        match = resolve(
            '/api/v1/app-sessions/dimensions/'
        )

        self.assertEqual(
            match.url_name,
            'app-session-dimensions',
        )

    def test_anonymous_denied(self):
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

    def test_non_admin_denied(self):
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
        'app_session_dimension_analytics'
    )
    def test_admin_gets_results(
        self,
        engine,
    ):
        engine.return_value = [
            {
                'dimension_value':
                    'android',
                'sessions': 5,
                'unique_profiles': 3,
                'closed_sessions': 4,
                'open_sessions': 1,
                'avg_session_duration_seconds':
                    90.0,
                'sessions_per_profile':
                    5 / 3,
            },
        ]

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
            kwargs['dimension'],
            'platform',
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
            response.data['dimension'],
            'platform',
        )

        self.assertEqual(
            response.data['results'][0][
                'sessions'
            ],
            5,
        )

    def test_missing_dimension_is_400(self):
        self.client.force_authenticate(
            self.admin
        )

        response = self.client.get(
            self.url,
            {
                'start_at':
                    self.start_at.isoformat(),
                'end_at':
                    self.end_at.isoformat(),
            },
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_400_BAD_REQUEST,
        )

    def test_invalid_dimension_is_400(self):
        self.client.force_authenticate(
            self.admin
        )

        params = self._params()
        params['dimension'] = 'producer'

        response = self.client.get(
            self.url,
            params,
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_400_BAD_REQUEST,
        )

    def test_invalid_window_is_400(self):
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
                'dimension':
                    'platform',
            },
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_400_BAD_REQUEST,
        )

    def test_post_not_allowed(self):
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

    def test_events_stays_viewer_accessible(
        self,
    ):
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
