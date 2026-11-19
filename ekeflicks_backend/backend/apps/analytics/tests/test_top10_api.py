from datetime import timedelta

from django.contrib.auth import get_user_model
from django.test import TestCase
from django.urls import reverse
from django.utils import timezone
from rest_framework.test import APIClient

from core.models import Content
from core.models.recommendations import (
    Top10Entry,
    Top10Snapshot,
)


User = get_user_model()


class Top10AnalyticsAPITests(TestCase):
    def setUp(self):
        self.client = APIClient()

        self.admin = User.objects.create_user(
            email='top10-admin@example.com',
            password='StrongPass123',
            is_staff=True,
        )

        self.user = User.objects.create_user(
            email='top10-user@example.com',
            password='StrongPass123',
        )

        self.end = timezone.now()
        self.start = (
            self.end
            - timedelta(days=7)
        )

    def _snapshot(
        self,
        *,
        published=True,
        end=None,
    ):
        if end is None:
            end = self.end

        return Top10Snapshot.objects.create(
            window_start=(
                end - timedelta(days=7)
            ),
            window_end=end,
            scope=Top10Snapshot.SCOPE_GLOBAL,
            algorithm_version=(
                Top10Snapshot.ALGORITHM_V1
            ),
            is_published=published,
        )

    def _content(
        self,
        title,
    ):
        return Content.objects.create(
            title=title,
            type='movie',
            producer_submission_status='approved',
        )

    def _entry(
        self,
        snapshot,
        content,
        position,
        *,
        movement='new',
        previous_position=None,
        position_change=None,
    ):
        return Top10Entry.objects.create(
            snapshot=snapshot,
            content=content,
            position=position,
            qualified_views=10,
            watch_seconds=120,
            unique_viewers=5,
            completed_views=3,
            qualification_rate_percent='50.00',
            previous_position=previous_position,
            position_change=position_change,
            movement=movement,
        )

    def test_requires_admin(self):
        self.client.force_authenticate(
            user=self.user
        )

        response = self.client.get(
            reverse(
                'top10-analytics-current'
            )
        )

        self.assertEqual(
            response.status_code,
            403,
        )

    def test_current_empty(self):
        self.client.force_authenticate(
            user=self.admin
        )

        response = self.client.get(
            reverse(
                'top10-analytics-current'
            )
        )

        self.assertEqual(
            response.status_code,
            200,
        )

        self.assertIsNone(
            response.data['snapshot']
        )

        self.assertEqual(
            response.data['count'],
            0,
        )

        self.assertEqual(
            response.data['entries'],
            [],
        )

    def test_current_returns_latest_published_snapshot(
        self,
    ):
        older = self._snapshot(
            end=(
                self.end
                - timedelta(days=1)
            )
        )

        newer = self._snapshot(
            end=self.end
        )

        old_content = self._content(
            'Old'
        )

        new_content = self._content(
            'New'
        )

        self._entry(
            older,
            old_content,
            1,
        )

        self._entry(
            newer,
            new_content,
            1,
        )

        self.client.force_authenticate(
            user=self.admin
        )

        response = self.client.get(
            reverse(
                'top10-analytics-current'
            )
        )

        self.assertEqual(
            response.status_code,
            200,
        )

        self.assertEqual(
            response.data[
                'snapshot'
            ]['id'],
            str(newer.id),
        )

        self.assertEqual(
            response.data['count'],
            1,
        )

        self.assertEqual(
            response.data[
                'entries'
            ][0]['content_id'],
            str(new_content.id),
        )

    def test_current_excludes_unpublished_snapshot(
        self,
    ):
        published = self._snapshot(
            end=(
                self.end
                - timedelta(hours=1)
            )
        )

        unpublished = self._snapshot(
            published=False,
            end=self.end,
        )

        published_content = self._content(
            'Published'
        )

        unpublished_content = self._content(
            'Unpublished'
        )

        self._entry(
            published,
            published_content,
            1,
        )

        self._entry(
            unpublished,
            unpublished_content,
            1,
        )

        self.client.force_authenticate(
            user=self.admin
        )

        response = self.client.get(
            reverse(
                'top10-analytics-current'
            )
        )

        self.assertEqual(
            response.data[
                'snapshot'
            ]['id'],
            str(published.id),
        )

    def test_current_entries_are_position_ordered(
        self,
    ):
        snapshot = self._snapshot()

        first = self._content('First')
        second = self._content('Second')

        self._entry(
            snapshot,
            second,
            2,
        )

        self._entry(
            snapshot,
            first,
            1,
        )

        self.client.force_authenticate(
            user=self.admin
        )

        response = self.client.get(
            reverse(
                'top10-analytics-current'
            )
        )

        self.assertEqual(
            [
                item['position']
                for item
                in response.data['entries']
            ],
            [1, 2],
        )

    def test_current_exposes_movement_and_metrics(
        self,
    ):
        snapshot = self._snapshot()
        content = self._content(
            'Movement'
        )

        self._entry(
            snapshot,
            content,
            1,
            movement='up',
            previous_position=3,
            position_change=2,
        )

        self.client.force_authenticate(
            user=self.admin
        )

        response = self.client.get(
            reverse(
                'top10-analytics-current'
            )
        )

        entry = response.data[
            'entries'
        ][0]

        self.assertEqual(
            entry['movement'],
            'up',
        )

        self.assertEqual(
            entry['previous_position'],
            3,
        )

        self.assertEqual(
            entry['position_change'],
            2,
        )

        self.assertEqual(
            entry['qualified_views'],
            10,
        )

        self.assertEqual(
            entry['watch_seconds'],
            120,
        )

    def test_history_returns_newest_first(
        self,
    ):
        older = self._snapshot(
            end=(
                self.end
                - timedelta(days=2)
            )
        )

        newer = self._snapshot(
            end=self.end
        )

        self.client.force_authenticate(
            user=self.admin
        )

        response = self.client.get(
            reverse(
                'top10-analytics-history'
            )
        )

        self.assertEqual(
            response.status_code,
            200,
        )

        ids = [
            item['id']
            for item
            in response.data['results']
        ]

        self.assertEqual(
            ids,
            [
                str(newer.id),
                str(older.id),
            ],
        )

    def test_history_limit(self):
        for offset in range(3):
            self._snapshot(
                end=(
                    self.end
                    - timedelta(hours=offset)
                )
            )

        self.client.force_authenticate(
            user=self.admin
        )

        response = self.client.get(
            reverse(
                'top10-analytics-history'
            ),
            {
                'limit': 2,
            },
        )

        self.assertEqual(
            response.status_code,
            200,
        )

        self.assertEqual(
            response.data['limit'],
            2,
        )

        self.assertEqual(
            response.data['count'],
            2,
        )

    def test_history_rejects_invalid_limit(self):
        self.client.force_authenticate(
            user=self.admin
        )

        for value in (
            'abc',
            '0',
            '101',
        ):
            response = self.client.get(
                reverse(
                    'top10-analytics-history'
                ),
                {
                    'limit': value,
                },
            )

            self.assertEqual(
                response.status_code,
                400,
            )

    def test_list_contract(self):
        self.client.force_authenticate(
            user=self.admin
        )

        response = self.client.get(
            reverse(
                'top10-analytics-list'
            )
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
            response.data['source'],
            'postgresql',
        )

        self.assertEqual(
            response.data[
                'window_days'
            ],
            7,
        )

        self.assertEqual(
            response.data[
                'algorithm_version'
            ],
            'd4_7d_v1',
        )
