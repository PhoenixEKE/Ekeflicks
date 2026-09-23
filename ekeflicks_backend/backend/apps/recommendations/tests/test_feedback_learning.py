from django.contrib.auth import get_user_model
from django.test import TestCase

from core.models import (
    Content,
    Favorite,
    Like,
    Rating,
)

from apps.recommendations.feedback_learning import (
    EKE_AI_FEEDBACK_VERSION,
    FeedbackLearningError,
    record_feedback,
)


User = get_user_model()


class FeedbackLearningTests(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            email="feedback@example.com",
            password="test-password",
        )

        self.profile = (
            self.user.profiles
            .filter(
                is_active=True
            )
            .first()
        )

        self.assertIsNotNone(
            self.profile
        )

        self.content = Content.objects.create(
            title="Feedback Target",
            description="Behavioral learning target.",
            type="movie",
            producer_submission_status="approved",
        )

    def _record(
        self,
        action,
        *,
        rating=None,
        content=None,
        profile_id=None,
    ):
        return record_feedback(
            user=self.user,
            profile_id=(
                str(
                    self.profile.id
                )
                if profile_id is None
                else profile_id
            ),
            content_id=str(
                (
                    content
                    or self.content
                ).id
            ),
            action=action,
            rating=rating,
        )

    def test_like_creates_signal(self):
        result = self._record(
            "like"
        )

        self.assertEqual(
            result.version,
            EKE_AI_FEEDBACK_VERSION,
        )

        self.assertTrue(
            result.changed
        )

        self.assertTrue(
            result.liked
        )

        self.assertTrue(
            Like.objects.filter(
                profile=self.profile,
                content=self.content,
            ).exists()
        )

        self.assertEqual(
            result.signal_counts["likes"],
            1,
        )

    def test_duplicate_like_is_idempotent(self):
        first = self._record(
            "like"
        )

        second = self._record(
            "like"
        )

        self.assertTrue(
            first.changed
        )

        self.assertFalse(
            second.changed
        )

        self.assertEqual(
            Like.objects.filter(
                profile=self.profile,
                content=self.content,
            ).count(),
            1,
        )

    def test_unlike_removes_signal(self):
        self._record(
            "like"
        )

        result = self._record(
            "unlike"
        )

        self.assertTrue(
            result.changed
        )

        self.assertFalse(
            result.liked
        )

        self.assertEqual(
            result.signal_counts["likes"],
            0,
        )

    def test_favorite_creates_signal(self):
        result = self._record(
            "favorite"
        )

        self.assertTrue(
            result.favorited
        )

        self.assertTrue(
            Favorite.objects.filter(
                profile=self.profile,
                content=self.content,
            ).exists()
        )

        self.assertEqual(
            result.signal_counts["favorites"],
            1,
        )

    def test_unfavorite_removes_signal(self):
        self._record(
            "favorite"
        )

        result = self._record(
            "unfavorite"
        )

        self.assertFalse(
            result.favorited
        )

        self.assertEqual(
            result.signal_counts["favorites"],
            0,
        )

    def test_rating_creates_signal(self):
        result = self._record(
            "rate",
            rating=4,
        )

        self.assertEqual(
            result.rating,
            4.0,
        )

        self.assertTrue(
            Rating.objects.filter(
                profile=self.profile,
                content=self.content,
                rating=4,
            ).exists()
        )

        self.assertEqual(
            result.signal_counts["ratings"],
            1,
        )

    def test_rating_updates_existing_signal(self):
        self._record(
            "rate",
            rating=2,
        )

        result = self._record(
            "rate",
            rating=5,
        )

        self.assertTrue(
            result.changed
        )

        self.assertEqual(
            result.rating,
            5.0,
        )

        self.assertEqual(
            Rating.objects.filter(
                profile=self.profile,
                content=self.content,
            ).count(),
            1,
        )

    def test_same_rating_is_idempotent(self):
        self._record(
            "rate",
            rating=5,
        )

        result = self._record(
            "rate",
            rating=5,
        )

        self.assertFalse(
            result.changed
        )

        self.assertEqual(
            result.rating,
            5.0,
        )

    def test_clear_rating(self):
        self._record(
            "rate",
            rating=3,
        )

        result = self._record(
            "clear_rating"
        )

        self.assertTrue(
            result.changed
        )

        self.assertIsNone(
            result.rating
        )

        self.assertEqual(
            result.signal_counts["ratings"],
            0,
        )

    def test_invalid_rating_rejected(self):
        with self.assertRaises(
            FeedbackLearningError
        ):
            self._record(
                "rate",
                rating=6,
            )

    def test_missing_rating_rejected(self):
        with self.assertRaises(
            FeedbackLearningError
        ):
            self._record(
                "rate",
            )

    def test_unknown_action_rejected(self):
        with self.assertRaises(
            FeedbackLearningError
        ):
            self._record(
                "dismiss"
            )

    def test_draft_content_rejected(self):
        hidden = Content.objects.create(
            title="Hidden Feedback Target",
            description="Must remain unauthorized.",
            type="movie",
            producer_submission_status="draft",
        )

        with self.assertRaises(
            FeedbackLearningError
        ):
            self._record(
                "like",
                content=hidden,
            )

    def test_cross_user_profile_rejected(self):
        other = User.objects.create_user(
            email="other-feedback@example.com",
            password="test-password",
        )

        other_profile = (
            other.profiles
            .filter(
                is_active=True
            )
            .first()
        )

        with self.assertRaises(
            Exception
        ):
            self._record(
                "like",
                profile_id=str(
                    other_profile.id
                ),
            )
