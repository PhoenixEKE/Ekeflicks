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
    ContentAnalyticsQuerySerializer,
)
from apps.analytics.services import (
    CONTENT_ANALYTICS_DIMENSIONS,
    CONTENT_ANALYTICS_RANKING_ORDER,
)
from apps.analytics.views import (
    ContentAnalyticsViewSet,
)


class ContentAnalyticsQuerySerializerTests(
    SimpleTestCase
):
    def setUp(self):
        self.valid = {
            'start_at':
                '2026-09-01T00:00:00Z',

            'end_at':
                '2026-09-10T00:00:00Z',

            'dimension':
                'content',

            'limit':
                25,
        }

    def test_valid_query(self):
        serializer = (
            ContentAnalyticsQuerySerializer(
                data=self.valid,
            )
        )

        self.assertTrue(
            serializer.is_valid(),
            serializer.errors,
        )

        self.assertEqual(
            serializer.validated_data[
                'dimension'
            ],
            'content',
        )

        self.assertEqual(
            serializer.validated_data[
                'limit'
            ],
            25,
        )

    def test_default_limit_is_ten(self):
        data = dict(
            self.valid
        )

        data.pop(
            'limit'
        )

        serializer = (
            ContentAnalyticsQuerySerializer(
                data=data,
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
            10,
        )

    def test_dimension_contract(self):
        self.assertEqual(
            set(
                CONTENT_ANALYTICS_DIMENSIONS
            ),
            {
                'content',
                'producer',
                'content_type',
                'genre',
            },
        )

        self.assertEqual(
            len(
                CONTENT_ANALYTICS_DIMENSIONS
            ),
            4,
        )

    def test_rejects_unknown_dimension(self):
        data = dict(
            self.valid
        )

        data['dimension'] = 'country'

        serializer = (
            ContentAnalyticsQuerySerializer(
                data=data,
            )
        )

        self.assertFalse(
            serializer.is_valid()
        )

        self.assertIn(
            'dimension',
            serializer.errors,
        )

    def test_rejects_end_before_start(self):
        data = dict(
            self.valid
        )

        data['start_at'] = (
            '2026-09-10T00:00:00Z'
        )

        data['end_at'] = (
            '2026-09-01T00:00:00Z'
        )

        serializer = (
            ContentAnalyticsQuerySerializer(
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
        data = dict(
            self.valid
        )

        data['start_at'] = (
            '2026-09-10T00:00:00Z'
        )

        data['end_at'] = (
            '2026-09-10T00:00:00Z'
        )

        serializer = (
            ContentAnalyticsQuerySerializer(
                data=data,
            )
        )

        self.assertFalse(
            serializer.is_valid()
        )

    def test_rejects_zero_limit(self):
        data = dict(
            self.valid
        )

        data['limit'] = 0

        serializer = (
            ContentAnalyticsQuerySerializer(
                data=data,
            )
        )

        self.assertFalse(
            serializer.is_valid()
        )

    def test_rejects_limit_above_100(self):
        data = dict(
            self.valid
        )

        data['limit'] = 101

        serializer = (
            ContentAnalyticsQuerySerializer(
                data=data,
            )
        )

        self.assertFalse(
            serializer.is_valid()
        )


class ContentAnalyticsAPITests(
    SimpleTestCase
):
    def setUp(self):
        self.factory = (
            APIRequestFactory()
        )

        self.admin = SimpleNamespace(
            pk='00000000-0000-0000-0000-000000000001',
            is_authenticated=True,
            is_staff=True,
        )

        self.non_admin = SimpleNamespace(
            pk='00000000-0000-0000-0000-000000000002',
            is_authenticated=True,
            is_staff=False,
        )

        self.params = {
            'start_at':
                '2026-09-01T00:00:00Z',

            'end_at':
                '2026-09-10T00:00:00Z',

            'dimension':
                'content',

            'limit':
                10,
        }

    def test_list_metadata_contract(self):
        request = self.factory.get(
            '/api/v1/content-analytics/'
        )

        force_authenticate(
            request,
            user=self.admin,
        )

        view = (
            ContentAnalyticsViewSet
            .as_view(
                {
                    'get': 'list',
                }
            )
        )

        response = view(
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
            response.data[
                'permissions'
            ],
            'admin',
        )

        self.assertEqual(
            response.data[
                'dimensions'
            ],
            list(
                CONTENT_ANALYTICS_DIMENSIONS
            ),
        )

        self.assertEqual(
            response.data[
                'ranking_order'
            ],
            list(
                CONTENT_ANALYTICS_RANKING_ORDER
            ),
        )

    def test_non_admin_is_forbidden(self):
        request = self.factory.get(
            '/api/v1/content-analytics/'
        )

        force_authenticate(
            request,
            user=self.non_admin,
        )

        view = (
            ContentAnalyticsViewSet
            .as_view(
                {
                    'get': 'list',
                }
            )
        )

        response = view(
            request
        )

        self.assertEqual(
            response.status_code,
            403,
        )

    @patch(
        'apps.analytics.views.'
        'content_dimension_analytics'
    )
    def test_dimensions_delegates_to_engine(
        self,
        engine,
    ):
        engine.return_value = [
            {
                'dimension':
                    'content',

                'value':
                    'abc',

                'qualified_views':
                    4,
            },
        ]

        request = self.factory.get(
            '/api/v1/content-analytics/'
            'dimensions/',
            data=self.params,
        )

        force_authenticate(
            request,
            user=self.admin,
        )

        view = (
            ContentAnalyticsViewSet
            .as_view(
                {
                    'get': 'dimensions',
                }
            )
        )

        response = view(
            request
        )

        self.assertEqual(
            response.status_code,
            200,
        )

        self.assertEqual(
            response.data[
                'dimension'
            ],
            'content',
        )

        self.assertEqual(
            response.data[
                'limit'
            ],
            10,
        )

        self.assertEqual(
            response.data[
                'results'
            ],
            engine.return_value,
        )

        engine.assert_called_once()

        args = (
            engine.call_args.args
        )

        kwargs = (
            engine.call_args.kwargs
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

        self.assertEqual(
            kwargs['dimension'],
            'content',
        )

        self.assertEqual(
            kwargs['limit'],
            10,
        )

    @patch(
        'apps.analytics.views.'
        'content_dimension_ranking'
    )
    def test_rankings_delegates_to_engine(
        self,
        engine,
    ):
        engine.return_value = [
            {
                'rank':
                    1,

                'dimension':
                    'genre',

                'value':
                    'Action',

                'qualified_views':
                    8,
            },
        ]

        params = dict(
            self.params
        )

        params['dimension'] = (
            'genre'
        )

        request = self.factory.get(
            '/api/v1/content-analytics/'
            'rankings/',
            data=params,
        )

        force_authenticate(
            request,
            user=self.admin,
        )

        view = (
            ContentAnalyticsViewSet
            .as_view(
                {
                    'get': 'rankings',
                }
            )
        )

        response = view(
            request
        )

        self.assertEqual(
            response.status_code,
            200,
        )

        self.assertEqual(
            response.data[
                'results'
            ],
            engine.return_value,
        )

        self.assertEqual(
            response.data[
                'ranking_order'
            ],
            list(
                CONTENT_ANALYTICS_RANKING_ORDER
            ),
        )

        engine.assert_called_once()

        self.assertEqual(
            engine.call_args.kwargs[
                'dimension'
            ],
            'genre',
        )

    def test_dimensions_bad_query_is_400(self):
        params = dict(
            self.params
        )

        params['dimension'] = (
            'country'
        )

        request = self.factory.get(
            '/api/v1/content-analytics/'
            'dimensions/',
            data=params,
        )

        force_authenticate(
            request,
            user=self.admin,
        )

        view = (
            ContentAnalyticsViewSet
            .as_view(
                {
                    'get': 'dimensions',
                }
            )
        )

        response = view(
            request
        )

        self.assertEqual(
            response.status_code,
            400,
        )

    def test_rankings_bad_window_is_400(self):
        params = dict(
            self.params
        )

        params['start_at'] = (
            '2026-09-10T00:00:00Z'
        )

        params['end_at'] = (
            '2026-09-01T00:00:00Z'
        )

        request = self.factory.get(
            '/api/v1/content-analytics/'
            'rankings/',
            data=params,
        )

        force_authenticate(
            request,
            user=self.admin,
        )

        view = (
            ContentAnalyticsViewSet
            .as_view(
                {
                    'get': 'rankings',
                }
            )
        )

        response = view(
            request
        )

        self.assertEqual(
            response.status_code,
            400,
        )

    def test_router_list_resolves(self):
        url = reverse(
            'content-analytics-list'
        )

        match = resolve(
            url
        )

        self.assertEqual(
            match.url_name,
            'content-analytics-list',
        )

    def test_router_dimensions_resolves(self):
        url = reverse(
            'content-analytics-dimensions'
        )

        match = resolve(
            url
        )

        self.assertEqual(
            match.url_name,
            'content-analytics-dimensions',
        )

    def test_router_rankings_resolves(self):
        url = reverse(
            'content-analytics-rankings'
        )

        match = resolve(
            url
        )

        self.assertEqual(
            match.url_name,
            'content-analytics-rankings',
        )
