from django.contrib.auth import get_user_model
from django.db import IntegrityError
from django.test import TestCase

from rest_framework.test import APIClient

from core.models.profiles import Profile
from core.models import ProfileType

from apps.profiles.social_models import (
    SocialBlock,
    SocialConnection,
    SocialProfile,
)


User = get_user_model()


class SocialConnectionTests(TestCase):
    def setUp(self):
        self.client = APIClient()

        self.user_a = User.objects.create_user(
            email="connection-a@example.com",
            password="Password123!",
        )
        self.user_b = User.objects.create_user(
            email="connection-b@example.com",
            password="Password123!",
        )

        self.profile_type, _ = (
            ProfileType.objects.get_or_create(
                name="main",
            )
        )

        self.profile_a = (
            Profile.objects
            .filter(
                user=self.user_a,
                is_active=True,
            )
            .order_by(
                "created_at",
                "pk",
            )
            .first()
        )

        if self.profile_a is None:
            self.profile_a = (
                Profile.objects
                .filter(user=self.user_a)
                .order_by(
                    "created_at",
                    "pk",
                )
                .first()
            )

        if self.profile_a is None:
            self.profile_a = Profile.objects.create(
                user=self.user_a,
                type=self.profile_type,
                name="Connection A",
                is_active=True,
            )
        else:
            self.profile_a.type = self.profile_type
            self.profile_a.name = "Connection A"
            self.profile_a.is_active = True
            self.profile_a.save(
                update_fields=(
                    "type",
                    "name",
                    "is_active",
                    "updated_at",
                )
            )

        self.profile_b = (
            Profile.objects
            .filter(
                user=self.user_b,
                is_active=True,
            )
            .order_by(
                "created_at",
                "pk",
            )
            .first()
        )

        if self.profile_b is None:
            self.profile_b = (
                Profile.objects
                .filter(user=self.user_b)
                .order_by(
                    "created_at",
                    "pk",
                )
                .first()
            )

        if self.profile_b is None:
            self.profile_b = Profile.objects.create(
                user=self.user_b,
                type=self.profile_type,
                name="Connection B",
                is_active=True,
            )
        else:
            self.profile_b.type = self.profile_type
            self.profile_b.name = "Connection B"
            self.profile_b.is_active = True
            self.profile_b.save(
                update_fields=(
                    "type",
                    "name",
                    "is_active",
                    "updated_at",
                )
            )

        self.social_a = SocialProfile.objects.create(
            profile=self.profile_a,
            display_name="Connection A",
            is_discoverable=True,
        )
        self.social_b = SocialProfile.objects.create(
            profile=self.profile_b,
            display_name="Connection B",
            is_discoverable=True,
        )

    def _auth(self, user):
        self.client.force_authenticate(user=user)

    def test_authentication_required(self):
        response = self.client.get(
            "/api/v1/social-connections/"
        )
        self.assertEqual(response.status_code, 401)

    def test_create_connection_request(self):
        self._auth(self.user_a)

        response = self.client.post(
            "/api/v1/social-connections/",
            {
                "target_profile_id":
                    str(self.profile_b.pk),
            },
            format="json",
        )

        self.assertEqual(response.status_code, 201)

        connection = SocialConnection.objects.get()

        self.assertEqual(
            connection.requester,
            self.social_a,
        )
        self.assertEqual(
            connection.target,
            self.social_b,
        )
        self.assertEqual(
            connection.status,
            SocialConnection.STATUS_PENDING,
        )

    def test_duplicate_pending_is_idempotent(self):
        self._auth(self.user_a)

        payload = {
            "target_profile_id":
                str(self.profile_b.pk),
        }

        first = self.client.post(
            "/api/v1/social-connections/",
            payload,
            format="json",
        )
        second = self.client.post(
            "/api/v1/social-connections/",
            payload,
            format="json",
        )

        self.assertEqual(first.status_code, 201)
        self.assertEqual(second.status_code, 201)
        self.assertEqual(
            SocialConnection.objects.count(),
            1,
        )

    def test_self_connection_rejected(self):
        self._auth(self.user_a)

        response = self.client.post(
            "/api/v1/social-connections/",
            {
                "target_profile_id":
                    str(self.profile_a.pk),
            },
            format="json",
        )

        self.assertEqual(response.status_code, 400)

    def test_hidden_target_not_connectable(self):
        self.social_b.is_discoverable = False
        self.social_b.save(
            update_fields=["is_discoverable"]
        )

        self._auth(self.user_a)

        response = self.client.post(
            "/api/v1/social-connections/",
            {
                "target_profile_id":
                    str(self.profile_b.pk),
            },
            format="json",
        )

        self.assertEqual(response.status_code, 404)

    def test_block_prevents_connection(self):
        SocialBlock.objects.create(
            blocker=self.social_b,
            blocked=self.social_a,
        )

        self._auth(self.user_a)

        response = self.client.post(
            "/api/v1/social-connections/",
            {
                "target_profile_id":
                    str(self.profile_b.pk),
            },
            format="json",
        )

        self.assertEqual(response.status_code, 403)

    def test_target_can_accept(self):
        connection = SocialConnection.objects.create(
            requester=self.social_a,
            target=self.social_b,
        )

        self._auth(self.user_b)

        response = self.client.post(
            (
                "/api/v1/social-connections/"
                f"{connection.pk}/accept/"
            ),
            {},
            format="json",
        )

        self.assertEqual(response.status_code, 200)

        connection.refresh_from_db()

        self.assertEqual(
            connection.status,
            SocialConnection.STATUS_ACCEPTED,
        )
        self.assertIsNotNone(
            connection.responded_at
        )

    def test_requester_cannot_accept_own_request(self):
        connection = SocialConnection.objects.create(
            requester=self.social_a,
            target=self.social_b,
        )

        self._auth(self.user_a)

        response = self.client.post(
            (
                "/api/v1/social-connections/"
                f"{connection.pk}/accept/"
            ),
            {},
            format="json",
        )

        self.assertEqual(response.status_code, 403)

    def test_target_can_decline(self):
        connection = SocialConnection.objects.create(
            requester=self.social_a,
            target=self.social_b,
        )

        self._auth(self.user_b)

        response = self.client.post(
            (
                "/api/v1/social-connections/"
                f"{connection.pk}/decline/"
            ),
            {},
            format="json",
        )

        self.assertEqual(response.status_code, 200)

        connection.refresh_from_db()

        self.assertEqual(
            connection.status,
            SocialConnection.STATUS_DECLINED,
        )

    def test_accepted_list_only_returns_accepted(self):
        SocialConnection.objects.create(
            requester=self.social_a,
            target=self.social_b,
            status=SocialConnection.STATUS_ACCEPTED,
        )

        self._auth(self.user_a)

        response = self.client.get(
            "/api/v1/social-connections/accepted/"
        )

        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(
            response.data[0]["status"],
            "accepted",
        )

    def test_either_party_can_remove_connection(self):
        connection = SocialConnection.objects.create(
            requester=self.social_a,
            target=self.social_b,
            status=SocialConnection.STATUS_ACCEPTED,
        )

        self._auth(self.user_a)

        response = self.client.delete(
            (
                "/api/v1/social-connections/"
                f"{connection.pk}/"
            )
        )

        self.assertEqual(response.status_code, 204)

        self.assertFalse(
            SocialConnection.objects.filter(
                pk=connection.pk
            ).exists()
        )

    def test_unique_direction_constraint(self):
        SocialConnection.objects.create(
            requester=self.social_a,
            target=self.social_b,
        )

        with self.assertRaises(IntegrityError):
            SocialConnection.objects.create(
                requester=self.social_a,
                target=self.social_b,
            )
