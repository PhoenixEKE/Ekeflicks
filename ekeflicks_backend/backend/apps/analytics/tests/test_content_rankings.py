from datetime import (
    datetime,
    timezone,
)
from unittest.mock import (
    Mock,
    patch,
)

from django.test import SimpleTestCase

from apps.analytics.services import (
    CONTENT_ANALYTICS_RANKING_ORDER,
    content_dimension_analytics,
    content_dimension_ranking,
)


class ContentAnalyticsRankingTests(
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

    def test_ranking_order_contract(self):
        self.assertEqual(
            CONTENT_ANALYTICS_RANKING_ORDER,
            (
                'qualified_views',
                'watch_seconds',
                'unique_viewers',
                'completed_views',
                'qualification_rate_percent',
            ),
        )

    def test_underlying_sql_order_is_deterministic(self):
        client = self._client()

        content_dimension_analytics(
            self.start,
            self.end,
            dimension='content',
            client=client,
        )

        query = (
            client.query.call_args.args[0]
        )

        expected = (
            'ORDER BY\n'
            '            qualified_views DESC,\n'
            '            watch_seconds DESC,\n'
            '            unique_viewers DESC,\n'
            '            completed_views DESC,\n'
            '            qualification_rate_percent DESC,\n'
            '            dimension_value ASC'
        )

        self.assertIn(
            expected,
            query,
        )

    def test_ranking_uses_existing_dimension_engine(self):
        rows = [
            {
                'dimension': 'content',
                'value': 'content-a',
                'events': 12,
                'play_starts': 5,
                'qualified_views': 4,
                'unique_viewers': 3,
                'watch_seconds': 900,
                'completed_views': 2,
                'qualification_rate_percent': 80.0,
                'completion_percent_avg': 72.0,
            },
            {
                'dimension': 'content',
                'value': 'content-b',
                'events': 10,
                'play_starts': 4,
                'qualified_views': 3,
                'unique_viewers': 2,
                'watch_seconds': 650,
                'completed_views': 1,
                'qualification_rate_percent': 75.0,
                'completion_percent_avg': 61.0,
            },
        ]

        with patch(
            'apps.analytics.services.'
            'content_dimension_analytics',
            return_value=rows,
        ) as engine:
            result = content_dimension_ranking(
                self.start,
                self.end,
                dimension='content',
                limit=10,
            )

        engine.assert_called_once_with(
            self.start,
            self.end,
            dimension='content',
            limit=10,
            client=None,
        )

        self.assertEqual(
            result[0]['rank'],
            1,
        )

        self.assertEqual(
            result[0]['value'],
            'content-a',
        )

        self.assertEqual(
            result[1]['rank'],
            2,
        )

        self.assertEqual(
            result[1]['value'],
            'content-b',
        )

    def test_ranking_does_not_mutate_engine_rows(self):
        source = [
            {
                'dimension': 'genre',
                'value': 'Action',
                'events': 5,
                'play_starts': 2,
                'qualified_views': 2,
                'unique_viewers': 2,
                'watch_seconds': 300,
                'completed_views': 1,
                'qualification_rate_percent': 100.0,
                'completion_percent_avg': 80.0,
            },
        ]

        original = dict(
            source[0]
        )

        with patch(
            'apps.analytics.services.'
            'content_dimension_analytics',
            return_value=source,
        ):
            result = content_dimension_ranking(
                self.start,
                self.end,
                dimension='genre',
            )

        self.assertEqual(
            source[0],
            original,
        )

        self.assertNotIn(
            'rank',
            source[0],
        )

        self.assertEqual(
            result[0]['rank'],
            1,
        )

    def test_empty_ranking(self):
        with patch(
            'apps.analytics.services.'
            'content_dimension_analytics',
            return_value=[],
        ):
            result = content_dimension_ranking(
                self.start,
                self.end,
                dimension='producer',
            )

        self.assertEqual(
            result,
            [],
        )

    def test_default_limit_is_ten(self):
        with patch(
            'apps.analytics.services.'
            'content_dimension_analytics',
            return_value=[],
        ) as engine:
            content_dimension_ranking(
                self.start,
                self.end,
                dimension='content_type',
            )

        self.assertEqual(
            engine.call_args.kwargs['limit'],
            10,
        )

    def test_limit_is_forwarded(self):
        with patch(
            'apps.analytics.services.'
            'content_dimension_analytics',
            return_value=[],
        ) as engine:
            content_dimension_ranking(
                self.start,
                self.end,
                dimension='genre',
                limit=25,
            )

        self.assertEqual(
            engine.call_args.kwargs['limit'],
            25,
        )

    def test_rejects_non_integer_limit(self):
        with self.assertRaisesRegex(
            ValueError,
            'limit must be an integer',
        ):
            content_dimension_ranking(
                self.start,
                self.end,
                dimension='content',
                limit='abc',
            )

    def test_rejects_zero_limit(self):
        with self.assertRaisesRegex(
            ValueError,
            'ranking limit must be between 1 and 100',
        ):
            content_dimension_ranking(
                self.start,
                self.end,
                dimension='content',
                limit=0,
            )

    def test_rejects_limit_above_100(self):
        with self.assertRaisesRegex(
            ValueError,
            'ranking limit must be between 1 and 100',
        ):
            content_dimension_ranking(
                self.start,
                self.end,
                dimension='content',
                limit=101,
            )

    def test_all_dimensions_are_supported(self):
        for dimension in (
            'content',
            'producer',
            'content_type',
            'genre',
        ):
            with self.subTest(
                dimension=dimension,
            ):
                with patch(
                    'apps.analytics.services.'
                    'content_dimension_analytics',
                    return_value=[],
                ) as engine:
                    content_dimension_ranking(
                        self.start,
                        self.end,
                        dimension=dimension,
                    )

                self.assertEqual(
                    engine.call_args.kwargs[
                        'dimension'
                    ],
                    dimension,
                )

    def test_unknown_dimension_is_delegated_to_engine(self):
        client = self._client()

        with self.assertRaisesRegex(
            ValueError,
            'dimension must be one of',
        ):
            content_dimension_ranking(
                self.start,
                self.end,
                dimension='country',
                client=client,
            )

    def test_real_result_shape_keeps_metrics_and_adds_rank(self):
        client = self._client(
            rows=[
                (
                    'movie',
                    20,
                    8,
                    6,
                    5,
                    1800,
                    4,
                    75.0,
                    81.25,
                ),
            ]
        )

        result = content_dimension_ranking(
            self.start,
            self.end,
            dimension='content_type',
            client=client,
        )

        self.assertEqual(
            result,
            [
                {
                    'dimension':
                        'content_type',

                    'value':
                        'movie',

                    'events':
                        20,

                    'play_starts':
                        8,

                    'qualified_views':
                        6,

                    'unique_viewers':
                        5,

                    'watch_seconds':
                        1800,

                    'completed_views':
                        4,

                    'qualification_rate_percent':
                        75.0,

                    'completion_percent_avg':
                        81.25,

                    'rank':
                        1,
                },
            ],
        )
