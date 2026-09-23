from django.test import TestCase

from apps.recommendations.candidate_generation import (
    Candidate,
)
from apps.recommendations.diversification import (
    EKE_AI_DIVERSIFICATION_VERSION,
    DiversificationError,
    diversify_ranked_candidates,
)
from apps.recommendations.ranking import (
    RankedCandidate,
    RankingComponents,
)
from apps.recommendations.user_context import (
    EKE_AI_USER_CONTEXT_VERSION,
    EkeAIUserContext,
)


class EkeAIDiversificationTests(TestCase):
    def _context(self):
        return EkeAIUserContext(
            version=EKE_AI_USER_CONTEXT_VERSION,
            user_id="user-1",
            profile_id="profile-1",
            profile_name="Main",
            signal_counts={
                "watch_history": 1,
                "likes": 1,
                "favorites": 0,
                "ratings": 0,
            },
        )

    def _ranked(
        self,
        content_id,
        score,
        *,
        reasons=(),
        sources=(),
    ):
        return RankedCandidate(
            content_id=content_id,
            score=score,
            components=RankingComponents(
                preference=score,
            ),
            reasons=tuple(reasons),
            sources=tuple(sources),
        )

    def test_preserves_original_top_one(self):
        context = self._context()

        ranked = (
            self._ranked(
                "best",
                100,
            ),
            self._ranked(
                "other",
                99,
                reasons=(
                    "discovery",
                ),
            ),
        )

        candidates = (
            Candidate(
                content_id="best",
                sources=(),
                genre_matches=(
                    "thriller",
                ),
            ),
            Candidate(
                content_id="other",
                sources=(
                    "trending",
                ),
                genre_matches=(
                    "comedy",
                ),
            ),
        )

        result = diversify_ranked_candidates(
            context=context,
            ranked_candidates=ranked,
            candidates=candidates,
            limit=2,
        )

        self.assertEqual(
            result[0].content_id,
            "best",
        )

    def test_promotes_genre_variety_when_scores_are_close(self):
        context = self._context()

        ranked = (
            self._ranked(
                "a",
                100,
            ),
            self._ranked(
                "b",
                98,
            ),
            self._ranked(
                "c",
                97,
            ),
        )

        candidates = (
            Candidate(
                content_id="a",
                sources=(),
                genre_matches=(
                    "thriller",
                ),
            ),
            Candidate(
                content_id="b",
                sources=(),
                genre_matches=(
                    "thriller",
                ),
            ),
            Candidate(
                content_id="c",
                sources=(),
                genre_matches=(
                    "comedy",
                ),
            ),
        )

        result = diversify_ranked_candidates(
            context=context,
            ranked_candidates=ranked,
            candidates=candidates,
            limit=3,
        )

        self.assertEqual(
            result[0].content_id,
            "a",
        )

        self.assertEqual(
            result[1].content_id,
            "c",
        )

    def test_discovery_signal_can_break_close_tie(self):
        context = self._context()

        ranked = (
            self._ranked(
                "top",
                100,
            ),
            self._ranked(
                "normal",
                90,
            ),
            self._ranked(
                "discover",
                89,
                reasons=(
                    "discovery",
                ),
                sources=(
                    "trending",
                ),
            ),
        )

        candidates = (
            Candidate(
                content_id="top",
                sources=(),
                genre_matches=(),
            ),
            Candidate(
                content_id="normal",
                sources=(),
                genre_matches=(),
            ),
            Candidate(
                content_id="discover",
                sources=(
                    "trending",
                ),
                genre_matches=(),
            ),
        )

        result = diversify_ranked_candidates(
            context=context,
            ranked_candidates=ranked,
            candidates=candidates,
            limit=3,
        )

        self.assertEqual(
            result[1].content_id,
            "discover",
        )

    def test_does_not_change_ranking_score(self):
        context = self._context()

        original = self._ranked(
            "x",
            42.5,
            reasons=(
                "discovery",
            ),
        )

        result = diversify_ranked_candidates(
            context=context,
            ranked_candidates=(
                original,
            ),
            candidates=(
                Candidate(
                    content_id="x",
                    sources=(),
                    genre_matches=(
                        "drama",
                    ),
                ),
            ),
            limit=1,
        )

        self.assertEqual(
            result[0].score,
            42.5,
        )

        self.assertEqual(
            result[0],
            original,
        )

    def test_unknown_candidate_is_never_introduced(self):
        context = self._context()

        ranked = (
            self._ranked(
                "authorized",
                10,
            ),
            self._ranked(
                "missing",
                100,
            ),
        )

        result = diversify_ranked_candidates(
            context=context,
            ranked_candidates=ranked,
            candidates=(
                Candidate(
                    content_id="authorized",
                    sources=(),
                ),
            ),
            limit=10,
        )

        ids = {
            item.content_id
            for item in result
        }

        self.assertEqual(
            ids,
            {
                "authorized",
            },
        )

    def test_empty_input_is_safe(self):
        result = diversify_ranked_candidates(
            context=self._context(),
            ranked_candidates=(),
            candidates=(),
            limit=20,
        )

        self.assertEqual(
            result,
            tuple(),
        )

    def test_is_deterministic(self):
        context = self._context()

        ranked = (
            self._ranked(
                "a",
                20,
            ),
            self._ranked(
                "b",
                20,
            ),
            self._ranked(
                "c",
                20,
            ),
        )

        candidates = (
            Candidate(
                content_id="a",
                sources=(),
                genre_matches=(
                    "thriller",
                ),
            ),
            Candidate(
                content_id="b",
                sources=(),
                genre_matches=(
                    "comedy",
                ),
            ),
            Candidate(
                content_id="c",
                sources=(),
                genre_matches=(
                    "drama",
                ),
            ),
        )

        first = diversify_ranked_candidates(
            context=context,
            ranked_candidates=ranked,
            candidates=candidates,
            limit=3,
        )

        second = diversify_ranked_candidates(
            context=context,
            ranked_candidates=ranked,
            candidates=candidates,
            limit=3,
        )

        self.assertEqual(
            first,
            second,
        )

    def test_limit_guard(self):
        context = self._context()

        with self.assertRaises(
            DiversificationError
        ):
            diversify_ranked_candidates(
                context=context,
                ranked_candidates=(),
                candidates=(),
                limit=0,
            )

        with self.assertRaises(
            DiversificationError
        ):
            diversify_ranked_candidates(
                context=context,
                ranked_candidates=(),
                candidates=(),
                limit=101,
            )

    def test_version_contract(self):
        self.assertEqual(
            EKE_AI_DIVERSIFICATION_VERSION,
            "g5_2f_v1",
        )
