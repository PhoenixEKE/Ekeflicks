from datetime import timedelta

from django.test import TestCase
from django.utils import timezone

from core.models import Content, Genre

from apps.recommendations.intelligent_search import (
    EKE_AI_SEARCH_VERSION,
    IntelligentSearchError,
    intelligent_search,
)
from apps.recommendations.user_context import (
    EKE_AI_USER_CONTEXT_VERSION,
    EkeAIUserContext,
    GenrePreference,
)


class EkeAIIntelligentSearchTests(TestCase):
    def _context(
        self,
        genres=(),
    ):
        return EkeAIUserContext(
            version=EKE_AI_USER_CONTEXT_VERSION,
            user_id="user-1",
            profile_id="profile-1",
            profile_name="Main",
            current_intent="",
            preferred_genres=tuple(
                GenrePreference(
                    slug=slug,
                    weight=weight,
                )
                for slug, weight
                in genres
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
        title,
        description="",
        approved=True,
        available_from=None,
        available_until=None,
    ):
        return Content.objects.create(
            title=title,
            description=description,
            type="movie",
            producer_submission_status=(
                "approved"
                if approved
                else "draft"
            ),
            available_from=available_from,
            available_until=available_until,
        )

    def test_exact_title_is_ranked_first(self):
        exact = self._content(
            title="Night City",
        )

        self._content(
            title="Night City Stories",
        )

        result = intelligent_search(
            query="Night City",
            context=self._context(),
        )

        self.assertEqual(
            result.results[0].content_id,
            str(exact.id),
        )

        self.assertIn(
            "exact_title",
            result.results[0].reasons,
        )

    def test_description_terms_can_match(self):
        content = self._content(
            title="Silent Road",
            description=(
                "A mysterious journey through the desert."
            ),
        )

        result = intelligent_search(
            query="desert",
            context=self._context(),
        )

        self.assertEqual(
            result.results[0].content_id,
            str(content.id),
        )

        self.assertIn(
            "description_terms",
            result.results[0].reasons,
        )

    def test_genre_terms_can_match(self):
        genre = Genre.objects.create(
            name="Thriller",
            slug="thriller",
        )

        content = self._content(
            title="The Signal",
        )

        content.genres.add(
            genre
        )

        result = intelligent_search(
            query="thriller",
            context=self._context(),
        )

        self.assertEqual(
            result.results[0].content_id,
            str(content.id),
        )

        self.assertIn(
            "genre_match",
            result.results[0].reasons,
        )

    def test_profile_preference_is_secondary_signal(self):
        genre = Genre.objects.create(
            name="Thriller",
            slug="thriller",
        )

        preferred = self._content(
            title="Night Alpha",
        )

        preferred.genres.add(
            genre
        )

        other = self._content(
            title="Night Beta",
        )

        result = intelligent_search(
            query="night",
            context=self._context(
                genres=(
                    (
                        "thriller",
                        4,
                    ),
                ),
            ),
        )

        self.assertEqual(
            result.results[0].content_id,
            str(preferred.id),
        )

        self.assertIn(
            "profile_preference",
            result.results[0].reasons,
        )

        self.assertNotEqual(
            result.results[0].content_id,
            str(other.id),
        )

    def test_unapproved_content_is_never_returned(self):
        approved = self._content(
            title="Secret Approved",
        )

        self._content(
            title="Secret Draft",
            approved=False,
        )

        result = intelligent_search(
            query="secret",
            context=self._context(),
        )

        ids = {
            item.content_id
            for item in result.results
        }

        self.assertEqual(
            ids,
            {
                str(approved.id),
            },
        )

    def test_future_content_is_never_returned(self):
        today = timezone.localdate()

        visible = self._content(
            title="Future Visible",
        )

        self._content(
            title="Future Hidden",
            available_from=(
                today
                + timedelta(
                    days=1
                )
            ),
        )

        result = intelligent_search(
            query="future",
            context=self._context(),
        )

        ids = {
            item.content_id
            for item in result.results
        }

        self.assertEqual(
            ids,
            {
                str(visible.id),
            },
        )

    def test_expired_content_is_never_returned(self):
        today = timezone.localdate()

        visible = self._content(
            title="Archive Visible",
        )

        self._content(
            title="Archive Expired",
            available_until=(
                today
                - timedelta(
                    days=1
                )
            ),
        )

        result = intelligent_search(
            query="archive",
            context=self._context(),
        )

        ids = {
            item.content_id
            for item in result.results
        }

        self.assertEqual(
            ids,
            {
                str(visible.id),
            },
        )

    def test_no_match_returns_empty_results(self):
        self._content(
            title="Completely Different",
        )

        result = intelligent_search(
            query="spaceship",
            context=self._context(),
        )

        self.assertEqual(
            result.results,
            tuple(),
        )

    def test_empty_query_rejected(self):
        with self.assertRaises(
            IntelligentSearchError
        ):
            intelligent_search(
                query="   ",
                context=self._context(),
            )

    def test_limit_guard(self):
        with self.assertRaises(
            IntelligentSearchError
        ):
            intelligent_search(
                query="night",
                context=self._context(),
                limit=0,
            )

        with self.assertRaises(
            IntelligentSearchError
        ):
            intelligent_search(
                query="night",
                context=self._context(),
                limit=51,
            )

    def test_response_contract(self):
        result = intelligent_search(
            query="night",
            context=self._context(),
        )

        payload = result.to_dict()

        self.assertEqual(
            payload["version"],
            EKE_AI_SEARCH_VERSION,
        )

        self.assertEqual(
            payload["profile_id"],
            "profile-1",
        )

        self.assertIn(
            "result_count",
            payload,
        )

        self.assertIn(
            "results",
            payload,
        )
