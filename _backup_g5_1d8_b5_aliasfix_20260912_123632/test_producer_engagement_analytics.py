from datetime import (
    datetime,
    timezone,
)
from types import SimpleNamespace
from unittest.mock import (
    Mock,
    patch,
)
import uuid

from django.test import (
    SimpleTestCase,
)

from apps.analytics.services import (
    producer_engagement_analytics,
)


class ProducerEngagementAnalyticsTests(
    SimpleTestCase
):
    def setUp(self):
        self.start = datetime(
            2026,
            9,
            1,
            tzinfo=timezone.utc,
        )

        self.end = datetime(
            2026,
            9,
            10,
            tzinfo=timezone.utc,
        )

        self.content_id = (
            uuid.uuid4()
        )

        self.other_content_id = (
            uuid.uuid4()
        )

    def _client(
        self,
        rows=None,
    ):
        client = Mock()

        client.query.return_value = (
            SimpleNamespace(
                result_rows=(
                    rows
                    if rows is not None
                    else []
                ),
            )
        )

        return client

    @patch(
        'core.models.Like.objects.filter'
    )
    def test_result_contract(
        self,
        like_filter,
    ):
        like_filter.return_value.count.return_value = 7

        client = self._client(
            rows=[
                (
                    10,
                    3,
                    6,
                    20,
                ),
            ]
        )

        result = (
            producer_engagement_analytics(
                self.start,
                self.end,
                allowed_content_ids=[
                    self.content_id,
                ],
                client=client,
            )
        )

        self.assertEqual(
            result['likes'],
            10,
        )

        self.assertEqual(
            result['unlikes'],
            3,
        )

        self.assertEqual(
            result['net_likes'],
            7,
        )

        self.assertEqual(
            result['unique_likers'],
            6,
        )

        self.assertEqual(
            result['unique_viewers'],
            20,
        )

        self.assertEqual(
            result[
                'engagement_rate_percent'
            ],
            30.0,
        )

        self.assertEqual(
            result['current_likes'],
            7,
        )

        like_filter.assert_called_once_with(
            content_id__in=[
                str(
                    self.content_id
                ),
            ],
        )

    @patch(
        'apps.analytics.services.'
        'clickhouse_client'
    )
    @patch(
        'core.models.Like.objects.filter'
    )
    def test_empty_scope_never_opens_clickhouse(
        self,
        like_filter,
        clickhouse_factory,
    ):
        result = (
            producer_engagement_analytics(
                self.start,
                self.end,
                allowed_content_ids=[],
            )
        )

        clickhouse_factory.assert_not_called()
        like_filter.assert_not_called()

        self.assertEqual(
            result['likes'],
            0,
        )

        self.assertEqual(
            result['unlikes'],
            0,
        )

        self.assertEqual(
            result['net_likes'],
            0,
        )

        self.assertEqual(
            result['unique_likers'],
            0,
        )

        self.assertEqual(
            result['unique_viewers'],
            0,
        )

        self.assertEqual(
            result[
                'engagement_rate_percent'
            ],
            0.0,
        )

        self.assertEqual(
            result['current_likes'],
            0,
        )

    @patch(
        'core.models.Like.objects.filter'
    )
    def test_allowed_content_filter_is_inside_both_ch_populations(
        self,
        like_filter,
    ):
        like_filter.return_value.count.return_value = 0

        client = self._client(
            rows=[
                (
                    0,
                    0,
                    0,
                    0,
                ),
            ]
        )

        producer_engagement_analytics(
            self.start,
            self.end,
            allowed_content_ids=[
                self.content_id,
                self.other_content_id,
            ],
            client=client,
        )

        query = (
            client.query
            .call_args
            .args[0]
        )

        params = (
            client.query
            .call_args
            .kwargs[
                'parameters'
            ]
        )

        filter_contract = (
            'content_id IN arrayMap('
        )

        self.assertEqual(
            query.count(
                filter_contract
            ),
            2,
        )

        self.assertEqual(
            query.count(
                '{allowed_content_ids:Array(String)}'
            ),
            2,
        )

        self.assertEqual(
            set(
                params[
                    'allowed_content_ids'
                ]
            ),
            {
                str(
                    self.content_id
                ),
                str(
                    self.other_content_id
                ),
            },
        )

    @patch(
        'core.models.Like.objects.filter'
    )
    def test_reuses_d6_and_d4_contract(
        self,
        like_filter,
    ):
        like_filter.return_value.count.return_value = 0

        client = self._client(
            rows=[
                (
                    0,
                    0,
                    0,
                    0,
                ),
            ]
        )

        producer_engagement_analytics(
            self.start,
            self.end,
            allowed_content_ids=[
                self.content_id,
            ],
            client=client,
        )

        query = (
            client.query
            .call_args
            .args[0]
        )

        self.assertIn(
            "'content_like'",
            query,
        )

        self.assertIn(
            "'content_unlike'",
            query,
        )

        self.assertIn(
            'uniqExactIf',
            query,
        )

        self.assertNotIn(
            'favorite',
            query.lower(),
        )

        for event_name in (
            'video_start',
            'video_progress',
            'video_complete',
            'video_abandon',
        ):
            self.assertIn(
                event_name,
                query,
            )

        self.assertIn(
            'sum(watch_seconds)',
            query,
        )

        self.assertIn(
            'max(duration_seconds)',
            query,
        )

        self.assertIn(
            'least(',
            query,
        )

        self.assertIn(
            '30.0',
            query,
        )

        self.assertIn(
            '* 0.10',
            query,
        )

        self.assertGreaterEqual(
            query.count(
                'is_internal = 0'
            ),
            2,
        )

        self.assertGreaterEqual(
            query.count(
                'is_test = 0'
            ),
            2,
        )

    @patch(
        'core.models.Like.objects.filter'
    )
    def test_half_open_window(
        self,
        like_filter,
    ):
        like_filter.return_value.count.return_value = 0

        client = self._client(
            rows=[
                (
                    0,
                    0,
                    0,
                    0,
                ),
            ]
        )

        producer_engagement_analytics(
            self.start,
            self.end,
            allowed_content_ids=[
                self.content_id,
            ],
            client=client,
        )

        query = (
            client.query
            .call_args
            .args[0]
        )

        params = (
            client.query
            .call_args
            .kwargs[
                'parameters'
            ]
        )

        self.assertGreaterEqual(
            query.count(
                'occurred_at >='
            ),
            2,
        )

        self.assertGreaterEqual(
            query.count(
                'occurred_at <'
            ),
            2,
        )

        self.assertEqual(
            params['start_at'],
            self.start,
        )

        self.assertEqual(
            params['end_at'],
            self.end,
        )

    @patch(
        'core.models.Like.objects.filter'
    )
    def test_zero_viewers_returns_zero_rate(
        self,
        like_filter,
    ):
        like_filter.return_value.count.return_value = 0

        result = (
            producer_engagement_analytics(
                self.start,
                self.end,
                allowed_content_ids=[
                    self.content_id,
                ],
                client=self._client(
                    rows=[
                        (
                            4,
                            1,
                            3,
                            0,
                        ),
                    ]
                ),
            )
        )

        self.assertEqual(
            result[
                'engagement_rate_percent'
            ],
            0.0,
        )

    @patch(
        'core.models.Like.objects.filter'
    )
    def test_net_likes_can_be_negative(
        self,
        like_filter,
    ):
        like_filter.return_value.count.return_value = 0

        result = (
            producer_engagement_analytics(
                self.start,
                self.end,
                allowed_content_ids=[
                    self.content_id,
                ],
                client=self._client(
                    rows=[
                        (
                            2,
                            5,
                            2,
                            10,
                        ),
                    ]
                ),
            )
        )

        self.assertEqual(
            result['net_likes'],
            -3,
        )

    @patch(
        'core.models.Like.objects.filter'
    )
    def test_duplicate_allowed_ids_are_deduplicated(
        self,
        like_filter,
    ):
        like_filter.return_value.count.return_value = 0

        client = self._client(
            rows=[
                (
                    0,
                    0,
                    0,
                    0,
                ),
            ]
        )

        producer_engagement_analytics(
            self.start,
            self.end,
            allowed_content_ids=[
                self.content_id,
                str(
                    self.content_id
                ),
            ],
            client=client,
        )

        params = (
            client.query
            .call_args
            .kwargs[
                'parameters'
            ]
        )

        self.assertEqual(
            params[
                'allowed_content_ids'
            ],
            [
                str(
                    self.content_id
                ),
            ],
        )

    def test_invalid_window_rejected(
        self,
    ):
        with self.assertRaisesRegex(
            ValueError,
            'start_at must be before end_at',
        ):
            producer_engagement_analytics(
                self.end,
                self.start,
                allowed_content_ids=[
                    self.content_id,
                ],
                client=Mock(),
            )
