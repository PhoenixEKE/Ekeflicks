from datetime import timedelta
from types import SimpleNamespace
from unittest.mock import (
    MagicMock,
    patch,
)

from django.core.cache import cache
from django.test import (
    SimpleTestCase,
    override_settings,
)
from django.utils import timezone

from apps.analytics.tasks import (
    publish_global_top10_daily,
)


@override_settings(
    CACHES={
        'default': {
            'BACKEND': (
                'django.core.cache.backends.locmem.'
                'LocMemCache'
            ),
        },
    },
)
class Top10PublicationTaskTests(
    SimpleTestCase
):
    def setUp(self):
        cache.clear()

    @patch(
        'apps.analytics.services.'
        'publish_global_top10'
    )
    def test_task_publishes_top10(
        self,
        publish_mock,
    ):
        end_at = timezone.now()

        entries = MagicMock()
        entries.count.return_value = 4

        snapshot = SimpleNamespace(
            id='11111111-1111-1111-1111-111111111111',
            scope='global',
            algorithm_version='d4_7d_v1',
            entries=entries,
            window_start=(
                end_at - timedelta(days=7)
            ),
            window_end=end_at,
        )

        publish_mock.return_value = (
            snapshot
        )

        result = (
            publish_global_top10_daily.run()
        )

        self.assertTrue(
            result['published']
        )

        self.assertEqual(
            result['status'],
            'published',
        )

        self.assertEqual(
            result['entries'],
            4,
        )

        self.assertEqual(
            result['scope'],
            'global',
        )

        publish_mock.assert_called_once()

        kwargs = (
            publish_mock.call_args.kwargs
        )

        self.assertEqual(
            kwargs['window_days'],
            7,
        )

        self.assertIn(
            'end_at',
            kwargs,
        )

    @patch(
        'apps.analytics.services.'
        'publish_global_top10'
    )
    def test_task_skips_when_lock_exists(
        self,
        publish_mock,
    ):
        lock_key = (
            'analytics:top10:global:publication'
        )

        cache.set(
            lock_key,
            '1',
            timeout=60,
        )

        result = (
            publish_global_top10_daily.run()
        )

        self.assertEqual(
            result,
            {
                'status': 'locked',
                'published': False,
            },
        )

        publish_mock.assert_not_called()

    @patch(
        'apps.analytics.services.'
        'publish_global_top10'
    )
    def test_lock_is_released_after_success(
        self,
        publish_mock,
    ):
        now = timezone.now()

        entries = MagicMock()
        entries.count.return_value = 0

        publish_mock.return_value = (
            SimpleNamespace(
                id=(
                    '22222222-2222-2222-'
                    '2222-222222222222'
                ),
                scope='global',
                algorithm_version=(
                    'd4_7d_v1'
                ),
                entries=entries,
                window_start=(
                    now
                    - timedelta(days=7)
                ),
                window_end=now,
            )
        )

        publish_global_top10_daily.run()

        self.assertIsNone(
            cache.get(
                'analytics:top10:global:publication'
            )
        )
