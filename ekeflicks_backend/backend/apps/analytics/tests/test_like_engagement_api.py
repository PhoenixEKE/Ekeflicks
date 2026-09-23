from datetime import (
    datetime,
    timezone,
)
from types import SimpleNamespace
from unittest.mock import patch

from django.test import (
    SimpleTestCase,
)
from django.urls import (
    resolve,
    reverse,
)

from rest_framework.test import (
    APIRequestFactory,
    force_authenticate,
)

from apps.analytics.serializers import (
    LikeEngagementQuerySerializer,
)
from apps.analytics.views import (
    EngagementAnalyticsViewSet,
)


class LikeEngagementQuerySerializerTests(
    SimpleTestCase
):
    def setUp(self):
        self.valid = {
            'start_at':
                '2026-09-01T00:00:00Z',

            'end_at':
                '2026-09-10T00:00:00Z',
        }

    def test_valid_query(self):
        serializer = (
            LikeEngagementQuerySerializer(
                data=self.valid,
            )
        )

        self.assertTrue(
            serializer.is_valid(),
            serializer.errors,
        )

        self.assertEqual(
            serializer.validated_data[
                'start_at'
            ],
            datetime(
                2026,
                9,
                1,
                tzinfo=timezone.utc,
            ),
        )

        self.assertEqual(
            serializer.validated_data[
                'end_at'
            ],
            datetime(
                2026,
                9,
                10,
                tzinfo=timezone.utc,
            ),
        )

    def test_start_at_is_required(self):
        data = dict(
            self.valid
        )

        data.pop(
            'start_at'
        )

        serializer = (
            LikeEngagementQuerySerializer(
                data=data,
            )
        )

        self.assertFalse(
            serializer.is_valid()
        )

        self.assertIn(
            'start_at',
            serializer.errors,
        )

    def test_end_at_is_required(self):
        data = dict(
            self.valid
        )

        data.pop(
            'end_at'
        )

        serializer = (
            LikeEngagementQuerySerializer(
                data=data,
            )
        )

        self.assertFalse(
            serializer.is_valid()
        )

        self.assertIn(
            'end_at',
            serializer.errors,
        )

    def test_rejects_end_before_start(self):
        data = {
            'start_at':
                '2026-09-10T00:00:00Z',

            'end_at':
                '2026-09-01T00:00:00Z',
        }

        serializer = (
            LikeEngagementQuerySerializer(
                data=data,
            )
        )

        self.assertFalse(
            serializer.is_valid()
        )

        self.assertIn(
            'end_at',
            serializer.errors,
        )

    def test_rejects_equal_window(self):
        data = {
            'start_at':
                '2026-09-10T00:00:00Z',

            'end_at':
                '2026-09-10T00:00:00Z',
        }

        serializer = (
            LikeEngagementQuerySerializer(
                data=data,
            )
        )

        self.assertFalse(
            serializer.is_valid()
        )

        self.assertIn(
            'end_at',
            serializer.errors,
        )


