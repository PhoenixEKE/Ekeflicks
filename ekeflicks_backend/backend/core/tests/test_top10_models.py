from datetime import timedelta

from django.db import (
    IntegrityError,
    transaction,
)
from django.test import TestCase
from django.utils import timezone

from core.models import Content
from core.models.recommendations import (
    Top10Entry,
    Top10Snapshot,
)


class Top10PersistenceModelTests(TestCase):
    def setUp(self):
        self.end = timezone.now()
        self.start = self.end - timedelta(days=7)

        self.snapshot = Top10Snapshot.objects.create(
            window_start=self.start,
            window_end=self.end,
            scope=Top10Snapshot.SCOPE_GLOBAL,
            algorithm_version=(
                Top10Snapshot.ALGORITHM_V1
            ),
            is_published=True,
        )

        self.content = Content.objects.create(
            title='Top10 Test',
            type='movie',
            producer_submission_status='approved',
        )

    def test_snapshot_contract(self):
        self.assertEqual(
            self.snapshot.scope,
            'global',
        )

        self.assertEqual(
            self.snapshot.algorithm_version,
            'd4_7d_v1',
        )

        self.assertTrue(
            self.snapshot.is_published,
        )

    def test_entry_persists_frozen_metrics(self):
        entry = Top10Entry.objects.create(
            snapshot=self.snapshot,
            content=self.content,
            position=1,
            qualified_views=12,
            watch_seconds=950,
            unique_viewers=8,
            completed_views=5,
            qualification_rate_percent='75.50',
            previous_position=3,
            position_change=2,
            movement=Top10Entry.MOVEMENT_UP,
        )

        entry.refresh_from_db()

        self.assertEqual(entry.position, 1)
        self.assertEqual(entry.qualified_views, 12)
        self.assertEqual(entry.watch_seconds, 950)
        self.assertEqual(entry.unique_viewers, 8)
        self.assertEqual(entry.completed_views, 5)

        self.assertEqual(
            str(entry.qualification_rate_percent),
            '75.50',
        )

        self.assertEqual(
            entry.previous_position,
            3,
        )

        self.assertEqual(
            entry.position_change,
            2,
        )

        self.assertEqual(
            entry.movement,
            'up',
        )

    def test_same_position_cannot_repeat_in_snapshot(self):
        Top10Entry.objects.create(
            snapshot=self.snapshot,
            content=self.content,
            position=1,
        )

        other = Content.objects.create(
            title='Top10 Other',
            type='series',
            producer_submission_status='approved',
        )

        with self.assertRaises(
            IntegrityError
        ):
            with transaction.atomic():
                Top10Entry.objects.create(
                    snapshot=self.snapshot,
                    content=other,
                    position=1,
                )

    def test_same_content_cannot_repeat_in_snapshot(self):
        Top10Entry.objects.create(
            snapshot=self.snapshot,
            content=self.content,
            position=1,
        )

        with self.assertRaises(
            IntegrityError
        ):
            with transaction.atomic():
                Top10Entry.objects.create(
                    snapshot=self.snapshot,
                    content=self.content,
                    position=2,
                )

    def test_content_is_protected_from_deletion(self):
        Top10Entry.objects.create(
            snapshot=self.snapshot,
            content=self.content,
            position=1,
        )

        from django.db.models import ProtectedError

        with self.assertRaises(
            ProtectedError
        ):
            self.content.delete()

    def test_snapshot_delete_cascades_entries(self):
        Top10Entry.objects.create(
            snapshot=self.snapshot,
            content=self.content,
            position=1,
        )

        snapshot_id = self.snapshot.id

        self.snapshot.delete()

        self.assertFalse(
            Top10Entry.objects.filter(
                snapshot_id=snapshot_id,
            ).exists()
        )
