from datetime import datetime, timedelta, timezone as dt_timezone
from unittest.mock import patch

from django.test import TestCase

from core.models import Content
from apps.catalog.tasks import (
    DRAFT_RETENTION_DAYS,
    purge_expired_producer_drafts,
)


class ProducerDraftAutomaticPurgeTests(TestCase):
    def setUp(self):
        self.now = datetime(
            2026,
            9,
            5,
            12,
            0,
            0,
            tzinfo=dt_timezone.utc,
        )

    def _create_content(
        self,
        *,
        title,
        status='draft',
        age_days=0,
        poster_temp_path='',
    ):
        content = Content.objects.create(
            title=title,
            type='movie',
            producer_submission_status=status,
            poster_temp_path=poster_temp_path,
        )

        updated_at = self.now - timedelta(days=age_days)

        Content.objects.filter(
            id=content.id,
        ).update(
            updated_at=updated_at,
        )

        content.refresh_from_db()
        return content

    @patch('apps.catalog.tasks.timezone.now')
    def test_draft_exactly_120_days_old_is_deleted(
        self,
        now_mock,
    ):
        now_mock.return_value = self.now

        content = self._create_content(
            title='Draft 120 Days',
            age_days=DRAFT_RETENTION_DAYS,
        )

        result = purge_expired_producer_drafts()

        self.assertFalse(
            Content.objects.filter(id=content.id).exists()
        )
        self.assertEqual(result['deleted'], 1)
        self.assertEqual(result['retention_days'], 120)

    @patch('apps.catalog.tasks.timezone.now')
    def test_draft_119_days_old_is_preserved(
        self,
        now_mock,
    ):
        now_mock.return_value = self.now

        content = self._create_content(
            title='Draft 119 Days',
            age_days=119,
        )

        result = purge_expired_producer_drafts()

        self.assertTrue(
            Content.objects.filter(id=content.id).exists()
        )
        self.assertEqual(result['deleted'], 0)

    @patch('apps.catalog.tasks.timezone.now')
    def test_recently_saved_draft_is_preserved(
        self,
        now_mock,
    ):
        now_mock.return_value = self.now

        content = self._create_content(
            title='Old Then Saved Draft',
            age_days=121,
        )

        Content.objects.filter(
            id=content.id,
        ).update(
            updated_at=self.now - timedelta(days=1),
        )

        result = purge_expired_producer_drafts()

        self.assertTrue(
            Content.objects.filter(id=content.id).exists()
        )
        self.assertEqual(result['deleted'], 0)

    @patch('apps.catalog.tasks.timezone.now')
    def test_pending_approved_and_rejected_are_never_deleted(
        self,
        now_mock,
    ):
        now_mock.return_value = self.now

        contents = []

        for submission_status in (
            'pending',
            'approved',
            'rejected',
        ):
            contents.append(
                self._create_content(
                    title=f'Protected {submission_status}',
                    status=submission_status,
                    age_days=365,
                )
            )

        result = purge_expired_producer_drafts()

        for content in contents:
            self.assertTrue(
                Content.objects.filter(
                    id=content.id,
                ).exists(),
                content.producer_submission_status,
            )

        self.assertEqual(result['deleted'], 0)

    @patch(
        'apps.catalog.draft_cleanup.default_storage.delete'
    )
    @patch(
        'apps.catalog.draft_cleanup.default_storage.exists'
    )
    @patch('apps.catalog.tasks.timezone.now')
    def test_expired_draft_removes_registered_temp_media(
        self,
        now_mock,
        exists_mock,
        delete_mock,
    ):
        now_mock.return_value = self.now
        exists_mock.return_value = True

        temporary_path = (
            'uploads/test/automatic-purge/poster.jpg'
        )

        content = self._create_content(
            title='Expired Draft With Media',
            age_days=121,
            poster_temp_path=temporary_path,
        )

        result = purge_expired_producer_drafts()

        self.assertFalse(
            Content.objects.filter(id=content.id).exists()
        )

        exists_mock.assert_called_with(
            temporary_path,
        )
        delete_mock.assert_called_with(
            temporary_path,
        )

        self.assertEqual(result['deleted'], 1)
        self.assertEqual(result['storage_errors'], 0)

    @patch(
        'apps.catalog.draft_cleanup.default_storage.delete'
    )
    @patch(
        'apps.catalog.draft_cleanup.default_storage.exists'
    )
    @patch('apps.catalog.tasks.timezone.now')
    def test_storage_error_does_not_block_automatic_deletion(
        self,
        now_mock,
        exists_mock,
        delete_mock,
    ):
        now_mock.return_value = self.now
        exists_mock.return_value = True
        delete_mock.side_effect = RuntimeError(
            'Temporary storage unavailable'
        )

        content = self._create_content(
            title='Expired Draft Storage Failure',
            age_days=121,
            poster_temp_path=(
                'uploads/test/automatic-purge/failure.jpg'
            ),
        )

        result = purge_expired_producer_drafts()

        self.assertFalse(
            Content.objects.filter(id=content.id).exists()
        )

        self.assertEqual(result['deleted'], 1)
        self.assertEqual(result['storage_errors'], 1)

    @patch(
        'apps.catalog.tasks.delete_draft_temporary_media'
    )
    @patch('apps.catalog.tasks.timezone.now')
    def test_only_expired_drafts_reach_cleanup(
        self,
        now_mock,
        cleanup_mock,
    ):
        now_mock.return_value = self.now
        cleanup_mock.return_value = {
            'deleted': 0,
            'errors': 0,
        }

        expired = self._create_content(
            title='Expired Candidate',
            age_days=121,
        )

        recent = self._create_content(
            title='Recent Draft',
            age_days=10,
        )

        protected = self._create_content(
            title='Old Pending',
            status='pending',
            age_days=365,
        )

        result = purge_expired_producer_drafts()

        self.assertFalse(
            Content.objects.filter(id=expired.id).exists()
        )

        self.assertTrue(
            Content.objects.filter(id=recent.id).exists()
        )

        self.assertTrue(
            Content.objects.filter(id=protected.id).exists()
        )

        self.assertEqual(
            cleanup_mock.call_count,
            1,
        )

        cleaned_content = cleanup_mock.call_args.args[0]

        # Django remet la clé primaire à None après delete().
        # On vérifie donc l'identité logique du seul contenu
        # transmis au nettoyage plutôt que son id post-suppression.
        self.assertEqual(
            cleaned_content.title,
            expired.title,
        )

        self.assertEqual(result['deleted'], 1)

    @patch('apps.catalog.tasks.timezone.now')
    @patch(
        'apps.streaming.services.default_storage.delete'
    )
    @patch(
        'apps.streaming.services.default_storage.exists'
    )
    def test_expired_series_draft_removes_episode_master(
        self,
        exists_mock,
        delete_mock,
        now_mock,
    ):
        now_mock.return_value = self.now
        exists_mock.return_value = True

        content = Content.objects.create(
            title='Expired Series Draft With Master',
            type='series',
            producer_submission_status='draft',
        )

        from core.models import Episode, Season, VideoAsset

        season = Season.objects.create(
            content=content,
            season_number=1,
        )

        episode = Episode.objects.create(
            content=content,
            season=season,
            episode_number=1,
            title='Episode 1',
        )

        source_path = (
            'uploads/test/automatic-purge/'
            'series/master.mp4'
        )

        VideoAsset.objects.create(
            content=content,
            episode=episode,
            title='Episode 1',
            source_file_path=source_path,
        )

        Content.objects.filter(
            id=content.id
        ).update(
            updated_at=(
                self.now
                - timedelta(
                    days=DRAFT_RETENTION_DAYS + 1
                )
            )
        )

        result = purge_expired_producer_drafts()

        self.assertFalse(
            Content.objects.filter(
                id=content.id
            ).exists()
        )

        exists_mock.assert_called_with(
            source_path
        )

        delete_mock.assert_called_with(
            source_path
        )

        self.assertEqual(
            result['deleted'],
            1,
        )

        self.assertEqual(
            result['storage_errors'],
            0,
        )

    def test_expired_series_storage_error_does_not_block_purge(
        self,
    ):
        from datetime import timedelta
        from unittest.mock import patch

        from django.utils import timezone

        from apps.catalog.tasks import (
            purge_expired_producer_drafts,
        )
        from core.models import (
            Content,
            Episode,
            Season,
            VideoAsset,
        )

        now = timezone.now()

        content = Content.objects.create(
            title='Expired Series Storage Error',
            type='series',
            producer_submission_status='draft',
        )

        season = Season.objects.create(
            content=content,
            season_number=1,
            title='Season 1',
        )

        episode = Episode.objects.create(
            content=content,
            season=season,
            episode_number=1,
            title='Episode 1',
        )

        VideoAsset.objects.create(
            content=content,
            episode=episode,
            title='Episode master',
            source_file_path=(
                'uploads/test/purge-error/master.mp4'
            ),
        )

        Content.objects.filter(
            id=content.id
        ).update(
            updated_at=now - timedelta(days=121)
        )

        with patch(
            'apps.catalog.tasks.timezone.now',
            return_value=now,
        ), patch(
            'apps.streaming.services.'
            'default_storage.exists',
            return_value=True,
        ), patch(
            'apps.streaming.services.'
            'default_storage.delete',
            side_effect=RuntimeError(
                'storage unavailable'
            ),
        ):
            result = (
                purge_expired_producer_drafts()
            )

        self.assertFalse(
            Content.objects.filter(
                id=content.id
            ).exists()
        )

        self.assertEqual(
            result['deleted'],
            1,
        )

        self.assertEqual(
            result['storage_errors'],
            1,
        )
