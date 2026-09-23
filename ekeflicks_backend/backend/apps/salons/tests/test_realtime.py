from django.contrib.auth import get_user_model
from django.core.cache import cache
from django.test import override_settings
from django.urls import reverse

from channels.layers import InMemoryChannelLayer
from channels.testing import WebsocketCommunicator
from rest_framework import status
from rest_framework.test import APITransactionTestCase

from apps.salons.models import (
    Salon,
    SalonPlaybackState,
)
from apps.salons.realtime_services import (
    create_realtime_ticket,
)
from apps.salons.services import (
    close_salon,
    create_salon,
    join_salon,
)
from config.asgi import application


User = get_user_model()


TEST_CHANNEL_LAYERS = {
    "default": {
        "BACKEND": (
            "channels.layers."
            "InMemoryChannelLayer"
        ),
    },
}

TEST_CACHES = {
    "default": {
        "BACKEND": (
            "django.core.cache.backends."
            "locmem.LocMemCache"
        ),
        "LOCATION": "g5-3c-tests",
    },
}


@override_settings(
    CHANNEL_LAYERS=TEST_CHANNEL_LAYERS,
    CACHES=TEST_CACHES,
    SALON_REALTIME_TICKET_TTL=60,
)
class SalonRealtimeTests(APITransactionTestCase):
    def setUp(self):
        cache.clear()

        self.host = User.objects.create_user(
            email="rt-host@example.com",
            password="StrongPass123!",
        )

        self.member = User.objects.create_user(
            email="rt-member@example.com",
            password="StrongPass123!",
        )

        self.outsider = User.objects.create_user(
            email="rt-outsider@example.com",
            password="StrongPass123!",
        )

        self.salon = create_salon(
            host=self.host,
            name="Realtime Room",
            visibility=Salon.VISIBILITY_PUBLIC,
            capacity=6,
        )

        join_salon(
            salon=self.salon,
            user=self.member,
        )

        self.ticket_url = reverse(
            "salon-realtime-ticket",
            kwargs={
                "pk": self.salon.pk,
            },
        )

    def test_ticket_requires_authentication(self):
        response = self.client.post(
            self.ticket_url,
            {},
            format="json",
        )

        self.assertIn(
            response.status_code,
            (
                status.HTTP_401_UNAUTHORIZED,
                status.HTTP_403_FORBIDDEN,
            ),
        )

    def test_active_member_can_request_ticket(self):
        self.client.force_authenticate(
            user=self.member,
        )

        response = self.client.post(
            self.ticket_url,
            {},
            format="json",
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_200_OK,
        )

        self.assertTrue(
            response.data["ticket"]
        )

        self.assertEqual(
            response.data["expires_in"],
            60,
        )

    def test_outsider_cannot_request_ticket(self):
        self.client.force_authenticate(
            user=self.outsider,
        )

        response = self.client.post(
            self.ticket_url,
            {},
            format="json",
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_403_FORBIDDEN,
        )

    async def _connect(
        self,
        user,
    ):
        ticket = await self._ticket(
            user
        )

        communicator = WebsocketCommunicator(
            application,
            (
                f"/ws/salons/"
                f"{self.salon.pk}/"
                f"?ticket={ticket}"
            ),
        )

        connected, _ = (
            await communicator.connect()
        )

        return communicator, connected

    async def _ticket(
        self,
        user,
    ):
        from asgiref.sync import sync_to_async

        return await sync_to_async(
            create_realtime_ticket,
            thread_sensitive=True,
        )(
            salon=self.salon,
            user=user,
        )

    async def test_member_websocket_connects_and_receives_state(
        self,
    ):
        communicator, connected = (
            await self._connect(
                self.member
            )
        )

        self.assertTrue(
            connected
        )

        ready = (
            await communicator.receive_json_from()
        )

        self.assertEqual(
            ready["type"],
            "connection.ready",
        )

        self.assertEqual(
            ready["playback"]["sequence"],
            0,
        )

        await communicator.disconnect()

    async def test_ticket_is_single_use(self):
        ticket = await self._ticket(
            self.member
        )

        path = (
            f"/ws/salons/{self.salon.pk}/"
            f"?ticket={ticket}"
        )

        first = WebsocketCommunicator(
            application,
            path,
        )

        connected, _ = await first.connect()

        self.assertTrue(
            connected
        )

        await first.receive_json_from()

        second = WebsocketCommunicator(
            application,
            path,
        )

        second_connected, _ = (
            await second.connect()
        )

        self.assertFalse(
            second_connected
        )

        await first.disconnect()

    async def test_host_playback_update_is_broadcast(
        self,
    ):
        host_ws, host_connected = (
            await self._connect(
                self.host
            )
        )

        member_ws, member_connected = (
            await self._connect(
                self.member
            )
        )

        self.assertTrue(
            host_connected
        )
        self.assertTrue(
            member_connected
        )

        await host_ws.receive_json_from()
        await member_ws.receive_json_from()

        # Presence is deterministic:
        # - host receives its own join
        # - host receives member join
        # - member receives its own join
        host_presence_1 = (
            await host_ws.receive_json_from()
        )
        host_presence_2 = (
            await host_ws.receive_json_from()
        )
        member_presence = (
            await member_ws.receive_json_from()
        )

        self.assertEqual(
            host_presence_1["type"],
            "presence.joined",
        )
        self.assertEqual(
            host_presence_2["type"],
            "presence.joined",
        )
        self.assertEqual(
            member_presence["type"],
            "presence.joined",
        )

        await host_ws.send_json_to(
            {
                "type": "playback.update",
                "playback": {
                    "expected_sequence": 0,
                    "position_ms": 12000,
                    "is_playing": True,
                },
            }
        )

        host_event = (
            await host_ws.receive_json_from(
                timeout=1
            )
        )

        member_event = (
            await member_ws.receive_json_from(
                timeout=1
            )
        )

        self.assertEqual(
            host_event["type"],
            "playback.state",
        )

        self.assertEqual(
            member_event["type"],
            "playback.state",
        )

        self.assertEqual(
            member_event["playback"][
                "sequence"
            ],
            1,
        )

        self.assertEqual(
            member_event["playback"][
                "position_ms"
            ],
            12000,
        )

        await host_ws.disconnect()
        await member_ws.disconnect()

    async def test_member_cannot_control_playback(
        self,
    ):
        ws, connected = await self._connect(
            self.member
        )

        self.assertTrue(
            connected
        )

        await ws.receive_json_from()

        await ws.send_json_to(
            {
                "type": "playback.update",
                "playback": {
                    "expected_sequence": 0,
                    "position_ms": 9000,
                    "is_playing": True,
                },
            }
        )

        response = await ws.receive_json_from(
            timeout=1
        )

        # A presence event can arrive before the error.
        if response["type"].startswith(
            "presence."
        ):
            response = (
                await ws.receive_json_from(
                    timeout=1
                )
            )

        self.assertEqual(
            response["type"],
            "error",
        )

        self.assertEqual(
            response["code"],
            "permission_denied",
        )

        await ws.disconnect()

    async def test_webrtc_offer_is_relayed_only_to_target(
        self,
    ):
        host_ws, _ = await self._connect(
            self.host
        )

        member_ws, _ = await self._connect(
            self.member
        )

        await host_ws.receive_json_from()
        await member_ws.receive_json_from()

        host_presence_1 = (
            await host_ws.receive_json_from()
        )
        host_presence_2 = (
            await host_ws.receive_json_from()
        )
        member_presence = (
            await member_ws.receive_json_from()
        )

        self.assertEqual(
            host_presence_1["type"],
            "presence.joined",
        )
        self.assertEqual(
            host_presence_2["type"],
            "presence.joined",
        )
        self.assertEqual(
            member_presence["type"],
            "presence.joined",
        )

        await host_ws.send_json_to(
            {
                "type": "webrtc.signal",
                "signal_type": "offer",
                "target_user_id": str(
                    self.member.pk
                ),
                "payload": {
                    "sdp": "test-offer",
                },
            }
        )

        event = (
            await member_ws.receive_json_from(
                timeout=1
            )
        )

        self.assertEqual(
            event["type"],
            "webrtc.signal",
        )

        self.assertEqual(
            event["signal_type"],
            "offer",
        )

        self.assertEqual(
            event["sender_user_id"],
            str(self.host.pk),
        )

        self.assertEqual(
            event["payload"]["sdp"],
            "test-offer",
        )

        await host_ws.disconnect()
        await member_ws.disconnect()

    def test_closed_salon_refuses_new_ticket(self):
        close_salon(
            salon=self.salon,
            user=self.host,
        )

        self.client.force_authenticate(
            user=self.host,
        )

        response = self.client.post(
            self.ticket_url,
            {},
            format="json",
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_400_BAD_REQUEST,
        )
