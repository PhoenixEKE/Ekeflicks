import base64
import hashlib
import hmac
import time

from django.contrib.auth import get_user_model
from django.test import override_settings
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from apps.salons.models import Salon
from apps.salons.services import create_salon, join_salon


User = get_user_model()


@override_settings(
    TURN_STUN_URLS=("stun:stun.test.invalid:3478",),
    TURN_ICE_SERVER_URLS=(
        "turn:turn.test.invalid:3478?transport=udp",
        "turns:turn.test.invalid:5349?transport=tcp",
    ),
    TURN_SHARED_SECRET="unit-test-shared-secret",
    TURN_CREDENTIAL_TTL_SECONDS=900,
)
class SalonIceServersApiTests(APITestCase):
    def setUp(self):
        self.host = User.objects.create_user(
            email="ice-host@example.com",
            password="StrongPass123!",
        )
        self.member = User.objects.create_user(
            email="ice-member@example.com",
            password="StrongPass123!",
        )
        self.outsider = User.objects.create_user(
            email="ice-outsider@example.com",
            password="StrongPass123!",
        )
        self.salon = create_salon(
            host=self.host,
            name="ICE credentials room",
            visibility=Salon.VISIBILITY_PUBLIC,
            capacity=6,
        )
        join_salon(salon=self.salon, user=self.member)
        self.url = reverse(
            "salon-ice-servers",
            kwargs={"pk": self.salon.pk},
        )

    def test_requires_authentication(self):
        response = self.client.get(self.url)
        self.assertIn(
            response.status_code,
            (status.HTTP_401_UNAUTHORIZED, status.HTTP_403_FORBIDDEN),
        )

    def test_active_member_receives_expiring_coturn_credentials(self):
        self.client.force_authenticate(user=self.member)

        response = self.client.get(self.url)

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(response.data["relay_available"])
        self.assertEqual(response.data["expires_in"], 900)
        self.assertEqual(
            response.data["ice_servers"][0]["urls"],
            ["stun:stun.test.invalid:3478"],
        )

        turn_server = response.data["ice_servers"][1]
        self.assertEqual(
            turn_server["urls"],
            [
                "turn:turn.test.invalid:3478?transport=udp",
                "turns:turn.test.invalid:5349?transport=tcp",
            ],
        )
        username = turn_server["username"]
        expires_at = int(username.split(":", 1)[0])
        now = int(time.time())
        self.assertGreaterEqual(expires_at, now + 899)
        self.assertLessEqual(expires_at, now + 900)

        expected_credential = base64.b64encode(
            hmac.new(
                b"unit-test-shared-secret",
                username.encode("utf-8"),
                hashlib.sha1,
            ).digest()
        ).decode("ascii")
        self.assertEqual(turn_server["credential"], expected_credential)
        self.assertNotIn("unit-test-shared-secret", str(response.data))

    def test_non_member_cannot_request_credentials(self):
        self.client.force_authenticate(user=self.outsider)

        response = self.client.get(self.url)

        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    @override_settings(TURN_ICE_SERVER_URLS=(), TURN_SHARED_SECRET="")
    def test_unconfigured_turn_returns_stun_only(self):
        self.client.force_authenticate(user=self.member)

        response = self.client.get(self.url)

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertFalse(response.data["relay_available"])
        self.assertEqual(response.data["expires_in"], 0)
        self.assertEqual(len(response.data["ice_servers"]), 1)
        self.assertEqual(
            response.data["ice_servers"][0]["urls"],
            ["stun:stun.test.invalid:3478"],
        )
