from django.contrib.auth import get_user_model
from django.db import IntegrityError, transaction
from django.urls import reverse

from rest_framework.test import APITestCase

from apps.profiles.social_models import (
    SocialBlock,
    SocialMute,
    SocialProfile,
    SocialReport,
    SocialReputation,
)
from apps.profiles.social_safety import (
    SOCIAL_SAFETY_VERSION,
    is_social_match_allowed,
)
from core.models.profiles import (
    Profile,
    ProfileType,
)


User = get_user_model()


class SocialSafetyTests(APITestCase):
    def setUp(self):
        self.profile_type = (
            ProfileType.objects.create(
                name="G5-3G Adult",
            )
        )

        self.user_a = User.objects.create_user(
            email="g53g-a@example.com",
            password="test-pass-123",
        )

        self.user_b = User.objects.create_user(
            email="g53g-b@example.com",
            password="test-pass-123",
        )

        self.profile_a = self._profile(
            self.user_a,
            "A",
        )

        self.profile_b = self._profile(
            self.user_b,
            "B",
        )

        self.social_a = self._social(
            self.profile_a,
            "A",
        )

        self.social_b = self._social(
            self.profile_b,
            "B",
        )

    def _profile(self, user, name):
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
            return Profile.objects.create(
                user=user,
                type=self.profile_type,
                name=name,
                is_active=True,
            )

        profile.type = self.profile_type
        profile.name = name
        profile.is_active = True

        profile.save(
            update_fields=(
                "type",
                "name",
                "is_active",
                "updated_at",
            )
        )

        return profile

    def _social(self, profile, display_name):
        social, _ = SocialProfile.objects.get_or_create(
            profile=profile,
            defaults={
                "display_name": display_name,
                "is_discoverable": True,
            },
        )

        changed = []

        if social.display_name != display_name:
            social.display_name = display_name
            changed.append(
                "display_name"
            )

        if not social.is_discoverable:
            social.is_discoverable = True
            changed.append(
                "is_discoverable"
            )

        if changed:
            changed.append(
                "updated_at"
            )

            social.save(
                update_fields=tuple(changed)
            )

        return social

    def test_version(self):
        self.assertEqual(
            SOCIAL_SAFETY_VERSION,
            "g5_3g_v1",
        )

    def test_block_is_symmetric_for_matching(self):
        SocialBlock.objects.create(
            blocker=self.social_b,
            blocked=self.social_a,
        )

        self.assertFalse(
            is_social_match_allowed(
                requester_social=self.social_a,
                candidate_social=self.social_b,
            )
        )

    def test_mute_is_directional(self):
        SocialMute.objects.create(
            muter=self.social_a,
            muted=self.social_b,
        )

        self.assertFalse(
            is_social_match_allowed(
                requester_social=self.social_a,
                candidate_social=self.social_b,
            )
        )

        self.assertTrue(
            is_social_match_allowed(
                requester_social=self.social_b,
                candidate_social=self.social_a,
            )
        )

    def test_self_block_is_database_rejected(self):
        with self.assertRaises(IntegrityError):
            with transaction.atomic():
                SocialBlock.objects.create(
                    blocker=self.social_a,
                    blocked=self.social_a,
                )

    def test_report_does_not_auto_block(self):
        SocialReport.objects.create(
            reporter=self.social_a,
            reported=self.social_b,
            reason=SocialReport.REASON_SPAM,
        )

        self.assertTrue(
            is_social_match_allowed(
                requester_social=self.social_a,
                candidate_social=self.social_b,
            )
        )

    def test_reputation_defaults_to_100(self):
        reputation = SocialReputation.objects.create(
            profile=self.social_a
        )

        self.assertEqual(
            reputation.score,
            100,
        )

    def test_public_serializer_does_not_expose_reputation(self):
        from apps.profiles.social_serializers import (
            PublicSocialProfileSerializer,
        )

        fields = set(
            PublicSocialProfileSerializer().fields
        )

        self.assertNotIn(
            "reputation",
            fields,
        )

        self.assertNotIn(
            "score",
            fields,
        )

    def test_block_api_is_owner_scoped_and_idempotent(self):
        self.client.force_authenticate(
            self.user_a
        )

        url = reverse(
            "social-block"
        )

        payload = {
            "profile_id": str(
                self.profile_b.pk
            )
        }

        first = self.client.post(
            url,
            payload,
            format="json",
        )

        second = self.client.post(
            url,
            payload,
            format="json",
        )

        self.assertIn(
            first.status_code,
            (200, 201),
        )

        self.assertEqual(
            second.status_code,
            200,
        )

        self.assertEqual(
            SocialBlock.objects.filter(
                blocker=self.social_a,
                blocked=self.social_b,
            ).count(),
            1,
        )

    def test_report_api_persists_without_sanction(self):
        self.client.force_authenticate(
            self.user_a
        )

        response = self.client.post(
            reverse("social-report"),
            {
                "profile_id": str(
                    self.profile_b.pk
                ),
                "reason": "spam",
                "details": "Repeated unsolicited messages.",
            },
            format="json",
        )

        self.assertEqual(
            response.status_code,
            201,
        )

        self.assertTrue(
            SocialReport.objects.filter(
                reporter=self.social_a,
                reported=self.social_b,
                reason="spam",
            ).exists()
        )

        self.assertFalse(
            SocialBlock.objects.filter(
                blocker=self.social_a,
                blocked=self.social_b,
            ).exists()
        )

    def test_reputation_api_only_returns_private_score(self):
        self.client.force_authenticate(
            self.user_a
        )

        response = self.client.get(
            reverse(
                "social-reputation"
            )
        )

        self.assertEqual(
            response.status_code,
            200,
        )

        self.assertEqual(
            set(response.data),
            {"score"},
        )

        self.assertEqual(
            response.data["score"],
            100,
        )