class EngagementAnalyticsAPITests(
    SimpleTestCase
):
    def setUp(self):
        self.factory = (
            APIRequestFactory()
        )

        self.admin = SimpleNamespace(
            pk=(
                '00000000-0000-0000-'
                '0000-000000000001'
            ),
            is_authenticated=True,
            is_staff=True,
        )

        self.non_admin = SimpleNamespace(
            pk=(
                '00000000-0000-0000-'
                '0000-000000000002'
            ),
            is_authenticated=True,
            is_staff=False,
        )

        self.params = {
            'start_at':
                '2026-09-01T00:00:00Z',

            'end_at':
                '2026-09-10T00:00:00Z',
        }

    def _view(self):
        return (
            EngagementAnalyticsViewSet
            .as_view(
                {
                    'get': 'list',
                }
            )
        )

    def test_router_resolves(self):
        url = reverse(
            'engagement-analytics-list'
        )

        self.assertEqual(
            url,
            '/api/v1/engagement-analytics/',
        )

        match = resolve(
            url
        )

        self.assertEqual(
            match.url_name,
            'engagement-analytics-list',
        )

    def test_non_admin_is_forbidden(self):
        request = self.factory.get(
            '/api/v1/engagement-analytics/',
            data=self.params,
        )

        force_authenticate(
            request,
            user=self.non_admin,
        )

        response = self._view()(
            request
        )

        self.assertEqual(
            response.status_code,
            403,
        )

    def test_missing_window_is_400(self):
        request = self.factory.get(
            '/api/v1/engagement-analytics/'
        )

        force_authenticate(
            request,
            user=self.admin,
        )

        response = self._view()(
            request
        )

        self.assertEqual(
            response.status_code,
            400,
        )

    def test_invalid_window_is_400(self):
        request = self.factory.get(
            '/api/v1/engagement-analytics/',
            data={
                'start_at':
                    '2026-09-10T00:00:00Z',

                'end_at':
                    '2026-09-01T00:00:00Z',
            },
        )

        force_authenticate(
            request,
            user=self.admin,
        )

        response = self._view()(
            request
        )

        self.assertEqual(
            response.status_code,
            400,
        )

    @patch(
        'apps.analytics.services.'
        'like_engagement_analytics'
    )
    def test_admin_api_returns_engine_metrics(
        self,
        engine,
    ):
        engine.return_value = {
            'start_at':
                '2026-09-01T00:00:00+00:00',

            'end_at':
                '2026-09-10T00:00:00+00:00',

            'likes':
                10,

            'unlikes':
                3,

            'net_likes':
                7,

            'unique_likers':
                6,

            'unique_viewers':
                20,

            'engagement_rate_percent':
                30.0,

            'current_likes':
                14,
        }

        request = self.factory.get(
            '/api/v1/engagement-analytics/',
            data=self.params,
        )

        force_authenticate(
            request,
            user=self.admin,
        )

        response = self._view()(
            request
        )

        self.assertEqual(
            response.status_code,
            200,
        )

        self.assertEqual(
            response.data['scope'],
            'global',
        )

        self.assertEqual(
            response.data['permissions'],
            'admin',
        )

        self.assertEqual(
            response.data['likes'],
            10,
        )

        self.assertEqual(
            response.data['unlikes'],
            3,
        )

        self.assertEqual(
            response.data['net_likes'],
            7,
        )

        self.assertEqual(
            response.data['unique_likers'],
            6,
        )

        self.assertEqual(
            response.data['unique_viewers'],
            20,
        )

        self.assertEqual(
            response.data[
                'engagement_rate_percent'
            ],
            30.0,
        )

        self.assertEqual(
            response.data['current_likes'],
            14,
        )

        engine.assert_called_once()

        args = (
            engine.call_args.args
        )

        self.assertEqual(
            args[0],
            datetime(
                2026,
                9,
                1,
                tzinfo=timezone.utc,
            ),
        )

        self.assertEqual(
            args[1],
            datetime(
                2026,
                9,
                10,
                tzinfo=timezone.utc,
            ),
        )

    @patch(
        'apps.analytics.services.'
        'like_engagement_analytics'
    )
    def test_favorite_is_not_part_of_api_contract(
        self,
        engine,
    ):
        engine.return_value = {
            'start_at':
                '2026-09-01T00:00:00+00:00',

            'end_at':
                '2026-09-10T00:00:00+00:00',

            'likes':
                0,

            'unlikes':
                0,

            'net_likes':
                0,

            'unique_likers':
                0,

            'unique_viewers':
                0,

            'engagement_rate_percent':
                0.0,

            'current_likes':
                0,
        }

        request = self.factory.get(
            '/api/v1/engagement-analytics/',
            data=self.params,
        )

        force_authenticate(
            request,
            user=self.admin,
        )

        response = self._view()(
            request
        )

        self.assertEqual(
            response.status_code,
            200,
        )

        self.assertNotIn(
            'favorites',
            response.data,
        )

        self.assertNotIn(
            'favorite',
            response.data,
        )
