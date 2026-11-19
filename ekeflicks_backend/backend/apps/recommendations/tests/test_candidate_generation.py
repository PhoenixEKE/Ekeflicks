from datetime import timedelta

from django.test import TestCase
from django.utils import timezone

from apps.recommendations.candidate_generation import (
    EKE_AI_CANDIDATE_VERSION,
    CandidateGenerationError,
    generate_candidate_pool,
)
from apps.recommendations.user_context import (
    build_user_context,
)
from core.models import (
    Content,
    Genre,
    Like,
    User,
    WatchHistory,
)
from core.models.recommendations import (
    Top10Entry,
    Top10Snapshot,
)


class EkeAICandidateGenerationTests(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            email="candidate@example.com",
            password="StrongPass123",
            firstname="Candidate",
        )

        self.profile = (
            self.user.profiles
            .filter(is_active=True)
            .first()
        )

        self.genre = Genre.objects.create(
            name="Thriller",
            slug="thriller",
        )

        today = timezone.localdate()

        self.watched = Content.objects.create(
            title="Already Watched",
            type="movie",
            producer_submission_status="approved",
            available_from=today
            - timedelta(days=10),
            available_until=today
            + timedelta(days=10),
            trending_score=99,
            popularity_score=99,
        )

        self.genre_candidate = (
            Content.objects.create(
                title="Genre Candidate",
                type="movie",
                producer_submission_status="approved",
                available_from=today
                - timedelta(days=10),
                available_until=today
                + timedelta(days=10),
                trending_score=70,
                popularity_score=50,
            )
        )

        self.trending_candidate = (
            Content.objects.create(
                title="Trending Candidate",
                type="series",
                producer_submission_status="approved",
                trending_score=90,
                popularity_score=60,
            )
        )

        self.popular_candidate = (
            Content.objects.create(
                title="Popular Candidate",
                type="movie",
                producer_submission_status="approved",
                trending_score=20,
                popularity_score=95,
            )
        )

        self.pending = Content.objects.create(
            title="Pending Forbidden",
            type="movie",
            producer_submission_status="pending",
            trending_score=100,
            popularity_score=100,
        )

        self.future = Content.objects.create(
            title="Future Forbidden",
            type="movie",
            producer_submission_status="approved",
            available_from=today
            + timedelta(days=5),
            trending_score=100,
            popularity_score=100,
        )

        self.expired = Content.objects.create(
            title="Expired Forbidden",
            type="movie",
            producer_submission_status="approved",
            available_until=today
            - timedelta(days=1),
            trending_score=100,
            popularity_score=100,
        )

        self.watched.genres.add(
            self.genre
        )

        self.genre_candidate.genres.add(
            self.genre
        )

        WatchHistory.objects.create(
            profile=self.profile,
            content=self.watched,
            progress=100,
            watched_duration=7200,
            completed=True,
        )

        Like.objects.create(
            profile=self.profile,
            content=self.genre_candidate,
        )

    def _context(self):
        return build_user_context(
            user=self.user,
            profile_id=self.profile.id,
        )

    def test_generates_only_postgresql_eligible_candidates(self):
        pool = generate_candidate_pool(
            context=self._context(),
            limit=100,
        )

        ids = {
            candidate.content_id
            for candidate
            in pool.candidates
        }

        self.assertIn(
            str(self.genre_candidate.id),
            ids,
        )

        self.assertIn(
            str(self.trending_candidate.id),
            ids,
        )

        self.assertIn(
            str(self.popular_candidate.id),
            ids,
        )

        self.assertNotIn(
            str(self.pending.id),
            ids,
        )

        self.assertNotIn(
            str(self.future.id),
            ids,
        )

        self.assertNotIn(
            str(self.expired.id),
            ids,
        )

    def test_watched_content_is_excluded(self):
        pool = generate_candidate_pool(
            context=self._context(),
        )

        ids = {
            candidate.content_id
            for candidate
            in pool.candidates
        }

        self.assertNotIn(
            str(self.watched.id),
            ids,
        )

    def test_preferred_genre_source_is_recorded(self):
        pool = generate_candidate_pool(
            context=self._context(),
        )

        candidate = next(
            item
            for item in pool.candidates
            if item.content_id
            == str(
                self.genre_candidate.id
            )
        )

        self.assertIn(
            "preferred_genres",
            candidate.sources,
        )

        self.assertIn(
            "thriller",
            candidate.genre_matches,
        )

    def test_sources_are_merged_without_duplicate_candidates(self):
        pool = generate_candidate_pool(
            context=self._context(),
        )

        matching = [
            candidate
            for candidate
            in pool.candidates
            if candidate.content_id
            == str(
                self.genre_candidate.id
            )
        ]

        self.assertEqual(
            len(matching),
            1,
        )

        self.assertIn(
            "preferred_genres",
            matching[0].sources,
        )

        self.assertIn(
            "trending",
            matching[0].sources,
        )

        self.assertIn(
            "popular",
            matching[0].sources,
        )

    def test_top10_is_a_signal_not_a_personal_ranking(self):
        now = timezone.now()

        snapshot = (
            Top10Snapshot.objects.create(
                window_start=now
                - timedelta(days=7),
                window_end=now,
                scope="global",
                algorithm_version="d4_7d_v1",
                is_published=True,
            )
        )

        Top10Entry.objects.create(
            snapshot=snapshot,
            content=self.popular_candidate,
            position=1,
        )

        pool = generate_candidate_pool(
            context=self._context(),
        )

        candidate = next(
            item
            for item in pool.candidates
            if item.content_id
            == str(
                self.popular_candidate.id
            )
        )

        self.assertIn(
            "top10",
            candidate.sources,
        )

        self.assertEqual(
            candidate.top10_position,
            1,
        )

    def test_pool_contract(self):
        pool = generate_candidate_pool(
            context=self._context(),
        )

        payload = pool.to_dict()

        self.assertEqual(
            payload["version"],
            EKE_AI_CANDIDATE_VERSION,
        )

        self.assertEqual(
            payload["profile_id"],
            str(self.profile.id),
        )

        self.assertEqual(
            payload["candidate_count"],
            len(payload["candidates"]),
        )

        self.assertEqual(
            set(
                payload[
                    "source_counts"
                ].keys()
            ),
            {
                "preferred_genres",
                "trending",
                "popular",
                "top10",
            },
        )

    def test_limit_is_guarded(self):
        context = self._context()

        with self.assertRaises(
            CandidateGenerationError
        ):
            generate_candidate_pool(
                context=context,
                limit=0,
            )

        with self.assertRaises(
            CandidateGenerationError
        ):
            generate_candidate_pool(
                context=context,
                limit=201,
            )

    def test_limit_is_applied_after_deduplication(self):
        pool = generate_candidate_pool(
            context=self._context(),
            limit=2,
        )

        self.assertLessEqual(
            len(pool.candidates),
            2,
        )
