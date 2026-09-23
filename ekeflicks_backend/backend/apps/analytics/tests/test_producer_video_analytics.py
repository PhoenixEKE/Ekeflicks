from datetime import (
    datetime,
    timezone,
)
from unittest.mock import (
    Mock,
    patch,
)
import uuid

from django.test import SimpleTestCase

from apps.analytics.services import (
    producer_content_video_analytics,
)


class ProducerContentVideoAnalyticsTests(
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

        self.content_id = uuid.uuid4()

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

    def _query(self):
        client = self._client()

        producer_content_video_analytics(
            self.start,
            self.end,
            allowed_content_ids=[
                self.content_id,
            ],
            client=client,
        )

        return (
            client,
            client.query.call_args.args[0],
            client.query.call_args.kwargs[
                'parameters'
            ],
        )

    def test_empty_scope_never_opens_clickhouse(self):
        with patch(
            'apps.analytics.services.clickhouse_client'
        ) as clickhouse_client:
            rows = producer_content_video_analytics(
                self.start,
                self.end,
                allowed_content_ids=[],
            )

        self.assertEqual(
            rows,
            [],
        )

        clickhouse_client.assert_not_called()

    def test_content_scope_is_applied_inside_clickhouse(self):
        client, query, params = self._query()

        self.assertIn(
            'content_id IN arrayMap(',
            query,
        )

        self.assertIn(
            'x -> toUUID(x)',
            query,
        )

        self.assertIn(
            '{allowed_content_ids:Array(String)}',
            query,
        )

        self.assertEqual(
            params['allowed_content_ids'],
            [
                str(self.content_id),
            ],
        )

    def test_duplicate_content_ids_are_deduplicated(self):
        client = self._client()

        producer_content_video_analytics(
            self.start,
            self.end,
            allowed_content_ids=[
                self.content_id,
                str(self.content_id),
            ],
            client=client,
        )

        params = (
            client.query
            .call_args
            .kwargs['parameters']
        )

        self.assertEqual(
            params['allowed_content_ids'],
            [
                str(self.content_id),
            ],
        )

    def test_uses_only_video_lifecycle_events(self):
        _, query, _ = self._query()

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
            'is_internal = 0',
            query,
        )

        self.assertIn(
            'is_test = 0',
            query,
        )

    def test_requires_viewing_session(self):
        _, query, _ = self._query()

        self.assertIn(
            'viewing_session_id',
            query,
        )

        self.assertIn(
            'IS NOT NULL',
            query,
        )

    def test_groups_session_before_content(self):
        _, query, _ = self._query()

        self.assertIn(
            'GROUP BY\n'
            '                content_id,\n'
            '                viewing_session_id',
            query,
        )

    def test_watch_time_uses_strict_deltas(self):
        _, query, _ = self._query()

        self.assertIn(
            'sum(watch_seconds)',
            query,
        )

        self.assertIn(
            'AS session_watch_seconds',
            query,
        )

        self.assertNotIn(
            'position_seconds',
            query,
        )

    def test_reuses_exact_d4_qualification_threshold(self):
        _, query, _ = self._query()

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

    def test_completed_views_requires_complete_event(self):
        _, query, _ = self._query()

        self.assertIn(
            "event_name = 'video_complete'",
            query,
        )

        self.assertIn(
            'AS has_complete',
            query,
        )

        self.assertNotIn(
            'completion_percent = 100',
            query,
        )

    def test_unique_viewers_are_qualified_only(self):
        _, query, _ = self._query()

        self.assertIn(
            'uniqExactIf(',
            query,
        )

        self.assertIn(
            'is_qualified = 1',
            query,
        )

    def test_half_open_window_and_limit_parameters(self):
        client = self._client()

        producer_content_video_analytics(
            self.start,
            self.end,
            allowed_content_ids=[
                self.content_id,
            ],
            limit=25,
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

        self.assertRegex(
            query,
            (
                r'occurred_at\s*'
                r'>=\s*'
                r'\{start_at:DateTime64\(3\)\}'
            ),
        )

        self.assertRegex(
            query,
            (
                r'occurred_at\s*'
                r'<\s*'
                r'\{end_at:DateTime64\(3\)\}'
            ),
        )

        self.assertEqual(
            params['start_at'],
            self.start,
        )

        self.assertEqual(
            params['end_at'],
            self.end,
        )

        self.assertEqual(
            params['limit'],
            25,
        )

    def test_result_contract_matches_d4_kpis(self):
        client = self._client(
            rows=[
                (
                    str(self.content_id),
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

        rows = producer_content_video_analytics(
            self.start,
            self.end,
            allowed_content_ids=[
                self.content_id,
            ],
            client=client,
        )

        self.assertEqual(
            rows,
            [
                {
                    'dimension':
                        'content',

                    'value':
                        str(self.content_id),

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

    def test_invalid_window_rejected_before_query(self):
        client = self._client()

        with self.assertRaisesRegex(
            ValueError,
            'start_at must be before end_at',
        ):
            producer_content_video_analytics(
                self.end,
                self.start,
                allowed_content_ids=[
                    self.content_id,
                ],
                client=client,
            )

        client.query.assert_not_called()

    def test_invalid_limit_rejected(self):
        client = self._client()

        with self.assertRaisesRegex(
            ValueError,
            'limit must be between 1 and 1000',
        ):
            producer_content_video_analytics(
                self.start,
                self.end,
                allowed_content_ids=[
                    self.content_id,
                ],
                limit=1001,
                client=client,
            )

        client.query.assert_not_called()
