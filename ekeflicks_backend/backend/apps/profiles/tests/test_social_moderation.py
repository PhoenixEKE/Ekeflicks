from django.contrib.auth import get_user_model
from django.urls import reverse

from rest_framework.test import APITestCase

from core.models.profiles import (
    Profile,
    ProfileType,
)

from apps.profiles.social_models import (
    SocialModeration,
    SocialProfile,
    SocialReputation,
)

from apps.profiles.social_moderation import (
    SOCIAL_MODERATION_VERSION,
    is_social_moderation_allowed,
    moderate_social_profile,
)

from apps.profiles.social_safety import (
    is_social_match_allowed,
)


User = get_user_model()


class SocialModerationTests(APITestCase):
    def setUp(self):
        self.profile_type, _ = (
            ProfileType.objects.get_or_create(
                name="main",
            )
        )

        self.staff = User.objects.create_user(
            email="moderator-g53h@example.com",
            password="strong-password",
            is_staff=True,
        )

        self.user_a = User.objects.create_user(
            email="g53h-a@example.com",
            password="strong-password",
        )

        self.user_b = User.objects.create_user(
            email="g53h-b@example.com",
            password="strong-password",
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
            .filter(user=user)
            .first()
        )

        if profile is None:
            profile = Profile.objects.create(
                user=user,
                type=self.profile_type,
                name=name,
            )
        else:
            profile.type = self.profile_type
            profile.name = name
            profile.is_active = True

            fields = [
                "type",
                "name",
                "is_active",
            ]

            field_names = {
                f.name
                for f in Profile._meta.fields
            }

            if "updated_at" in field_names:
                fields.append("updated_at")

            profile.save(
                update_fields=fields,
            )

        return profile

    def _social(self, profile, name):
        social, _ = (
            SocialProfile.objects.get_or_create(
                profile=profile,
                defaults={
                    "display_name": name,
                    "is_discoverable": True,
                },
            )
        )

        social.display_name = name
        social.is_discoverable = True
        social.save()

        return social

    def test_version(self):
        self.assertEqual(
            SOCIAL_MODERATION_VERSION,
            "g5_3h_v1",
        )

    def test_default_profile_is_allowed(self):
        self.assertTrue(
            is_social_moderation_allowed(
                self.social_a
            )
        )

    def test_limited_profile_is_ineligible(self):
        moderate_social_profile(
            profile=self.social_a,
            status="limited",
            reviewer=self.staff,
            reason="Safety review",
        )

        self.assertFalse(
            is_social_moderation_allowed(
                self.social_a
            )
        )

    def test_suspended_profile_is_ineligible(self):
        moderate_social_profile(
            profile=self.social_a,
            status="suspended",
            reviewer=self.staff,
            reason="Confirmed abuse",
        )

        self.assertFalse(
            is_social_moderation_allowed(
                self.social_a
            )
        )

    def test_limited_candidate_is_excluded_from_matching(self):
        moderate_social_profile(
            profile=self.social_b,
            status="limited",
            reviewer=self.staff,
            reason="Safety",
        )

        self.assertFalse(
            is_social_match_allowed(
                requester_social=self.social_a,
                candidate_social=self.social_b,
            )
        )

    def test_suspended_requester_is_excluded_from_matching(self):
        moderate_social_profile(
            profile=self.social_a,
            status="suspended",
            reviewer=self.staff,
            reason="Safety",
        )

        self.assertFalse(
            is_social_match_allowed(
                requester_social=self.social_a,
                candidate_social=self.social_b,
            )
        )

    def test_limited_caps_reputation(self):
        reputation, _ = (
            SocialReputation.objects.get_or_create(
                profile=self.social_a,
                defaults={
                    "score": 100,
                },
            )
        )

        reputation.score = 95
        reputation.save()

        moderate_social_profile(
            profile=self.social_a,
            status="limited",
            reviewer=self.staff,
            reason="Limited",
        )

        reputation.refresh_from_db()

        self.assertEqual(
            reputation.score,
            60,
        )

    def test_suspended_caps_reputation(self):
        reputation, _ = (
            SocialReputation.objects.get_or_create(
                profile=self.social_a,
                defaults={
                    "score": 100,
                },
            )
        )

        reputation.score = 90
        reputation.save()

        moderate_social_profile(
            profile=self.social_a,
            status="suspended",
            reviewer=self.staff,
            reason="Suspended",
        )

        reputation.refresh_from_db()

        self.assertEqual(
            reputation.score,
            20,
        )

    def test_report_does_not_automatically_sanction(self):
        from apps.profiles.social_models import (
            SocialReport,
        )

        SocialReport.objects.create(
            reporter=self.social_a,
            reported=self.social_b,
            reason="spam",
            details="Test report",
        )

        self.assertFalse(
            SocialModeration.objects.filter(
                profile=self.social_b,
            ).exists()
        )

        self.assertTrue(
            is_social_moderation_allowed(
                self.social_b
            )
        )

    def test_non_staff_service_cannot_moderate(self):
        with self.assertRaises(
            PermissionError
        ):
            moderate_social_profile(
                profile=self.social_a,
                status="suspended",
                reviewer=self.user_a,
                reason="Unauthorized",
            )

    def test_non_staff_api_is_forbidden(self):
        self.client.force_authenticate(
            self.user_a
        )

        response = self.client.patch(
            reverse(
                "social-moderation-detail",
                kwargs={
                    "profile_id":
                        self.social_b.profile_id,
                },
            ),
            {
                "status": "suspended",
                "reason": "Unauthorized",
            },
            format="json",
        )

        self.assertEqual(
            response.status_code,
            403,
        )

    def test_staff_api_can_suspend(self):
        self.client.force_authenticate(
            self.staff
        )

        response = self.client.patch(
            reverse(
                "social-moderation-detail",
                kwargs={
                    "profile_id":
                        self.social_b.profile_id,
                },
            ),
            {
                "status": "suspended",
                "reason": "Confirmed abuse",
            },
            format="json",
        )

        self.assertEqual(
            response.status_code,
            200,
        )

        moderation = (
            SocialModeration.objects.get(
                profile=self.social_b,
            )
        )

        self.assertEqual(
            moderation.status,
            "suspended",
        )

        self.assertEqual(
            moderation.reviewed_by,
            self.staff,
        )

        self.assertIsNotNone(
            moderation.reviewed_at
        )

    def test_staff_can_restore_active(self):
        moderate_social_profile(
            profile=self.social_b,
            status="suspended",
            reviewer=self.staff,
            reason="Initial decision",
        )

        self.client.force_authenticate(
            self.staff
        )

        response = self.client.patch(
            reverse(
                "social-moderation-detail",
                kwargs={
                    "profile_id":
                        self.social_b.profile_id,
                },
            ),
            {
                "status": "active",
                "reason": "Review completed",
            },
            format="json",
        )

        self.assertEqual(
            response.status_code,
            200,
        )

        moderation = (
            SocialModeration.objects.get(
                profile=self.social_b,
            )
        )

        self.assertEqual(
            moderation.status,
            "active",
        )

        self.assertTrue(
            is_social_moderation_allowed(
                self.social_b
            )
        )
