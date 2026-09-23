from datetime import timedelta
from unittest.mock import MagicMock, patch
from uuid import uuid4

from django.test import TestCase
from django.utils import timezone

from apps.analytics.services import (
    TOP10_PUBLISH_ADVISORY_LOCK_KEY,
    _acquire_global_top10_publish_lock,
    publish_global_top10,
    top10_content_ranking,
    top10_eligible_content_ids,
)
from core.models import Content
from core.models.recommendations import (
    Top10Entry,
    Top10Snapshot,
)


class Top10PublicationTests(TestCase):
    def setUp(self):
        self.end = timezone.now()

    def _content(
        self,
        title,
        *,
        status='approved',
        available_from=None,
        available_until=None,
    ):
        return Content.objects.create(
            title=title,
            type='movie',
            producer_submission_status=status,
            available_from=available_from,
            available_until=available_until,
        )

    def _row(
        self,
        content,
        *,
        qualified=10,
        watch=100,
        viewers=5,
        completed=2,
        rate=50.0,
    ):
        return {
            'dimension': 'content',
            'value': str(content.id),
            'rank': 1,
            'events': 10,
            'play_starts': 10,
            'qualified_views': qualified,
            'unique_viewers': viewers,
            'watch_seconds': watch,
            'completed_views': completed,
            'qualification_rate_percent': rate,
            'completion_percent_avg': 60.0,
        }

    def test_eligible_ids_are_postgresql_authoritative(self):
        today = timezone.localdate()

        approved = self._content(
            'Approved',
        )

        self._content(
            'Pending',
            status='pending',
        )

        self._content(
            'Future',
            available_from=(
                today + timedelta(days=1)
            ),
        )

        self._content(
            'Expired',
            available_until=(
                today - timedelta(days=1)
            ),
        )

        ids = top10_eligible_content_ids(
            today
        )

        self.assertEqual(
            ids,
            [approved.id],
        )

    @patch(
        'apps.analytics.services.'
        'top10_content_ranking'
    )
    @patch(
        'apps.analytics.services.'
        '_acquire_global_top10_publish_lock'
    )
    def test_publisher_ranks_only_eligible_ids(
        self,
        lock,
        ranking,
    ):
        approved = self._content(
            'Approved',
        )

        self._content(
            'Pending',
            status='pending',
        )

        ranking.return_value = [
            self._row(approved)
        ]

        snapshot = publish_global_top10(
            end_at=self.end,
        )

        lock.assert_called_once_with()

        ranking.assert_called_once()

        args = ranking.call_args.args
        kwargs = ranking.call_args.kwargs

        self.assertEqual(
            args[0],
            self.end - timedelta(days=7),
        )

        self.assertEqual(
            args[1],
            self.end,
        )

        self.assertEqual(
            kwargs['eligible_content_ids'],
            [approved.id],
        )

        self.assertEqual(
            kwargs['limit'],
            10,
        )

        self.assertEqual(
            snapshot.entries.count(),
            1,
        )

    @patch(
        'apps.analytics.services.'
        'top10_content_ranking'
    )
    @patch(
        'apps.analytics.services.'
        '_acquire_global_top10_publish_lock'
    )
    def test_more_than_100_ineligible_cannot_hide_eligible(
        self,
        lock,
        ranking,
    ):
        for index in range(105):
            self._content(
                f'Pending {index}',
                status='pending',
            )

        eligible = self._content(
            'Eligible after 105 ineligible',
        )

        ranking.return_value = [
            self._row(
                eligible,
                qualified=1,
            )
        ]

        snapshot = publish_global_top10(
            end_at=self.end,
        )

        eligible_ids = (
            ranking.call_args.kwargs[
                'eligible_content_ids'
            ]
        )

        self.assertEqual(
            eligible_ids,
            [eligible.id],
        )

        self.assertEqual(
            list(
                snapshot.entries.values_list(
                    'content_id',
                    flat=True,
                )
            ),
            [eligible.id],
        )

    @patch(
        'apps.analytics.services.'
        'top10_content_ranking'
    )
    @patch(
        'apps.analytics.services.'
        '_acquire_global_top10_publish_lock'
    )
    def test_no_eligible_content_skips_clickhouse_and_publishes_empty(
        self,
        lock,
        ranking,
    ):
        self._content(
            'Pending',
            status='pending',
        )

        snapshot = publish_global_top10(
            end_at=self.end,
        )

        lock.assert_called_once_with()
        ranking.assert_not_called()

        self.assertTrue(
            snapshot.is_published
        )

        self.assertEqual(
            snapshot.entries.count(),
            0,
        )

    @patch(
        'apps.analytics.services.'
        'top10_content_ranking'
    )
    @patch(
        'apps.analytics.services.'
        '_acquire_global_top10_publish_lock'
    )
    def test_empty_analytics_publishes_empty_snapshot(
        self,
        lock,
        ranking,
    ):
        self._content(
            'Approved',
        )

        ranking.return_value = []

        snapshot = publish_global_top10(
            end_at=self.end,
        )

        self.assertTrue(
            snapshot.is_published
        )

        self.assertEqual(
            snapshot.entries.count(),
            0,
        )

    @patch(
        'apps.analytics.services.'
        'top10_content_ranking'
    )
    @patch(
        'apps.analytics.services.'
        '_acquire_global_top10_publish_lock'
    )
    def test_limits_product_top10_to_ten(
        self,
        lock,
        ranking,
    ):
        contents = [
            self._content(
                f'Content {index}'
            )
            for index in range(12)
        ]

        ranking.return_value = [
            self._row(
                content,
                qualified=100 - index,
            )
            for index, content
            in enumerate(contents[:10])
        ]

        snapshot = publish_global_top10(
            end_at=self.end,
        )

        self.assertEqual(
            snapshot.entries.count(),
            10,
        )

        self.assertEqual(
            list(
                snapshot.entries
                .order_by('position')
                .values_list(
                    'position',
                    flat=True,
                )
            ),
            list(range(1, 11)),
        )

        self.assertEqual(
            ranking.call_args.kwargs[
                'limit'
            ],
            10,
        )

    @patch(
        'apps.analytics.services.'
        'top10_content_ranking'
    )
    @patch(
        'apps.analytics.services.'
        '_acquire_global_top10_publish_lock'
    )
    def test_tracks_movements(
        self,
        lock,
        ranking,
    ):
        first = self._content('First')
        second = self._content('Second')
        newcomer = self._content('New')

        ranking.return_value = [
            self._row(first),
            self._row(second),
        ]

        publish_global_top10(
            end_at=(
                self.end
                - timedelta(hours=1)
            ),
        )

        ranking.return_value = [
            self._row(second),
            self._row(first),
            self._row(newcomer),
        ]

        current = publish_global_top10(
            end_at=self.end,
        )

        entries = {
            entry.content_id: entry
            for entry
            in current.entries.all()
        }

        self.assertEqual(
            entries[second.id].previous_position,
            2,
        )
        self.assertEqual(
            entries[second.id].position,
            1,
        )
        self.assertEqual(
            entries[second.id].position_change,
            1,
        )
        self.assertEqual(
            entries[second.id].movement,
            Top10Entry.MOVEMENT_UP,
        )

        self.assertEqual(
            entries[first.id].previous_position,
            1,
        )
        self.assertEqual(
            entries[first.id].position,
            2,
        )
        self.assertEqual(
            entries[first.id].position_change,
            -1,
        )
        self.assertEqual(
            entries[first.id].movement,
            Top10Entry.MOVEMENT_DOWN,
        )

        self.assertIsNone(
            entries[
                newcomer.id
            ].previous_position
        )
        self.assertIsNone(
            entries[
                newcomer.id
            ].position_change
        )
        self.assertEqual(
            entries[newcomer.id].movement,
            Top10Entry.MOVEMENT_NEW,
        )

    @patch(
        'apps.analytics.services.'
        'top10_content_ranking'
    )
    @patch(
        'apps.analytics.services.'
        '_acquire_global_top10_publish_lock'
    )
    def test_unchanged_position(
        self,
        lock,
        ranking,
    ):
        content = self._content(
            'Stable'
        )

        ranking.return_value = [
            self._row(content)
        ]

        publish_global_top10(
            end_at=(
                self.end
                - timedelta(hours=1)
            ),
        )

        current = publish_global_top10(
            end_at=self.end,
        )

        entry = current.entries.get()

        self.assertEqual(
            entry.previous_position,
            1,
        )

        self.assertEqual(
            entry.position_change,
            0,
        )

        self.assertEqual(
            entry.movement,
            Top10Entry.MOVEMENT_UNCHANGED,
        )

    @patch(
        'apps.analytics.services.'
        'top10_content_ranking'
    )
    @patch(
        'apps.analytics.services.'
        '_acquire_global_top10_publish_lock'
    )
    def test_exact_seven_day_window(
        self,
        lock,
        ranking,
    ):
        content = self._content(
            'Window'
        )

        ranking.return_value = [
            self._row(content)
        ]

        snapshot = publish_global_top10(
            end_at=self.end,
        )

        self.assertEqual(
            snapshot.window_end,
            self.end,
        )

        self.assertEqual(
            snapshot.window_start,
            self.end - timedelta(days=7),
        )

    @patch(
        'apps.analytics.services.'
        'top10_content_ranking'
    )
    @patch(
        'apps.analytics.services.'
        '_acquire_global_top10_publish_lock'
    )
    def test_transaction_rolls_back_on_entry_failure(
        self,
        lock,
        ranking,
    ):
        content = self._content(
            'Rollback'
        )

        ranking.return_value = [
            self._row(content)
        ]

        before = (
            Top10Snapshot.objects.count()
        )

        with patch(
            'core.models.recommendations.'
            'Top10Entry.objects.bulk_create',
            side_effect=RuntimeError(
                'forced failure'
            ),
        ):
            with self.assertRaises(
                RuntimeError
            ):
                publish_global_top10(
                    end_at=self.end,
                )

        self.assertEqual(
            Top10Snapshot.objects.count(),
            before,
        )

    def test_advisory_lock_key_is_deterministic_bigint_safe(self):
        self.assertEqual(
            TOP10_PUBLISH_ADVISORY_LOCK_KEY,
            int(
                '454B45544F503130',
                16,
            ),
        )

        self.assertLessEqual(
            TOP10_PUBLISH_ADVISORY_LOCK_KEY,
            9223372036854775807,
        )

    @patch(
        'django.db.backends.utils.CursorWrapper.execute'
    )
    def test_advisory_lock_uses_pg_transaction_lock(
        self,
        execute,
    ):
        _acquire_global_top10_publish_lock()

        sql = execute.call_args.args[0]
        params = execute.call_args.args[1]

        self.assertIn(
            'pg_advisory_xact_lock',
            sql,
        )

        self.assertEqual(
            params,
            [
                TOP10_PUBLISH_ADVISORY_LOCK_KEY
            ],
        )


