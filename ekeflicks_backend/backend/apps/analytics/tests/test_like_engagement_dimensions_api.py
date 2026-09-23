from datetime import (
    datetime,
    timezone,
)
from types import SimpleNamespace
from unittest.mock import patch

from django.test import SimpleTestCase
from django.urls import (
    resolve,
    reverse,
)

from rest_framework.test import (
    APIRequestFactory,
    force_authenticate,
)

from apps.analytics.serializers import (
    LIKE_ENGAGEMENT_DIMENSION_CHOICES,
    LikeEngagementDimensionQuerySerializer,
)
from apps.analytics.views import (
    EngagementAnalyticsViewSet,
)


class LikeEngagementDimensionQuerySerializerTests(
    SimpleTestCase
):
    def setUp(self):
        self.valid = {
            'start_at':
                '2026-09-01T00:00:00Z',

            'end_at':
                '2026-09-10T00:00:00Z',

            'dimension':
                'genre',
        }

    def test_supported_dimensions_exact(self):
        self.assertEqual(
            LIKE_ENGAGEMENT_DIMENSION_CHOICES,
            (
                'content',
                'producer',
                'content_type',
                'genre',
                'country_code',
                'profile_type',
            ),
        )

    def test_valid_query_default_limit(self):
        serializer = (
            LikeEngagementDimensionQuerySerializer(
                data=self.valid,
            )
        )

        self.assertTrue(
            serializer.is_valid(),
            serializer.errors,
        )

        self.assertEqual(
            serializer.validated_data[
                'limit'
            ],
            100,
        )

    def test_accepts_all_supported_dimensions(self):
        for dimension in (
            LIKE_ENGAGEMENT_DIMENSION_CHOICES
        ):
            serializer = (
                LikeEngagementDimensionQuerySerializer(
                    data={
                        **self.valid,
                        'dimension':
                            dimension,
                    },
                )
            )

            self.assertTrue(
                serializer.is_valid(),
                serializer.errors,
            )

    def test_rejects_platform_and_device_type(self):
        for dimension in (
            'platform',
            'device_type',
        ):
            serializer = (
                LikeEngagementDimensionQuerySerializer(
                    data={
                        **self.valid,
                        'dimension':
                            dimension,
                    },
                )
            )

            self.assertFalse(
                serializer.is_valid()
            )

            self.assertIn(
                'dimension',
                serializer.errors,
            )

    def test_rejects_invalid_window(self):
        serializer = (
            LikeEngagementDimensionQuerySerializer(
                data={
                    **self.valid,
                    'start_at':
                        '2026-09-10T00:00:00Z',
                    'end_at':
                        '2026-09-01T00:00:00Z',
                },
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
        serializer = (
            LikeEngagementDimensionQuerySerializer(
                data={
                    **self.valid,
                    'start_at':
                        '2026-09-10T00:00:00Z',
                    'end_at':
                        '2026-09-10T00:00:00Z',
                },
            )
        )

        self.assertFalse(
            serializer.is_valid()
        )

        self.assertIn(
            'end_at',
            serializer.errors,
        )

    def test_limit_bounds(self):
        for value in (
            1,
            1000,
        ):
            serializer = (
                LikeEngagementDimensionQuerySerializer(
                    data={
                        **self.valid,
                        'limit':
                            value,
                    },
                )
            )

            self.assertTrue(
                serializer.is_valid(),
                serializer.errors,
            )

        for value in (
            0,
            1001,
        ):
            serializer = (
                LikeEngagementDimensionQuerySerializer(
                    data={
                        **self.valid,
                        'limit':
                            value,
                    },
                )
            )

            self.assertFalse(
                serializer.is_valid()
            )

            self.assertIn(
                'limit',
                serializer.errors,
            )

    def test_required_fields(self):
        for field in (
            'start_at',
            'end_at',
            'dimension',
        ):
            data = dict(
                self.valid
            )

            data.pop(
                field
            )

            serializer = (
                LikeEngagementDimensionQuerySerializer(
                    data=data,
                )
            )

            self.assertFalse(
                serializer.is_valid()
            )

            self.assertIn(
                field,
                serializer.errors,
            )


class EngagementDimensionsAPITests(
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

            'dimension':
                'genre',

            'limit':
                10,
        }

    def _view(self):
        return (
            EngagementAnalyticsViewSet
            .as_view(
                {
                    'get':
                        'dimensions',
                }
            )
        )

    def test_route_resolves(self):
        url = reverse(
            'engagement-analytics-dimensions'
        )

        self.assertEqual(
            url,
            (
                '/api/v1/'
                'engagement-analytics/'
                'dimensions/'
            ),
        )

        match = resolve(
            url
        )

        self.assertEqual(
            match.url_name,
            'engagement-analytics-dimensions',
        )

    def test_non_admin_forbidden(self):
        request = self.factory.get(
            (
                '/api/v1/'
                'engagement-analytics/'
                'dimensions/'
            ),
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

    def test_missing_dimension_400(self):
        params = dict(
            self.params
        )

        params.pop(
            'dimension'
        )

        request = self.factory.get(
            (
                '/api/v1/'
                'engagement-analytics/'
                'dimensions/'
            ),
            data=params,
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

    def test_forbidden_dimensions_400(self):
        for dimension in (
            'platform',
            'device_type',
        ):
            request = self.factory.get(
                (
                    '/api/v1/'
                    'engagement-analytics/'
                    'dimensions/'
                ),
                data={
                    **self.params,
                    'dimension':
                        dimension,
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

    def test_invalid_limit_400(self):
        request = self.factory.get(
            (
                '/api/v1/'
                'engagement-analytics/'
                'dimensions/'
            ),
            data={
                **self.params,
                'limit':
                    1001,
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
        'like_engagement_dimension_analytics'
    )
    def test_admin_calls_engine(
        self,
        engine,
    ):
        engine.return_value = [
            {
                'dimension':
                    'genre',
                'dimension_value':
                    'Drama',
                'likes':
                    8,
                'unlikes':
                    2,
                'net_likes':
                    6,
                'unique_likers':
                    7,
                'unique_viewers':
                    4,
                'engagement_rate_percent':
                    175.0,
            },
        ]

        request = self.factory.get(
            (
                '/api/v1/'
                'engagement-analytics/'
                'dimensions/'
            ),
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
            response.data['dimension'],
            'genre',
        )

        self.assertEqual(
            response.data['limit'],
            10,
        )

        self.assertEqual(
            response.data['results'],
            engine.return_value,
        )

        self.assertNotIn(
            'current_likes',
            response.data,
        )

        engine.assert_called_once_with(
            datetime(
                2026,
                9,
                1,
                tzinfo=timezone.utc,
            ),
            datetime(
                2026,
                9,
                10,
                tzinfo=timezone.utc,
            ),
            dimension='genre',
            limit=10,
        )

    @patch(
        'apps.analytics.services.'
        'like_engagement_dimension_analytics'
    )
    def test_default_limit_forwarded(
        self,
        engine,
    ):
        engine.return_value = []

        params = dict(
            self.params
        )

        params.pop(
            'limit'
        )

        request = self.factory.get(
            (
                '/api/v1/'
                'engagement-analytics/'
                'dimensions/'
            ),
            data=params,
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
            response.data['limit'],
            100,
        )

        self.assertEqual(
            engine.call_args.kwargs[
                'limit'
            ],
            100,
        )
