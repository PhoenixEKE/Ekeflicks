from datetime import timedelta

from django.test import TestCase
from django.utils import timezone

from apps.catalog.experience_services import (
    recommended_queryset,
    top_10_queryset,
)
from core.models import Content
from core.models.recommendations import (
    Top10Entry,
    Top10Snapshot,
)


class PublicTop10ServiceTests(TestCase):
    def _content(
        self,
        title,
        *,
        submission='approved',
        available_from=None,
        available_until=None,
        views=0,
    ):
        return Content.objects.create(
            title=title,
            type='movie',
            producer_submission_status=submission,
            available_from=available_from,
            available_until=available_until,
            view_count=views,
        )

    def _snapshot(self):
        end = timezone.now()

        return Top10Snapshot.objects.create(
            window_start=(
                end - timedelta(days=7)
            ),
            window_end=end,
            scope=Top10Snapshot.SCOPE_GLOBAL,
            algorithm_version=(
                Top10Snapshot.ALGORITHM_V1
            ),
            is_published=True,
        )

    def _entry(
        self,
        snapshot,
        content,
        position,
    ):
        return Top10Entry.objects.create(
            snapshot=snapshot,
            content=content,
            position=position,
            qualified_views=10,
            watch_seconds=100,
            unique_viewers=5,
            completed_views=2,
            qualification_rate_percent='50.00',
            movement='new',
        )

    def test_no_snapshot_returns_empty_top10(self):
        self._content(
            'Approved',
            views=999,
        )

        self._content(
            'Draft',
            submission='draft',
            views=1000,
        )

        result = list(
            top_10_queryset()
        )

        self.assertEqual(
            result,
            [],
        )

    def test_snapshot_filters_future_content(self):
        from datetime import timedelta

        from django.utils import timezone

        from core.models.recommendations import (
            Top10Entry,
            Top10Snapshot,
        )

        today = timezone.localdate()

        future = self._content(
            'Future',
            available_from=today + timedelta(days=1),
            views=999,
        )

        valid = self._content(
            'Valid',
            available_from=today,
            views=1,
        )

        now = timezone.now()

        snapshot = Top10Snapshot.objects.create(
            window_start=now - timedelta(days=7),
            window_end=now,
            scope=Top10Snapshot.SCOPE_GLOBAL,
            algorithm_version=Top10Snapshot.ALGORITHM_V1,
            is_published=True,
        )

        Top10Entry.objects.create(
            snapshot=snapshot,
            content=future,
            position=1,
            qualified_views=100,
            watch_seconds=1000,
            unique_viewers=50,
            completed_views=20,
            qualification_rate_percent=50,
            movement=Top10Entry.MOVEMENT_NEW,
        )

        Top10Entry.objects.create(
            snapshot=snapshot,
            content=valid,
            position=2,
            qualified_views=10,
            watch_seconds=100,
            unique_viewers=5,
            completed_views=2,
            qualification_rate_percent=50,
            movement=Top10Entry.MOVEMENT_NEW,
        )

        result = list(
            top_10_queryset()
        )

        self.assertEqual(
            [item.id for item in result],
            [valid.id],
        )

    def test_snapshot_filters_expired_content(self):
        from datetime import timedelta

        from django.utils import timezone

        from core.models.recommendations import (
            Top10Entry,
            Top10Snapshot,
        )

        today = timezone.localdate()

        expired = self._content(
            'Expired',
            available_until=today - timedelta(days=1),
            views=999,
        )

        valid = self._content(
            'Valid',
            available_until=today,
            views=1,
        )

        now = timezone.now()

        snapshot = Top10Snapshot.objects.create(
            window_start=now - timedelta(days=7),
            window_end=now,
            scope=Top10Snapshot.SCOPE_GLOBAL,
            algorithm_version=Top10Snapshot.ALGORITHM_V1,
            is_published=True,
        )

        Top10Entry.objects.create(
            snapshot=snapshot,
            content=expired,
            position=1,
            qualified_views=100,
            watch_seconds=1000,
            unique_viewers=50,
            completed_views=20,
            qualification_rate_percent=50,
            movement=Top10Entry.MOVEMENT_NEW,
        )

        Top10Entry.objects.create(
            snapshot=snapshot,
            content=valid,
            position=2,
            qualified_views=10,
            watch_seconds=100,
            unique_viewers=5,
            completed_views=2,
            qualification_rate_percent=50,
            movement=Top10Entry.MOVEMENT_NEW,
        )

        result = list(
            top_10_queryset()
        )

        self.assertEqual(
            [item.id for item in result],
            [valid.id],
        )

    def test_empty_snapshot_is_authoritative(self):
        self._content(
            'Legacy approved',
            views=999,
        )

        self._snapshot()

        self.assertEqual(
            list(top_10_queryset()),
            [],
        )

    def test_snapshot_position_is_authoritative(self):
        first = self._content(
            'First',
            views=1,
        )

        second = self._content(
            'Second',
            views=999,
        )

        snapshot = self._snapshot()

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

        result = list(
            top_10_queryset()
        )

        self.assertEqual(
            [item.id for item in result],
            [
                first.id,
                second.id,
            ],
        )

    def test_latest_published_snapshot_wins(self):
        first = self._content('First')
        second = self._content('Second')

        old = self._snapshot()
        self._entry(old, first, 1)

        # Ensure deterministic generated_at ordering.
        Top10Snapshot.objects.filter(
            pk=old.pk
        ).update(
            generated_at=(
                timezone.now()
                - timedelta(hours=1)
            )
        )

        new = self._snapshot()
        self._entry(new, second, 1)

        result = list(
            top_10_queryset()
        )

        self.assertEqual(
            [item.id for item in result],
            [second.id],
        )

    def test_snapshot_still_enforces_public_eligibility(self):
        today = timezone.localdate()

        approved = self._content(
            'Approved'
        )

        pending = self._content(
            'Pending',
            submission='pending',
        )

        expired = self._content(
            'Expired',
            available_until=(
                today - timedelta(days=1)
            ),
        )

        snapshot = self._snapshot()

        self._entry(
            snapshot,
            pending,
            1,
        )

        self._entry(
            snapshot,
            approved,
            2,
        )

        self._entry(
            snapshot,
            expired,
            3,
        )

        result = list(
            top_10_queryset()
        )

        self.assertEqual(
            [item.id for item in result],
            [approved.id],
        )

    def test_recommended_without_profile_uses_strict_top10(self):
        self._content(
            'Approved',
            views=999,
        )

        result = list(
            recommended_queryset(None)
        )

        self.assertEqual(
            result,
            [],
        )