class Top10ContentRankingTests(TestCase):
    def setUp(self):
        self.start = (
            timezone.now()
            - timedelta(days=7)
        )

        self.end = timezone.now()

    def test_empty_eligible_ids_do_not_query_clickhouse(self):
        client = MagicMock()

        rows = top10_content_ranking(
            self.start,
            self.end,
            eligible_content_ids=[],
            client=client,
        )

        self.assertEqual(
            rows,
            [],
        )

        client.query.assert_not_called()

    def test_query_filters_eligible_ids_before_order_and_limit(self):
        client = MagicMock()

        result = MagicMock()
        result.result_rows = []

        client.query.return_value = result

        first = uuid4()
        second = uuid4()

        top10_content_ranking(
            self.start,
            self.end,
            eligible_content_ids=[
                first,
                second,
            ],
            limit=10,
            client=client,
        )

        query = (
            client.query.call_args.args[0]
        )

        params = (
            client.query.call_args.kwargs[
                'parameters'
            ]
        )

        self.assertIn(
            'content_id IN',
            query,
        )

        self.assertIn(
            '{eligible_content_ids:Array(String)}',
            query,
        )

        self.assertLess(
            query.index(
                'content_id IN'
            ),
            query.index(
                'ORDER BY'
            ),
        )

        self.assertLess(
            query.index(
                'ORDER BY'
            ),
            query.index(
                'LIMIT'
            ),
        )

        self.assertEqual(
            params[
                'eligible_content_ids'
            ],
            [
                str(first),
                str(second),
            ]
        )

        self.assertEqual(
            params['limit'],
            10,
        )

    def test_query_keeps_exact_d4_ranking_order(self):
        client = MagicMock()

        result = MagicMock()
        result.result_rows = []

        client.query.return_value = result

        top10_content_ranking(
            self.start,
            self.end,
            eligible_content_ids=[
                uuid4()
            ],
            client=client,
        )

        query = (
            client.query.call_args.args[0]
        )

        expected = [
            'qualified_views DESC',
            'watch_seconds DESC',
            'unique_viewers DESC',
            'completed_views DESC',
            'qualification_rate_percent DESC',
            'content_id ASC',
        ]

        positions = [
            query.index(item)
            for item in expected
        ]

        self.assertEqual(
            positions,
            sorted(positions),
        )

    def test_query_keeps_exact_d4_qualification_threshold(self):
        client = MagicMock()

        result = MagicMock()
        result.result_rows = []

        client.query.return_value = result

        top10_content_ranking(
            self.start,
            self.end,
            eligible_content_ids=[
                uuid4()
            ],
            client=client,
        )

        query = (
            client.query.call_args.args[0]
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
            'session_duration_seconds',
            query,
        )

        self.assertIn(
            '* 0.10',
            query,
        )

    def test_maps_clickhouse_row(self):
        client = MagicMock()

        content_id = uuid4()

        result = MagicMock()

        result.result_rows = [
            (
                content_id,
                12,
                4,
                3,
                2,
                90,
                1,
                75.0,
                60.0,
            )
        ]

        client.query.return_value = result

        rows = top10_content_ranking(
            self.start,
            self.end,
            eligible_content_ids=[
                content_id
            ],
            client=client,
        )

        self.assertEqual(
            len(rows),
            1,
        )

        self.assertEqual(
            rows[0]['value'],
            str(content_id),
        )

        self.assertEqual(
            rows[0]['rank'],
            1,
        )

        self.assertEqual(
            rows[0]['qualified_views'],
            3,
        )

        self.assertEqual(
            rows[0]['watch_seconds'],
            90,
        )

        self.assertEqual(
            rows[0]['unique_viewers'],
            2,
        )

        self.assertEqual(
            rows[0]['completed_views'],
            1,
        )
