from datetime import (
    datetime,
    timezone,
)
from unittest.mock import (
    Mock,
    patch,
)

from django.test import (
    SimpleTestCase,
)

from apps.analytics.services import (
    like_engagement_analytics,
)


class LikeEngagementAnalyticsTests(
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

    def _client(
        self,
        rows=None,
    ):
        client = Mock()

        result = Mock()
        result.result_rows = (
            rows
            if rows is not None
            else []
        )

        client.query.return_value = result

        return client

    @patch(
        'core.models.Like.objects.count',
        return_value=7,
    )
    def test_result_contract(
        self,
        like_count,
    ):
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
            like_engagement_analytics(
                self.start,
                self.end,
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

        like_count.assert_called_once()

    @patch(
        'core.models.Like.objects.count',
        return_value=0,
    )
    def test_zero_viewers_returns_zero_rate(
        self,
        like_count,
    ):
        result = (
            like_engagement_analytics(
                self.start,
                self.end,
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
        'core.models.Like.objects.count',
        return_value=0,
    )
    def test_net_likes_can_be_negative(
        self,
        like_count,
    ):
        result = (
            like_engagement_analytics(
                self.start,
                self.end,
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
        'core.models.Like.objects.count',
        return_value=0,
    )
    def test_empty_clickhouse_result(
        self,
        like_count,
    ):
        result = (
            like_engagement_analytics(
                self.start,
                self.end,
                client=self._client(
                    rows=[],
                ),
            )
        )

        self.assertEqual(
            result['likes'],
            0,
        )
        self.assertEqual(
            result['unlikes'],
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
            result['net_likes'],
            0,
        )
        self.assertEqual(
            result[
                'engagement_rate_percent'
            ],
            0.0,
        )

    def test_rejects_invalid_window(
        self,
    ):
        with self.assertRaisesRegex(
            ValueError,
            'start_at must be before end_at',
        ):
            like_engagement_analytics(
                self.end,
                self.start,
                client=self._client(),
            )

    @patch(
        'core.models.Like.objects.count',
        return_value=0,
    )
    def test_half_open_window(
        self,
        like_count,
    ):
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

        like_engagement_analytics(
            self.start,
            self.end,
            client=client,
        )

        query = (
            client.query.call_args.args[0]
        )

        params = (
            client.query
            .call_args
            .kwargs['parameters']
        )

        self.assertIn(
            'occurred_at >=',
            query,
        )
        self.assertIn(
            'occurred_at <',
            query,
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
        'core.models.Like.objects.count',
        return_value=0,
    )
    def test_like_activity_contract(
        self,
        like_count,
    ):
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

        like_engagement_analytics(
            self.start,
            self.end,
            client=client,
        )

        query = (
            client.query.call_args.args[0]
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
        self.assertIn(
            'is_internal = 0',
            query,
        )
        self.assertIn(
            'is_test = 0',
            query,
        )

        self.assertNotIn(
            'favorite',
            query.lower(),
        )

    @patch(
        'core.models.Like.objects.count',
        return_value=0,
    )
    def test_reuses_d4_qualification_contract(
        self,
        like_count,
    ):
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

        like_engagement_analytics(
            self.start,
            self.end,
            client=client,
        )

        query = (
            client.query.call_args.args[0]
        )

        for name in (
            'video_start',
            'video_progress',
            'video_complete',
            'video_abandon',
        ):
            self.assertIn(
                name,
                query,
            )

        self.assertIn(
            'sum(watch_seconds)',
            query,
        )

        self.assertIn(
            'duration_seconds < 300',
            query,
        )

        self.assertIn(
            'duration_seconds * 0.10',
            query,
        )

        self.assertIn(
            '30',
            query,
        )

        self.assertIn(
            'uniqExact(profile_id)',
            query,
        )
