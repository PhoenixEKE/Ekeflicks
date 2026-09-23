from django.contrib.auth import get_user_model
from django.test import TestCase

from apps.profiles.social_models import (
    SocialConnection,
    SocialProfile,
)
from apps.salons.models import (
    SALON_MODE_VERSION,
    Salon,
)
from apps.salons.social_matching import (
    match_users_for_salon,
)
from core.models.content import (
    Content,
    ContentGenre,
    Genre,
)
from core.models.profiles import Profile


User = get_user_model()


class SalonModeTests(TestCase):
    def _user(self, email):
        return User.objects.create_user(
            email=email,
            password="StrongPass123!",
        )

    def _profile(self, user, name):
        profile = (
            Profile.objects
            .filter(
                user=user,
                is_active=True,
            )
            .first()
        )

        if profile is None:
            profile = (
                Profile.objects
                .filter(user=user)
                .first()
            )

        if profile is None:
            raise AssertionError(
                "User profile was not created."
            )

        if profile.name != name:
            profile.name = name
            profile.save(
                update_fields=("name",)
            )

        social, _ = (
            SocialProfile.objects
            .get_or_create(
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

        return profile, social

    def _salon(
        self,
        *,
        host,
        mode=Salon.MODE_SOCIAL,
        content=None,
    ):
        return Salon.objects.create(
            host=host,
            name="G5-3M Salon",
            mode=mode,
            content=content,
        )

    def test_version(self):
        self.assertEqual(
            SALON_MODE_VERSION,
            "g5_3m_v1",
        )

    def test_default_mode_is_social(self):
        host = self._user(
            "g5m-default@example.com"
        )

        salon = Salon.objects.create(
            host=host,
            name="Default",
        )

        self.assertEqual(
            salon.mode,
            Salon.MODE_SOCIAL,
        )

    def test_all_modes_are_persistable(self):
        host = self._user(
            "g5m-modes@example.com"
        )

        for mode in (
            Salon.MODE_SOCIAL,
            Salon.MODE_FRIENDS,
            Salon.MODE_MIXED,
            Salon.MODE_THEMATIC,
        ):
            salon = self._salon(
                host=host,
                mode=mode,
            )

            salon.refresh_from_db()

            self.assertEqual(
                salon.mode,
                mode,
            )

    def test_social_excludes_accepted_connections(self):
        host = self._user(
            "g5m-social-host@example.com"
        )
        friend = self._user(
            "g5m-social-friend@example.com"
        )
        stranger = self._user(
            "g5m-social-stranger@example.com"
        )

        _, host_social = self._profile(
            host,
            "Host",
        )
        _, friend_social = self._profile(
            friend,
            "Friend",
        )
        self._profile(
            stranger,
            "Stranger",
        )

        SocialConnection.objects.create(
            requester=host_social,
            target=friend_social,
            status=SocialConnection.STATUS_ACCEPTED,
        )

        salon = self._salon(
            host=host,
            mode=Salon.MODE_SOCIAL,
        )

        matches = match_users_for_salon(
            salon=salon,
            requester=host,
        )

        ids = {
            item.user_id
            if hasattr(item, "user_id")
            else item.user.pk
            for item in matches
        }

        self.assertNotIn(
            friend.pk,
            ids,
        )
        self.assertIn(
            stranger.pk,
            ids,
        )

    def test_friends_only_returns_accepted_connections(self):
        host = self._user(
            "g5m-friends-host@example.com"
        )
        friend = self._user(
            "g5m-friends-friend@example.com"
        )
        stranger = self._user(
            "g5m-friends-stranger@example.com"
        )

        _, host_social = self._profile(
            host,
            "Host",
        )
        _, friend_social = self._profile(
            friend,
            "Friend",
        )
        self._profile(
            stranger,
            "Stranger",
        )

        SocialConnection.objects.create(
            requester=host_social,
            target=friend_social,
            status=SocialConnection.STATUS_ACCEPTED,
        )

        salon = self._salon(
            host=host,
            mode=Salon.MODE_FRIENDS,
        )

        ids = {
            item.user.pk
            for item in match_users_for_salon(
                salon=salon,
                requester=host,
            )
        }

        self.assertIn(
            friend.pk,
            ids,
        )
        self.assertNotIn(
            stranger.pk,
            ids,
        )

    def test_mixed_returns_friend_and_stranger(self):
        host = self._user(
            "g5m-mixed-host@example.com"
        )
        friend = self._user(
            "g5m-mixed-friend@example.com"
        )
        stranger = self._user(
            "g5m-mixed-stranger@example.com"
        )

        _, host_social = self._profile(
            host,
            "Host",
        )
        _, friend_social = self._profile(
            friend,
            "Friend",
        )
        self._profile(
            stranger,
            "Stranger",
        )

        SocialConnection.objects.create(
            requester=host_social,
            target=friend_social,
            status=SocialConnection.STATUS_ACCEPTED,
        )

        salon = self._salon(
            host=host,
            mode=Salon.MODE_MIXED,
        )

        ids = {
            item.user.pk
            for item in match_users_for_salon(
                salon=salon,
                requester=host,
            )
        }

        self.assertIn(
            friend.pk,
            ids,
        )
        self.assertIn(
            stranger.pk,
            ids,
        )

    def test_thematic_without_content_has_no_matches(self):
        host = self._user(
            "g5m-theme-host@example.com"
        )
        candidate = self._user(
            "g5m-theme-candidate@example.com"
        )

        self._profile(
            host,
            "Host",
        )
        self._profile(
            candidate,
            "Candidate",
        )

        salon = self._salon(
            host=host,
            mode=Salon.MODE_THEMATIC,
        )

        self.assertEqual(
            match_users_for_salon(
                salon=salon,
                requester=host,
            ),
            tuple(),
        )
