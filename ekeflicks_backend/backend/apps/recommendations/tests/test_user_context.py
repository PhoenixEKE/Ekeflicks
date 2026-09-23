from django.test import TestCase

from apps.recommendations.user_context import (
    EKE_AI_USER_CONTEXT_VERSION,
    EkeAIAuthenticationRequired,
    EkeAIContextError,
    EkeAIProfileUnavailable,
    build_user_context,
    resolve_active_profile,
)
from core.models import (
    Content,
    Favorite,
    Genre,
    Like,
    Profile,
    Rating,
    User,
    WatchHistory,
)


class EkeAIUserContextTests(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            email="context@example.com",
            password="StrongPass123",
            firstname="Context",
        )

        self.profile = Profile.objects.get(
            user=self.user,
        )

        self.other_user = User.objects.create_user(
            email="other-context@example.com",
            password="StrongPass123",
            firstname="Other",
        )

        self.other_profile = Profile.objects.get(
            user=self.other_user,
        )

        self.scifi = Genre.objects.create(
            name="Science Fiction",
            slug="science-fiction",
        )

        self.drama = Genre.objects.create(
            name="Drama",
            slug="drama",
        )

        self.watched = Content.objects.create(
            title="Context Watched",
            type="movie",
        )

        self.liked = Content.objects.create(
            title="Context Liked",
            type="movie",
        )

        self.favorite = Content.objects.create(
            title="Context Favorite",
            type="series",
        )

        self.rated = Content.objects.create(
            title="Context Rated",
            type="movie",
        )

        self.watched.genres.add(
            self.scifi,
        )

        self.liked.genres.add(
            self.scifi,
        )

        self.favorite.genres.add(
            self.drama,
        )

        self.rated.genres.add(
            self.scifi,
        )

        WatchHistory.objects.create(
            profile=self.profile,
            content=self.watched,
            progress=70,
            watched_duration=420,
            completed=False,
        )

        Like.objects.create(
            profile=self.profile,
            content=self.liked,
        )

        Favorite.objects.create(
            profile=self.profile,
            content=self.favorite,
        )

        Rating.objects.create(
            profile=self.profile,
            content=self.rated,
            rating=4,
        )

    def test_builds_normalized_context(self):
        context = build_user_context(
            user=self.user,
            profile_id=self.profile.id,
            current_intent=(
                "Je veux une série courte"
            ),
        )

        self.assertEqual(
            context.version,
            EKE_AI_USER_CONTEXT_VERSION,
        )

        self.assertEqual(
            context.user_id,
            str(self.user.id),
        )

        self.assertEqual(
            context.profile_id,
            str(self.profile.id),
        )

        self.assertEqual(
            context.current_intent,
            "Je veux une série courte",
        )

        self.assertEqual(
            context.signal_counts,
            {
                "watch_history": 1,
                "likes": 1,
                "favorites": 1,
                "ratings": 1,
            },
        )

        self.assertEqual(
            context.watched_content_ids,
            (
                str(self.watched.id),
            ),
        )

        self.assertEqual(
            context.liked_content_ids,
            (
                str(self.liked.id),
            ),
        )

        self.assertEqual(
            context.favorite_content_ids,
            (
                str(self.favorite.id),
            ),
        )

        self.assertEqual(
            context.ratings[0].content_id,
            str(self.rated.id),
        )

        self.assertEqual(
            context.ratings[0].rating,
            4.0,
        )

        self.assertEqual(
            context.recent_watch_history[0].progress,
            70,
        )

        self.assertEqual(
            context.recent_watch_history[0].watched_duration,
            420,
        )

    def test_like_and_favorite_are_independent(self):
        context = build_user_context(
            user=self.user,
            profile_id=self.profile.id,
        )

        self.assertIn(
            str(self.liked.id),
            context.liked_content_ids,
        )

        self.assertNotIn(
            str(self.liked.id),
            context.favorite_content_ids,
        )

        self.assertIn(
            str(self.favorite.id),
            context.favorite_content_ids,
        )

        self.assertNotIn(
            str(self.favorite.id),
            context.liked_content_ids,
        )

    def test_genre_preferences_are_weighted_but_not_ranked_candidates(self):
        context = build_user_context(
            user=self.user,
            profile_id=self.profile.id,
        )

        preferences = {
            item.slug: item.weight
            for item in context.preferred_genres
        }

        self.assertEqual(
            preferences["science-fiction"],
            4,
        )

        self.assertEqual(
            preferences["drama"],
            3,
        )

    def test_foreign_profile_is_rejected(self):
        with self.assertRaises(
            EkeAIProfileUnavailable
        ):
            build_user_context(
                user=self.user,
                profile_id=self.other_profile.id,
            )

    def test_inactive_profile_is_rejected(self):
        self.profile.is_active = False
        self.profile.save(
            update_fields=[
                "is_active",
            ],
        )

        with self.assertRaises(
            EkeAIProfileUnavailable
        ):
            resolve_active_profile(
                user=self.user,
                profile_id=self.profile.id,
            )

    def test_anonymous_actor_is_rejected(self):
        class AnonymousActor:
            is_authenticated = False

        with self.assertRaises(
            EkeAIAuthenticationRequired
        ):
            build_user_context(
                user=AnonymousActor(),
            )

    def test_history_limit_is_guarded(self):
        with self.assertRaises(
            EkeAIContextError
        ):
            build_user_context(
                user=self.user,
                profile_id=self.profile.id,
                history_limit=0,
            )

        with self.assertRaises(
            EkeAIContextError
        ):
            build_user_context(
                user=self.user,
                profile_id=self.profile.id,
                history_limit=201,
            )

    def test_to_dict_contract(self):
        context = build_user_context(
            user=self.user,
            profile_id=self.profile.id,
        )

        payload = context.to_dict()

        self.assertEqual(
            payload["version"],
            EKE_AI_USER_CONTEXT_VERSION,
        )

        self.assertEqual(
            payload["profile_id"],
            str(self.profile.id),
        )

        self.assertEqual(
            payload["signal_counts"]["likes"],
            1,
        )

        self.assertEqual(
            payload["signal_counts"]["favorites"],
            1,
        )

        self.assertIsInstance(
            payload["preferred_genres"],
            list,
        )
