from datetime import (
    datetime,
    timezone,
)
from unittest.mock import patch

from django.urls import reverse
from rest_framework.test import APITestCase

from core.models import Content, User

from apps.analytics.tests.test_producer_analytics_api import (
    ProducerAnalyticsAPITests,
)


class ProducerAnalyticsKPIAPITests(
    ProducerAnalyticsAPITests
):
    def setUp(self):
        super().setUp()

        self.url = reverse(
            'producer-analytics-list'
        )

        self.start = (
            datetime(
                2026,
                9,
                1,
                tzinfo=timezone.utc,
            )
        )

        self.end = (
            datetime(
                2026,
                9,
                10,
                tzinfo=timezone.utc,
            )
        )

    def _window(self):
        return {
            'start_at':
                self.start.isoformat(),

            'end_at':
                self.end.isoformat(),
        }

    def test_rejects_client_producer_id(self):
        self.client.force_authenticate(
            self.producer
        )

        response = self.client.get(
            self.url,
            {
                **self._window(),
                'producer_id':
                    str(
                        self.other_producer.id
                    ),
            },
        )

        self.assertEqual(
            response.status_code,
            400,
        )

        self.assertIn(
            'producer_id',
            response.data,
        )

    def test_rejects_client_producer(self):
        self.client.force_authenticate(
            self.producer
        )

        response = self.client.get(
            self.url,
            {
                **self._window(),
                'producer':
                    str(
                        self.other_producer.id
                    ),
            },
        )

        self.assertEqual(
            response.status_code,
            400,
        )

    @patch(
        'apps.analytics.services.'
        'producer_content_video_analytics'
    )
    def test_empty_scope_does_not_call_kpi_engine(
        self,
        analytics_mock,
    ):
        producer_without_content = (
            self._active_producer(
                email='empty-kpi@example.com'
            )
        )

        self.client.force_authenticate(
            producer_without_content
        )

        response = self.client.get(
            self.url,
            self._window(),
        )

        self.assertEqual(
            response.status_code,
            200,
        )

        self.assertEqual(
            response.data[
                'results'
            ],
            [],
        )

        analytics_mock.assert_not_called()

    @patch(
        'apps.analytics.services.'
        'producer_content_video_analytics'
    )
    def test_api_passes_only_own_content_ids(
        self,
        analytics_mock,
    ):
        analytics_mock.return_value = []

        self.client.force_authenticate(
            self.producer
        )

        response = self.client.get(
            self.url,
            self._window(),
        )

        self.assertEqual(
            response.status_code,
            200,
        )

        kwargs = (
            analytics_mock
            .call_args
            .kwargs
        )

        allowed = {
            str(value)
            for value
            in kwargs[
                'allowed_content_ids'
            ]
        }

        own = {
            str(value)
            for value
            in Content.objects.filter(
                producer=self.producer
            ).values_list(
                'id',
                flat=True,
            )
        }

        foreign = {
            str(value)
            for value
            in Content.objects.filter(
                producer=
                    self.other_producer
            ).values_list(
                'id',
                flat=True,
            )
        }

        self.assertEqual(
            allowed,
            own,
        )

        self.assertTrue(
            allowed.isdisjoint(
                foreign
            )
        )

    @patch(
        'apps.analytics.services.'
        'producer_content_video_analytics'
    )
    def test_results_are_enriched_from_postgresql(
        self,
        analytics_mock,
    ):
        own_content = (
            Content.objects.filter(
                producer=self.producer
            ).first()
        )

        analytics_mock.return_value = [
            {
                'dimension':
                    'content',

                'value':
                    str(
                        own_content.id
                    ),

                'events':
                    12,

                'play_starts':
                    5,

                'qualified_views':
                    4,

                'unique_viewers':
                    3,

                'watch_seconds':
                    900,

                'completed_views':
                    2,

                'qualification_rate_percent':
                    80.0,

                'completion_percent_avg':
                    75.0,
            }
        ]

        self.client.force_authenticate(
            self.producer
        )

        response = self.client.get(
            self.url,
            self._window(),
        )

        self.assertEqual(
            response.status_code,
            200,
        )

        self.assertEqual(
            response.data[
                'result_count'
            ],
            1,
        )

        item = response.data[
            'results'
        ][0]

        self.assertEqual(
            item[
                'content_id'
            ],
            str(
                own_content.id
            ),
        )

        self.assertEqual(
            item[
                'title'
            ],
            own_content.title,
        )

        self.assertEqual(
            item[
                'type'
            ],
            own_content.type,
        )

        self.assertNotIn(
            'dimension',
            item,
        )

        self.assertNotIn(
            'value',
            item,
        )

    @patch(
        'apps.analytics.services.'
        'producer_content_video_analytics'
    )
    def test_foreign_row_is_dropped_even_if_engine_returns_it(
        self,
        analytics_mock,
    ):
        foreign_content = (
            Content.objects.filter(
                producer=
                    self.other_producer
            ).first()
        )

        analytics_mock.return_value = [
            {
                'dimension':
                    'content',

                'value':
                    str(
                        foreign_content.id
                    ),

                'events':
                    100,

                'play_starts':
                    50,

                'qualified_views':
                    50,

                'unique_viewers':
                    40,

                'watch_seconds':
                    10000,

                'completed_views':
                    25,

                'qualification_rate_percent':
                    100.0,

                'completion_percent_avg':
                    100.0,
            }
        ]

        self.client.force_authenticate(
            self.producer
        )

        response = self.client.get(
            self.url,
            self._window(),
        )

        self.assertEqual(
            response.status_code,
            200,
        )

        self.assertEqual(
            response.data[
                'results'
            ],
            [],
        )

    def test_invalid_window_is_400(self):
        self.client.force_authenticate(
            self.producer
        )

        response = self.client.get(
            self.url,
            {
                'start_at':
                    self.end.isoformat(),

                'end_at':
                    self.start.isoformat(),
            },
        )

        self.assertEqual(
            response.status_code,
            400,
        )

    def test_invalid_limit_is_400(self):
        self.client.force_authenticate(
            self.producer
        )

        response = self.client.get(
            self.url,
            {
                **self._window(),
                'limit':
                    '1001',
            },
        )

        self.assertEqual(
            response.status_code,
            400,
        )
