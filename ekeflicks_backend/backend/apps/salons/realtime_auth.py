from __future__ import annotations

from urllib.parse import parse_qs

from channels.db import database_sync_to_async
from django.contrib.auth import get_user_model
from django.contrib.auth.models import AnonymousUser

from .models import Salon, SalonMember
from .realtime_services import consume_realtime_ticket


@database_sync_to_async
def _resolve_ticket(
    token: str,
    salon_id: str,
):
    payload = consume_realtime_ticket(
        token=token,
    )

    if not payload:
        return AnonymousUser()

    if payload.get("salon_id") != str(salon_id):
        return AnonymousUser()

    User = get_user_model()

    try:
        user = User.objects.get(
            pk=payload["user_id"],
        )
    except User.DoesNotExist:
        return AnonymousUser()

    try:
        salon = Salon.objects.get(
            pk=salon_id,
            status=Salon.STATUS_OPEN,
        )
    except Salon.DoesNotExist:
        return AnonymousUser()

    if salon.host_id == user.pk:
        return user

    active = SalonMember.objects.filter(
        salon=salon,
        user=user,
        left_at__isnull=True,
    ).exists()

    if not active:
        return AnonymousUser()

    return user


class SalonTicketAuthMiddleware:
    def __init__(self, app):
        self.app = app

    async def __call__(
        self,
        scope,
        receive,
        send,
    ):
        scope = dict(scope)

        query = parse_qs(
            scope.get(
                "query_string",
                b"",
            ).decode()
        )

        token = (
            query.get("ticket", [""])[0]
        )

        salon_id = (
            scope.get(
                "url_route",
                {},
            )
            .get(
                "kwargs",
                {},
            )
            .get("salon_id")
        )

        if token and salon_id:
            scope["user"] = await _resolve_ticket(
                token,
                str(salon_id),
            )
        else:
            scope["user"] = AnonymousUser()

        return await self.app(
            scope,
            receive,
            send,
        )
