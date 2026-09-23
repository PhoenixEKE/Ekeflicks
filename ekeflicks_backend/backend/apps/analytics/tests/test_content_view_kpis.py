from datetime import (
    datetime,
    timezone,
)
from unittest.mock import Mock

from django.test import SimpleTestCase

from apps.analytics.services import (
    content_dimension_analytics,
)


class ContentViewKPIContractTests(
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

    def _query(
        self,
        dimension='content',
    ):
        client = self._client()

        content_dimension_analytics(
            self.start,
            self.end,
            dimension=dimension,
            client=client,
        )

        return (
            client.query.call_args.args[0]
        )

    def test_requires_viewing_session_id(self):
        query = self._query()

        self.assertIn(
            'viewing_session_id',
            query,
        )

        self.assertIn(
            'IS NOT NULL',
            query,
        )

    def test_session_is_grouped_before_dimension(self):
        query = self._query()

        self.assertIn(
            'GROUP BY\n'
            '                dimension_value,\n'
            '                viewing_session_id',
            query,
        )

    def test_play_start_is_session_based(self):
        query = self._query()

        self.assertIn(
            "event_name = 'video_start'",
            query,
        )

        self.assertIn(
            'AS has_start',
            query,
        )

        self.assertIn(
            'countIf(\n'
            '                has_start = 1',
            query,
        )

    def test_complete_is_session_based(self):
        query = self._query()

        self.assertIn(
            "event_name = 'video_complete'",
            query,
        )

        self.assertIn(
            'AS has_complete',
            query,
        )

        self.assertIn(
            'countIf(\n'
            '                has_complete = 1',
            query,
        )

    def test_watch_time_uses_sum_of_deltas(self):
        query = self._query()

        self.assertIn(
            'sum(watch_seconds)',
            query,
        )

        self.assertIn(
            'AS session_watch_seconds',
            query,
        )

    def test_position_is_not_used_for_qualification(self):
        query = self._query()

        self.assertNotIn(
            'position_seconds',
            query,
        )

    def test_known_duration_threshold_is_capped_at_30(self):
        query = self._query()

        self.assertIn(
            'least(',
            query,
        )

        self.assertIn(
            '30.0',
            query,
        )

        self.assertIn(
            'session_duration_seconds\n'
            '                            * 0.10',
            query,
        )

    def test_unknown_duration_threshold_is_30(self):
        query = self._query()

        self.assertIn(
            'session_duration_seconds > 0',
            query,
        )

        self.assertIn(
            '30.0',
            query,
        )

    def test_qualified_views_count_sessions(self):
        query = self._query()

        self.assertIn(
            'AS is_qualified',
            query,
        )

        self.assertIn(
            'countIf(\n'
            '                is_qualified = 1',
            query,
        )

    def test_unique_viewers_only_qualified(self):
        query = self._query()

        self.assertIn(
            'uniqExactIf(',
            query,
        )

        self.assertIn(
            'is_qualified = 1',
            query,
        )

    def test_qualification_rate(self):
        query = self._query()

        self.assertIn(
            'qualified_views\n'
            '                    * 100.0\n'
            '                    / play_starts',
            query,
        )

    def test_completion_uses_max_per_session(self):
        query = self._query()

        self.assertIn(
            'max(completion_percent)',
            query,
        )

        self.assertIn(
            'AS session_completion_percent',
            query,
        )

    def test_content_dimension_remains_supported(self):
        query = self._query(
            'content'
        )

        self.assertIn(
            'toString(content_id)',
            query,
        )

    def test_producer_dimension_remains_supported(self):
        query = self._query(
            'producer'
        )

        self.assertIn(
            'toString(producer_id)',
            query,
        )

    def test_content_type_dimension_remains_supported(self):
        query = self._query(
            'content_type'
        )

        self.assertIn(
            "content_type IN ('movie', 'series')",
            query,
        )

    def test_genre_dimension_remains_array_joined(self):
        query = self._query(
            'genre'
        )

        self.assertIn(
            'ARRAY JOIN genres AS genre',
            query,
        )

    def test_normalized_result_contract(self):
        client = self._client(
            rows=[
                (
                    'movie',
                    15,
                    5,
                    4,
                    3,
                    920,
                    2,
                    80.0,
                    76.349,
                ),
            ]
        )

        rows = content_dimension_analytics(
            self.start,
            self.end,
            dimension='content_type',
            client=client,
        )

        self.assertEqual(
            rows,
            [
                {
                    'dimension':
                        'content_type',

                    'value':
                        'movie',

                    'events':
                        15,

                    'play_starts':
                        5,

                    'qualified_views':
                        4,

                    'unique_viewers':
                        3,

                    'watch_seconds':
                        920,

                    'completed_views':
                        2,

                    'qualification_rate_percent':
                        80.0,

                    'completion_percent_avg':
                        76.35,
                },
            ],
        )
