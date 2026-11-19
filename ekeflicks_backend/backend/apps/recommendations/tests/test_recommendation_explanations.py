from types import SimpleNamespace

from django.test import TestCase

from core.models import (
    Content,
    Genre,
)

from apps.recommendations.recommendation_explanations import (
    EKE_AI_EXPLANATION_VERSION,
    RecommendationExplanationError,
    build_recommendation_explanation,
    explain_personalized_recommendation,
)
from apps.recommendations.user_context import (
    EKE_AI_USER_CONTEXT_VERSION,
    EkeAIUserContext,
    GenrePreference,
)


class RecommendationExplanationTests(TestCase):
    def _context(
        self,
        *,
        preferred_genres=(),
        current_intent="",
    ):
        return EkeAIUserContext(
            version=EKE_AI_USER_CONTEXT_VERSION,
            user_id="explain-user",
            profile_id="explain-profile",
            profile_name="Main",
            current_intent=current_intent,
            preferred_genres=tuple(
                GenrePreference(
                    slug=slug,
                    weight=5,
                )
                for slug
                in preferred_genres
            ),
            signal_counts={
                "watch_history": 0,
                "likes": 0,
                "favorites": 0,
                "ratings": 0,
            },
        )

    def _content(
        self,
        *,
        title="Explanation Target",
        approved=True,
        trending_score=0,
        popularity_score=0,
    ):
        return Content.objects.create(
            title=title,
            description="Grounded explanation test.",
            type="movie",
            producer_submission_status=(
                "approved"
                if approved
                else "draft"
            ),
            trending_score=trending_score,
            popularity_score=popularity_score,
        )

    def _recommendation(
        self,
        content,
        *,
        reasons=(),
        score=50,
    ):
        return SimpleNamespace(
            content_id=str(
                content.id
            ),
            score=score,
            reasons=tuple(
                reasons
            ),
        )

    def test_preference_signal_is_grounded_by_genre(self):
        genre = Genre.objects.create(
            name="Explain Thriller",
            slug="explain-thriller",
        )

        content = self._content()

        content.genres.add(
            genre
        )

        result = build_recommendation_explanation(
            context=self._context(
                preferred_genres=(
                    genre.slug,
                ),
            ),
            recommendation=self._recommendation(
                content,
                reasons=(
                    "profile_preference",
                ),
            ),
            content=content,
        )

        codes = {
            signal.code
            for signal
            in result.signals
        }

        self.assertIn(
            "preferred_genre",
            codes,
        )

    def test_preference_claim_omitted_without_real_match(self):
        content = self._content()

        result = build_recommendation_explanation(
            context=self._context(
                preferred_genres=(
                    "other-genre",
                ),
            ),
            recommendation=self._recommendation(
                content,
                reasons=(
                    "profile_preference",
                ),
            ),
            content=content,
        )

        codes = {
            signal.code
            for signal
            in result.signals
        }

        self.assertNotIn(
            "preferred_genre",
            codes,
        )

    def test_trending_signal_requires_positive_score(self):
        content = self._content(
            trending_score=90,
        )

        result = build_recommendation_explanation(
            context=self._context(),
            recommendation=self._recommendation(
                content,
                reasons=(
                    "trending",
                ),
            ),
            content=content,
        )

        self.assertIn(
            "trending",
            {
                signal.code
                for signal
                in result.signals
            },
        )

    def test_popular_signal_requires_positive_score(self):
        content = self._content(
            popularity_score=80,
        )

        result = build_recommendation_explanation(
            context=self._context(),
            recommendation=self._recommendation(
                content,
                reasons=(
                    "popular",
                ),
            ),
            content=content,
        )

        self.assertIn(
            "popular",
            {
                signal.code
                for signal
                in result.signals
            },
        )

    def test_discovery_signal_is_explained(self):
        content = self._content()

        result = build_recommendation_explanation(
            context=self._context(),
            recommendation=self._recommendation(
                content,
                reasons=(
                    "discovery",
                ),
            ),
            content=content,
        )

        self.assertIn(
            "discovery",
            {
                signal.code
                for signal
                in result.signals
            },
        )

    def test_current_intent_requires_real_context_intent(self):
        content = self._content()

        result = build_recommendation_explanation(
            context=self._context(
                current_intent=(
                    "something to watch tonight"
                ),
            ),
            recommendation=self._recommendation(
                content,
                reasons=(
                    "current_intent",
                ),
            ),
            content=content,
        )

        self.assertIn(
            "current_intent",
            {
                signal.code
                for signal
                in result.signals
            },
        )

    def test_unknown_reason_is_not_invented(self):
        content = self._content()

        result = build_recommendation_explanation(
            context=self._context(),
            recommendation=self._recommendation(
                content,
                reasons=(
                    "totally_unknown_signal",
                ),
            ),
            content=content,
        )

        self.assertEqual(
            result.signals,
            tuple(),
        )

    def test_fallback_remains_grounded(self):
        content = self._content()

        result = build_recommendation_explanation(
            context=self._context(),
            recommendation=self._recommendation(
                content,
                reasons=(),
            ),
            content=content,
        )

        self.assertIn(
            "personalized recommendation",
            result.headline.lower(),
        )

    def test_serialization_contract(self):
        content = self._content()

        result = build_recommendation_explanation(
            context=self._context(),
            recommendation=self._recommendation(
                content,
                reasons=(
                    "discovery",
                ),
                score=42,
            ),
            content=content,
        )

        payload = result.to_dict()

        self.assertEqual(
            payload["version"],
            EKE_AI_EXPLANATION_VERSION,
        )

        self.assertEqual(
            payload["content_id"],
            str(
                content.id
            ),
        )

        self.assertEqual(
            payload["title"],
            content.title,
        )

        self.assertEqual(
            payload["recommendation_score"],
            42.0,
        )

        self.assertIsInstance(
            payload["signals"],
            list,
        )

    def test_invalid_context_rejected(self):
        content = self._content()

        with self.assertRaises(
            RecommendationExplanationError
        ):
            build_recommendation_explanation(
                context=None,
                recommendation=self._recommendation(
                    content
                ),
                content=content,
            )

    def test_pipeline_explanation_uses_authorized_content(self):
        content = self._content(
            title="Popular Explanation Target",
            trending_score=100,
            popularity_score=100,
        )

        result = explain_personalized_recommendation(
            context=self._context(),
            content_id=str(
                content.id
            ),
        )

        self.assertEqual(
            result.content_id,
            str(
                content.id
            ),
        )

    def test_pipeline_rejects_draft_content(self):
        content = self._content(
            title="Hidden Explanation Target",
            approved=False,
            trending_score=100,
            popularity_score=100,
        )

        with self.assertRaises(
            RecommendationExplanationError
        ):
            explain_personalized_recommendation(
                context=self._context(),
                content_id=str(
                    content.id
                ),
            )
