from decimal import Decimal

from django.contrib.auth import get_user_model
from django.urls import reverse

from rest_framework import status
from rest_framework.test import APITestCase

from apps.salons.models import (
    Salon,
    SalonPlaybackState,
)
from apps.salons.services import (
    close_salon,
    create_salon,
    join_salon,
)


User = get_user_model()


class SalonPlaybackSyncTests(APITestCase):
    def setUp(self):
        self.host = User.objects.create_user(
            email="playback-host@example.com",
            password="StrongPass123!",
        )

        self.member = User.objects.create_user(
            email="playback-member@example.com",
            password="StrongPass123!",
        )

        self.outsider = User.objects.create_user(
            email="playback-outsider@example.com",
            password="StrongPass123!",
        )

        self.salon = create_salon(
            host=self.host,
            name="Sync Room",
            visibility=Salon.VISIBILITY_PUBLIC,
            capacity=6,
        )

        join_salon(
            salon=self.salon,
            user=self.member,
        )

        self.playback_url = reverse(
            "salon-playback",
            kwargs={"pk": self.salon.pk},
        )

        self.resync_url = reverse(
            "salon-resync",
            kwargs={"pk": self.salon.pk},
        )

    def test_playback_requires_authentication(self):
        response = self.client.get(
            self.playback_url,
        )

        self.assertIn(
            response.status_code,
            (
                status.HTTP_401_UNAUTHORIZED,
                status.HTTP_403_FORBIDDEN,
            ),
        )

    def test_member_can_read_initial_playback_state(self):
        self.client.force_authenticate(
            user=self.member,
        )

        response = self.client.get(
            self.playback_url,
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_200_OK,
        )
        self.assertEqual(
            response.data["position_ms"],
            0,
        )
        self.assertFalse(
            response.data["is_playing"],
        )
        self.assertEqual(
            response.data["sequence"],
            0,
        )

    def test_public_outsider_must_join_before_playback_access(self):
        self.client.force_authenticate(
            user=self.outsider,
        )

        response = self.client.get(
            self.playback_url,
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_403_FORBIDDEN,
        )

    def test_host_can_start_playback(self):
        self.client.force_authenticate(
            user=self.host,
        )

        response = self.client.patch(
            self.playback_url,
            {
                "expected_sequence": 0,
                "position_ms": 12500,
                "is_playing": True,
            },
            format="json",
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_200_OK,
        )

        self.assertEqual(
            response.data["position_ms"],
            12500,
        )
        self.assertTrue(
            response.data["is_playing"],
        )
        self.assertEqual(
            response.data["sequence"],
            1,
        )
        self.assertEqual(
            response.data["last_event"],
            SalonPlaybackState.EVENT_PLAY,
        )

    def test_member_cannot_control_playback(self):
        self.client.force_authenticate(
            user=self.member,
        )

        response = self.client.patch(
            self.playback_url,
            {
                "expected_sequence": 0,
                "position_ms": 5000,
                "is_playing": True,
            },
            format="json",
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_403_FORBIDDEN,
        )

    def test_sequence_increments_monotonically(self):
        self.client.force_authenticate(
            user=self.host,
        )

        first = self.client.patch(
            self.playback_url,
            {
                "expected_sequence": 0,
                "position_ms": 1000,
                "is_playing": True,
            },
            format="json",
        )

        self.assertEqual(
            first.status_code,
            status.HTTP_200_OK,
        )
        self.assertEqual(
            first.data["sequence"],
            1,
        )

        second = self.client.patch(
            self.playback_url,
            {
                "expected_sequence": 1,
                "position_ms": 4000,
            },
            format="json",
        )

        self.assertEqual(
            second.status_code,
            status.HTTP_200_OK,
        )
        self.assertEqual(
            second.data["sequence"],
            2,
        )

    def test_stale_sequence_is_rejected(self):
        self.client.force_authenticate(
            user=self.host,
        )

        first = self.client.patch(
            self.playback_url,
            {
                "expected_sequence": 0,
                "position_ms": 3000,
                "is_playing": True,
            },
            format="json",
        )

        self.assertEqual(
            first.status_code,
            status.HTTP_200_OK,
        )

        stale = self.client.patch(
            self.playback_url,
            {
                "expected_sequence": 0,
                "position_ms": 9000,
            },
            format="json",
        )

        self.assertEqual(
            stale.status_code,
            status.HTTP_400_BAD_REQUEST,
        )

        state = SalonPlaybackState.objects.get(
            salon=self.salon,
        )

        self.assertEqual(
            state.position_ms,
            3000,
        )
        self.assertEqual(
            state.sequence,
            1,
        )

    def test_host_can_pause_playback(self):
        self.client.force_authenticate(
            user=self.host,
        )

        start = self.client.patch(
            self.playback_url,
            {
                "expected_sequence": 0,
                "position_ms": 2000,
                "is_playing": True,
            },
            format="json",
        )

        pause = self.client.patch(
            self.playback_url,
            {
                "expected_sequence": start.data["sequence"],
                "position_ms": 5000,
                "is_playing": False,
            },
            format="json",
        )

        self.assertEqual(
            pause.status_code,
            status.HTTP_200_OK,
        )
        self.assertFalse(
            pause.data["is_playing"],
        )
        self.assertEqual(
            pause.data["last_event"],
            SalonPlaybackState.EVENT_PAUSE,
        )

    def test_host_can_change_playback_rate(self):
        self.client.force_authenticate(
            user=self.host,
        )

        response = self.client.patch(
            self.playback_url,
            {
                "expected_sequence": 0,
                "playback_rate": "1.25",
            },
            format="json",
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_200_OK,
        )

        state = SalonPlaybackState.objects.get(
            salon=self.salon,
        )

        self.assertEqual(
            state.playback_rate,
            Decimal("1.25"),
        )

    def test_invalid_playback_rate_is_rejected(self):
        self.client.force_authenticate(
            user=self.host,
        )

        response = self.client.patch(
            self.playback_url,
            {
                "expected_sequence": 0,
                "playback_rate": "3.00",
            },
            format="json",
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_400_BAD_REQUEST,
        )

    def test_empty_playback_update_is_rejected(self):
        self.client.force_authenticate(
            user=self.host,
        )

        response = self.client.patch(
            self.playback_url,
            {
                "expected_sequence": 0,
            },
            format="json",
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_400_BAD_REQUEST,
        )

    def test_member_resync_receives_authoritative_state(self):
        self.client.force_authenticate(
            user=self.host,
        )

        update = self.client.patch(
            self.playback_url,
            {
                "expected_sequence": 0,
                "position_ms": 15000,
                "is_playing": False,
            },
            format="json",
        )

        self.assertEqual(
            update.status_code,
            status.HTTP_200_OK,
        )

        self.client.force_authenticate(
            user=self.member,
        )

        response = self.client.get(
            self.resync_url,
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_200_OK,
        )

        self.assertEqual(
            response.data["position_ms"],
            15000,
        )
        self.assertEqual(
            response.data["sequence"],
            1,
        )
        self.assertIn(
            "server_time",
            response.data,
        )
        self.assertIn(
            "effective_position_ms",
            response.data,
        )

    def test_closed_salon_rejects_playback_access(self):
        close_salon(
            salon=self.salon,
            user=self.host,
        )

        self.client.force_authenticate(
            user=self.host,
        )

        response = self.client.get(
            self.playback_url,
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_400_BAD_REQUEST,
        )

    def test_routes_are_stable(self):
        self.assertEqual(
            self.playback_url,
            f"/api/v1/salons/{self.salon.pk}/playback/",
        )

        self.assertEqual(
            self.resync_url,
            f"/api/v1/salons/{self.salon.pk}/resync/",
        )
