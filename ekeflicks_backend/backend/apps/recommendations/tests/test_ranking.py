from django.test import TestCase

from apps.recommendations.candidate_generation import (
    Candidate,
)
from apps.recommendations.ranking import (
    EKE_AI_RANKING_VERSION,
    RankingError,
    rank_candidates,
    score_candidate,
)
from apps.recommendations.user_context import (
    EKE_AI_USER_CONTEXT_VERSION,
    EkeAIUserContext,
    GenrePreference,
)


class EkeAIRankingTests(TestCase):
    def _context(
        self,
        *,
        genres=(),
        intent="",
        counts=None,
    ):
        if counts is None:
            counts = {
                "watch_history": 2,
                "likes": 1,
                "favorites": 1,
                "ratings": 1,
            }

        return EkeAIUserContext(
            version=EKE_AI_USER_CONTEXT_VERSION,
            user_id="user-1",
            profile_id="profile-1",
            profile_name="Main",
            current_intent=intent,
            preferred_genres=tuple(
                GenrePreference(
                    slug=slug,
                    weight=weight,
                )
                for slug, weight in genres
            ),
            signal_counts=counts,
        )

    def test_preference_component_rewards_matching_genre(self):
        context = self._context(
            genres=(
                ("thriller", 4),
            ),
        )

        matching = Candidate(
            content_id="matching",
            sources=(
                "preferred_genres",
            ),
            genre_matches=(
                "thriller",
            ),
        )

        other = Candidate(
            content_id="other",
            sources=(),
            genre_matches=(),
        )

        match_score = score_candidate(
            context=context,
            candidate=matching,
        )

        other_score = score_candidate(
            context=context,
            candidate=other,
        )

        self.assertGreater(
            match_score.components.preference,
            0,
        )

        self.assertGreater(
            match_score.score,
            other_score.score,
        )

    def test_current_intent_can_override_weaker_history_signal(self):
        context = self._context(
            genres=(
                ("comedy", 1),
            ),
            intent="Je veux un thriller ce soir",
        )

        history_candidate = Candidate(
            content_id="history",
            sources=(
                "preferred_genres",
            ),
            genre_matches=(
                "comedy",
            ),
        )

        intent_candidate = Candidate(
            content_id="intent",
            sources=(
                "trending",
            ),
            genre_matches=(
                "thriller",
            ),
            trending_score=20,
        )

        ranked = rank_candidates(
            context=context,
            candidates=(
                history_candidate,
                intent_candidate,
            ),
        )

        self.assertEqual(
            ranked[0].content_id,
            "intent",
        )

        self.assertIn(
            "current_intent",
            ranked[0].reasons,
        )

    def test_top10_contributes_but_is_not_personal_affinity(self):
        context = self._context(
            genres=(),
        )

        candidate = Candidate(
            content_id="top10",
            sources=(
                "top10",
            ),
            top10_position=1,
        )

        scored = score_candidate(
            context=context,
            candidate=candidate,
        )

        self.assertGreater(
            scored.components.trend,
            0,
        )

        self.assertEqual(
            scored.components.preference,
            0,
        )

    def test_behavior_is_confidence_not_content_fabrication(self):
        context = self._context(
            counts={
                "watch_history": 10,
                "likes": 5,
                "favorites": 3,
                "ratings": 2,
            },
        )

        candidate = Candidate(
            content_id="real-candidate",
            sources=(),
        )

        scored = score_candidate(
            context=context,
            candidate=candidate,
        )

        self.assertEqual(
            scored.content_id,
            "real-candidate",
        )

        self.assertGreater(
            scored.components.behavior,
            0,
        )

    def test_discovery_bonus_is_small_and_explicit(self):
        context = self._context(
            genres=(
                ("thriller", 4),
            ),
        )

        candidate = Candidate(
            content_id="discover",
            sources=(
                "trending",
            ),
            genre_matches=(
                "comedy",
            ),
            trending_score=10,
        )

        scored = score_candidate(
            context=context,
            candidate=candidate,
        )

        self.assertEqual(
            scored.components.discovery,
            3.0,
        )

        self.assertIn(
            "discovery",
            scored.reasons,
        )

    def test_component_sum_equals_score(self):
        context = self._context(
            genres=(
                ("thriller", 3),
            ),
            intent="thriller",
        )

        candidate = Candidate(
            content_id="sum",
            sources=(
                "preferred_genres",
                "trending",
                "popular",
                "top10",
            ),
            genre_matches=(
                "thriller",
            ),
            trending_score=70,
            popularity_score=80,
            top10_position=3,
        )

        scored = score_candidate(
            context=context,
            candidate=candidate,
        )

        self.assertEqual(
            scored.score,
            scored.components.total,
        )

    def test_ranking_is_deterministic(self):
        context = self._context()

        candidates = (
            Candidate(
                content_id="b",
                sources=(),
            ),
            Candidate(
                content_id="a",
                sources=(),
            ),
        )

        first = rank_candidates(
            context=context,
            candidates=candidates,
        )

        second = rank_candidates(
            context=context,
            candidates=candidates,
        )

        self.assertEqual(
            first,
            second,
        )

        self.assertEqual(
            [
                item.content_id
                for item in first
            ],
            [
                "a",
                "b",
            ],
        )

    def test_limit_guard(self):
        context = self._context()

        with self.assertRaises(
            RankingError
        ):
            rank_candidates(
                context=context,
                candidates=(),
                limit=0,
            )

        with self.assertRaises(
            RankingError
        ):
            rank_candidates(
                context=context,
                candidates=(),
                limit=101,
            )

    def test_contract_version(self):
        self.assertEqual(
            EKE_AI_RANKING_VERSION,
            "g5_2e_v1",
        )
