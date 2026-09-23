from django.test import TestCase

from apps.recommendations.candidate_generation import (
    Candidate,
    CandidatePool,
)
from apps.recommendations.personalized_engine import (
    EKE_AI_PERSONALIZED_ENGINE_VERSION,
    PersonalizedRecommendationError,
    recommend_for_context,
)
from apps.recommendations.user_context import (
    EKE_AI_USER_CONTEXT_VERSION,
    EkeAIUserContext,
    GenrePreference,
)


class PersonalizedRecommendationEngineTests(TestCase):
    def _context(
        self,
        *,
        profile_id="profile-1",
        watched=(),
        genres=(),
        counts=None,
    ):
        if counts is None:
            counts = {
                "watch_history": 1,
                "likes": 1,
                "favorites": 0,
                "ratings": 0,
            }

        return EkeAIUserContext(
            version=EKE_AI_USER_CONTEXT_VERSION,
            user_id="user-1",
            profile_id=profile_id,
            profile_name="Main",
            watched_content_ids=tuple(
                watched
            ),
            preferred_genres=tuple(
                GenrePreference(
                    slug=slug,
                    weight=weight,
                )
                for slug, weight in genres
            ),
            signal_counts=counts,
        )

    def _pool(
        self,
        candidates,
        profile_id="profile-1",
    ):
        return CandidatePool(
            version="g5_2c_v1",
            profile_id=profile_id,
            candidates=tuple(candidates),
            source_counts={},
        )

    def test_preferred_genre_candidate_wins_baseline(self):
        context = self._context(
            genres=(
                ("thriller", 4),
            ),
        )

        preferred = Candidate(
            content_id="preferred",
            sources=(
                "preferred_genres",
                "trending",
            ),
            genre_matches=(
                "thriller",
            ),
            trending_score=20,
        )

        global_only = Candidate(
            content_id="global",
            sources=(
                "trending",
                "popular",
            ),
            trending_score=90,
            popularity_score=90,
        )

        result = recommend_for_context(
            context=context,
            candidate_pool=self._pool(
                [
                    global_only,
                    preferred,
                ]
            ),
        )

        self.assertEqual(
            result.recommendations[
                0
            ].content_id,
            "preferred",
        )

        self.assertIn(
            "preferred_genre",
            result.recommendations[
                0
            ].reasons,
        )

    def test_top10_is_supporting_signal(self):
        context = self._context()

        candidate = Candidate(
            content_id="top10-content",
            sources=(
                "top10",
            ),
            top10_position=2,
        )

        result = recommend_for_context(
            context=context,
            candidate_pool=self._pool(
                [candidate]
            ),
        )

        recommendation = (
            result.recommendations[0]
        )

        self.assertIn(
            "global_top10",
            recommendation.reasons,
        )

        self.assertGreater(
            recommendation.score,
            0,
        )

    def test_watched_content_cannot_be_recommended(self):
        context = self._context(
            watched=(
                "watched",
            ),
        )

        pool = self._pool(
            [
                Candidate(
                    content_id="watched",
                    sources=(
                        "trending",
                    ),
                    trending_score=100,
                ),
                Candidate(
                    content_id="new",
                    sources=(
                        "popular",
                    ),
                    popularity_score=20,
                ),
            ]
        )

        result = recommend_for_context(
            context=context,
            candidate_pool=pool,
        )

        ids = {
            item.content_id
            for item
            in result.recommendations
        }

        self.assertNotIn(
            "watched",
            ids,
        )

        self.assertIn(
            "new",
            ids,
        )

    def test_cold_start_uses_global_signals(self):
        context = self._context(
            genres=(),
            counts={
                "watch_history": 0,
                "likes": 0,
                "favorites": 0,
                "ratings": 0,
            },
        )

        pool = self._pool(
            [
                Candidate(
                    content_id="cold",
                    sources=(
                        "top10",
                        "trending",
                    ),
                    trending_score=80,
                    top10_position=1,
                )
            ]
        )

        result = recommend_for_context(
            context=context,
            candidate_pool=pool,
        )

        self.assertTrue(
            result.cold_start
        )

        self.assertIn(
            "global_top10",
            result.recommendations[
                0
            ].reasons,
        )

        self.assertIn(
            "trending",
            result.recommendations[
                0
            ].reasons,
        )

        self.assertNotIn(
            "preferred_genre",
            result.recommendations[
                0
            ].reasons,
        )

    def test_profile_mismatch_is_rejected(self):
        context = self._context(
            profile_id="profile-A",
        )

        pool = self._pool(
            [],
            profile_id="profile-B",
        )

        with self.assertRaises(
            PersonalizedRecommendationError
        ):
            recommend_for_context(
                context=context,
                candidate_pool=pool,
            )

    def test_limit_is_guarded(self):
        context = self._context()
        pool = self._pool([])

        with self.assertRaises(
            PersonalizedRecommendationError
        ):
            recommend_for_context(
                context=context,
                candidate_pool=pool,
                limit=0,
            )

        with self.assertRaises(
            PersonalizedRecommendationError
        ):
            recommend_for_context(
                context=context,
                candidate_pool=pool,
                limit=101,
            )

    def test_limit_is_applied(self):
        context = self._context()

        pool = self._pool(
            [
                Candidate(
                    content_id=str(index),
                    sources=(
                        "trending",
                    ),
                    trending_score=index,
                )
                for index in range(10)
            ]
        )

        result = recommend_for_context(
            context=context,
            candidate_pool=pool,
            limit=3,
        )

        self.assertEqual(
            len(result.recommendations),
            3,
        )

    def test_result_contract(self):
        context = self._context()

        pool = self._pool(
            [
                Candidate(
                    content_id="contract",
                    sources=(
                        "popular",
                    ),
                    popularity_score=50,
                )
            ]
        )

        result = recommend_for_context(
            context=context,
            candidate_pool=pool,
        )

        payload = result.to_dict()

        self.assertEqual(
            payload["version"],
            EKE_AI_PERSONALIZED_ENGINE_VERSION,
        )

        self.assertEqual(
            payload["profile_id"],
            "profile-1",
        )

        self.assertEqual(
            payload["recommendation_count"],
            1,
        )

        self.assertIn(
            "score",
            payload[
                "recommendations"
            ][0],
        )

        self.assertIn(
            "reasons",
            payload[
                "recommendations"
            ][0],
        )
