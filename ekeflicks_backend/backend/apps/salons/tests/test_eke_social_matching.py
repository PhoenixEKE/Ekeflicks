from django.contrib.auth import get_user_model
from django.test import TestCase

from apps.profiles.social_models import (
    SocialProfile,
)
from apps.recommendations.user_context import (
    build_user_context,
)
from apps.salons.eke_social_matching import (
    EKE_SOCIAL_MATCHING_VERSION,
    calculate_social_compatibility,
)
from apps.salons.models import Salon
from apps.salons.services import create_salon
from apps.salons.social_matching import (
    match_users_for_salon,
)
from core.models import (
    Content,
    Favorite,
    Genre,
    Like,
    Rating,
    WatchHistory,
)
from core.models.profiles import (
    Profile,
    ProfileType,
)


User = get_user_model()


class EkeSocialMatchingTests(TestCase):
    def setUp(self):
        self.profile_type = (
            ProfileType.objects.create(
                name="G5-3F",
            )
        )

        self.requester = self._user(
            "requester-g53f@example.com",
        )

        self.strong_candidate = self._user(
            "strong-g53f@example.com",
        )

        self.discovery_candidate = self._user(
            "discovery-g53f@example.com",
        )

        self.salon = create_salon(
            host=self.requester,
            name="G5-3F Salon",
            visibility=Salon.VISIBILITY_PUBLIC,
            capacity=10,
        )

    def _user(self, email):
        user = User.objects.create_user(
            email=email,
            password="test-pass-123",
        )

        profile = (
            Profile.objects
            .filter(
                user=user,
                is_active=True,
            )
            .order_by(
                "created_at",
                "pk",
            )
            .first()
        )

        if profile is None:
            profile = (
                Profile.objects
                .filter(user=user)
                .order_by(
                    "created_at",
                    "pk",
                )
                .first()
            )

        if profile is None:
            profile = Profile.objects.create(
                user=user,
                type=self.profile_type,
                name=email.split("@")[0],
                is_active=True,
            )
        else:
            profile.type = self.profile_type
            profile.is_active = True

            profile.save(
                update_fields=(
                    "type",
                    "is_active",
                    "updated_at",
                )
            )

        social, _ = (
            SocialProfile.objects.get_or_create(
                profile=profile,
                defaults={
                    "display_name":
                        profile.name,
                    "is_discoverable":
                        True,
                },
            )
        )

        if not social.is_discoverable:
            social.is_discoverable = True
            social.save(
                update_fields=(
                    "is_discoverable",
                    "updated_at",
                )
            )

        return user

    def _profile(self, user):
        return (
            Profile.objects
            .filter(
                user=user,
                is_active=True,
            )
            .order_by(
                "created_at",
                "pk",
            )
            .first()
        )

    def _content(self, title):
        return Content.objects.create(
            title=title,
            producer_submission_status="approved",
        )

    def test_adapter_uses_canonical_eke_context(self):
        profile = self._profile(
            self.requester
        )

        context = build_user_context(
            user=self.requester,
            profile_id=profile.pk,
        )

        self.assertEqual(
            context.profile_id,
            str(profile.pk),
        )

    def test_empty_context_has_discovery_fallback(self):
        requester_context = build_user_context(
            user=self.requester,
            profile_id=self._profile(
                self.requester
            ).pk,
        )

        candidate_context = build_user_context(
            user=self.discovery_candidate,
            profile_id=self._profile(
                self.discovery_candidate
            ).pk,
        )

        result = calculate_social_compatibility(
            requester_context=requester_context,
            candidate_context=candidate_context,
        )

        self.assertEqual(
            result.version,
            EKE_SOCIAL_MATCHING_VERSION,
        )

        self.assertEqual(
            result.score,
            5,
        )

        self.assertEqual(
            result.reasons,
            ("community_discovery",),
        )

    def test_shared_behavior_outranks_discovery(self):
        content = self._content(
            "G5-3F Shared"
        )

        requester_profile = self._profile(
            self.requester
        )

        strong_profile = self._profile(
            self.strong_candidate
        )

        WatchHistory.objects.create(
            profile=requester_profile,
            content=content,
            progress=50,
            watched_duration=100,
            completed=False,
        )

        WatchHistory.objects.create(
            profile=strong_profile,
            content=content,
            progress=70,
            watched_duration=120,
            completed=False,
        )

        Like.objects.create(
            profile=requester_profile,
            content=content,
        )

        Like.objects.create(
            profile=strong_profile,
            content=content,
        )

        results = match_users_for_salon(
            salon=self.salon,
            requester=self.requester,
            limit=20,
        )

        by_id = {
            item.user.pk: item
            for item in results
        }

        strong = by_id[
            self.strong_candidate.pk
        ]

        discovery = by_id[
            self.discovery_candidate.pk
        ]

        self.assertGreater(
            strong.score,
            discovery.score,
        )

        self.assertIn(
            "shared_content_taste",
            strong.reasons,
        )

        self.assertIn(
            "shared_engagement",
            strong.reasons,
        )

    def test_weighted_genre_affinity_is_used(self):
        genre = Genre.objects.create(
            name="G5-3F Science Fiction",
            slug="g5-3f-science-fiction",
        )

        content = self._content(
            "G5-3F Genre"
        )

        content.genres.add(
            genre
        )

        requester_profile = self._profile(
            self.requester
        )

        strong_profile = self._profile(
            self.strong_candidate
        )

        Favorite.objects.create(
            profile=requester_profile,
            content=content,
        )

        Favorite.objects.create(
            profile=strong_profile,
            content=content,
        )

        requester_context = build_user_context(
            user=self.requester,
            profile_id=requester_profile.pk,
        )

        candidate_context = build_user_context(
            user=self.strong_candidate,
            profile_id=strong_profile.pk,
        )

        result = calculate_social_compatibility(
            requester_context=requester_context,
            candidate_context=candidate_context,
        )

        self.assertIn(
            "shared_genres",
            result.reasons,
        )

        self.assertIn(
            genre.slug,
            result.common_genre_slugs,
        )

    def test_positive_rating_affinity_is_used(self):
        content = self._content(
            "G5-3F Rating"
        )

        requester_profile = self._profile(
            self.requester
        )

        strong_profile = self._profile(
            self.strong_candidate
        )

        Rating.objects.create(
            profile=requester_profile,
            content=content,
            rating=4.5,
        )

        Rating.objects.create(
            profile=strong_profile,
            content=content,
            rating=5.0,
        )

        requester_context = build_user_context(
            user=self.requester,
            profile_id=requester_profile.pk,
        )

        candidate_context = build_user_context(
            user=self.strong_candidate,
            profile_id=strong_profile.pk,
        )

        result = calculate_social_compatibility(
            requester_context=requester_context,
            candidate_context=candidate_context,
        )

        self.assertIn(
            "shared_positive_ratings",
            result.reasons,
        )

    def test_country_is_not_an_eke_social_reason(self):
        requester_profile = self._profile(
            self.requester
        )

        candidate_profile = self._profile(
            self.discovery_candidate
        )

        requester_profile.country_code = "FR"
        requester_profile.save(
            update_fields=(
                "country_code",
                "updated_at",
            )
        )

        candidate_profile.country_code = "FR"
        candidate_profile.save(
            update_fields=(
                "country_code",
                "updated_at",
            )
        )

        results = match_users_for_salon(
            salon=self.salon,
            requester=self.requester,
        )

        match = {
            item.user.pk: item
            for item in results
        }[
            self.discovery_candidate.pk
        ]

        self.assertNotIn(
            "same_country",
            match.reasons,
        )

    def test_hidden_profile_is_filtered_before_eke_context(self):
        profile = self._profile(
            self.strong_candidate
        )

        social = SocialProfile.objects.get(
            profile=profile,
        )

        social.is_discoverable = False
        social.save(
            update_fields=(
                "is_discoverable",
                "updated_at",
            )
        )

        results = match_users_for_salon(
            salon=self.salon,
            requester=self.requester,
        )

        ids = {
            item.user.pk
            for item in results
        }

        self.assertNotIn(
            self.strong_candidate.pk,
            ids,
        )
