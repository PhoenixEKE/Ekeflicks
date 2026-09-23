from asgiref.sync import sync_to_async
from channels.testing import WebsocketCommunicator
from django.contrib.auth import get_user_model
from django.core.cache import cache
from django.test import override_settings
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITransactionTestCase

from apps.salons.models import (
    Salon,
    SalonMessage,
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
        "LOCATION": "g5-3n-tests",
    },
}


@override_settings(
    CHANNEL_LAYERS=TEST_CHANNEL_LAYERS,
    CACHES=TEST_CACHES,
    SALON_REALTIME_TICKET_TTL=60,
)
class SalonInteractionTests(
    APITransactionTestCase
):
    def setUp(self):
        cache.clear()

        self.host = User.objects.create_user(
            email="n-host@example.com",
            password="StrongPass123!",
        )

        self.member = User.objects.create_user(
            email="n-member@example.com",
            password="StrongPass123!",
        )

        self.outsider = User.objects.create_user(
            email="n-outsider@example.com",
            password="StrongPass123!",
        )

        self.salon = create_salon(
            host=self.host,
            name="G5-3N Room",
            visibility=Salon.VISIBILITY_PUBLIC,
            capacity=6,
        )

        join_salon(
            salon=self.salon,
            user=self.member,
        )

    async def _ticket(
        self,
        user,
    ):
        return await sync_to_async(
            create_realtime_ticket,
            thread_sensitive=True,
        )(
            salon=self.salon,
            user=user,
        )

    async def _connect(
        self,
        user,
    ):
        ticket = await self._ticket(
            user
        )

        ws = WebsocketCommunicator(
            application,
            (
                f"/ws/salons/"
                f"{self.salon.pk}/"
                f"?ticket={ticket}"
            ),
        )

        connected, _ = await ws.connect()

        self.assertTrue(connected)

        ready = await ws.receive_json_from()

        self.assertEqual(
            ready["type"],
            "connection.ready",
        )

        presence = await ws.receive_json_from()

        self.assertEqual(
            presence["type"],
            "presence.joined",
        )

        return ws

    def test_active_member_can_read_history(self):
        SalonMessage.objects.create(
            salon=self.salon,
            author=self.host,
            text="Hello",
        )

        self.client.force_authenticate(
            user=self.member,
        )

        url = reverse(
            "salon-messages",
            kwargs={
                "pk": self.salon.pk,
            },
        )

        response = self.client.get(url)

        self.assertEqual(
            response.status_code,
            status.HTTP_200_OK,
        )

        self.assertEqual(
            response.data["results"][0]["text"],
            "Hello",
        )

    def test_outsider_cannot_read_history(self):
        self.client.force_authenticate(
            user=self.outsider,
        )

        url = reverse(
            "salon-messages",
            kwargs={
                "pk": self.salon.pk,
            },
        )

        response = self.client.get(url)

        self.assertEqual(
            response.status_code,
            status.HTTP_403_FORBIDDEN,
        )

    def test_closed_salon_history_is_rejected(self):
        close_salon(
            salon=self.salon,
            user=self.host,
        )

        self.client.force_authenticate(
            user=self.host,
        )

        url = reverse(
            "salon-messages",
            kwargs={
                "pk": self.salon.pk,
            },
        )

        response = self.client.get(url)

        self.assertEqual(
            response.status_code,
            status.HTTP_400_BAD_REQUEST,
        )

    async def test_chat_message_is_persisted_and_broadcast(
        self,
    ):
        host_ws = await self._connect(
            self.host
        )

        member_ws = await self._connect(
            self.member
        )

        joined = await host_ws.receive_json_from()

        self.assertEqual(
            joined["type"],
            "presence.joined",
        )

        await member_ws.send_json_to(
            {
                "type": "chat.send",
                "text": "  Bonjour Salon  ",
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
            "chat.message",
        )

        self.assertEqual(
            member_event["type"],
            "chat.message",
        )

        self.assertEqual(
            host_event["message"]["text"],
            "Bonjour Salon",
        )

        self.assertEqual(
            host_event["message"]["author_id"],
            str(self.member.pk),
        )

        exists = await sync_to_async(
            SalonMessage.objects.filter(
                salon=self.salon,
                author=self.member,
                text="Bonjour Salon",
            ).exists,
            thread_sensitive=True,
        )()

        self.assertTrue(exists)

        await host_ws.disconnect()
        await member_ws.disconnect()

    async def test_blank_chat_message_is_rejected(
        self,
    ):
        ws = await self._connect(
            self.member
        )

        await ws.send_json_to(
            {
                "type": "chat.send",
                "text": "   ",
            }
        )

        response = await ws.receive_json_from(
            timeout=1
        )

        self.assertEqual(
            response["type"],
            "error",
        )

        self.assertEqual(
            response["code"],
            "invalid_event",
        )

        count = await sync_to_async(
            SalonMessage.objects.count,
            thread_sensitive=True,
        )()

        self.assertEqual(count, 0)

        await ws.disconnect()

    async def test_chat_message_over_1000_chars_is_rejected(
        self,
    ):
        ws = await self._connect(
            self.member
        )

        await ws.send_json_to(
            {
                "type": "chat.send",
                "text": "x" * 1001,
            }
        )

        response = await ws.receive_json_from(
            timeout=1
        )

        self.assertEqual(
            response["type"],
            "error",
        )

        self.assertEqual(
            response["code"],
            "invalid_event",
        )

        count = await sync_to_async(
            SalonMessage.objects.count,
            thread_sensitive=True,
        )()

        self.assertEqual(count, 0)

        await ws.disconnect()

    async def test_reaction_is_broadcast_and_not_persisted(
        self,
    ):
        host_ws = await self._connect(
            self.host
        )

        member_ws = await self._connect(
            self.member
        )

        joined = await host_ws.receive_json_from()

        self.assertEqual(
            joined["type"],
            "presence.joined",
        )

        before = await sync_to_async(
            SalonMessage.objects.count,
            thread_sensitive=True,
        )()

        await member_ws.send_json_to(
            {
                "type": "reaction.send",
                "reaction": "fire",
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
            "reaction.received",
        )

        self.assertEqual(
            member_event["type"],
            "reaction.received",
        )

        self.assertEqual(
            host_event["reaction"],
            "fire",
        )

        self.assertEqual(
            host_event["user_id"],
            str(self.member.pk),
        )

        after = await sync_to_async(
            SalonMessage.objects.count,
            thread_sensitive=True,
        )()

        self.assertEqual(
            before,
            after,
        )

        await host_ws.disconnect()
        await member_ws.disconnect()

    async def test_invalid_reaction_is_rejected(
        self,
    ):
        ws = await self._connect(
            self.member
        )

        await ws.send_json_to(
            {
                "type": "reaction.send",
                "reaction": "invalid",
            }
        )

        response = await ws.receive_json_from(
            timeout=1
        )

        self.assertEqual(
            response["type"],
            "error",
        )

        self.assertEqual(
            response["code"],
            "invalid_event",
        )

        await ws.disconnect()
