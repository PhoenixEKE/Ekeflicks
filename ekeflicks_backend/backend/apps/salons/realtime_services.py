from __future__ import annotations

import secrets
from typing import Any

from django.conf import settings
from django.core.cache import cache
from rest_framework.exceptions import PermissionDenied, ValidationError

from .models import Salon, SalonMember


TICKET_PREFIX = "salon:realtime:ticket:"


def _ticket_key(token: str) -> str:
    return f"{TICKET_PREFIX}{token}"


def _consumed_key(token: str) -> str:
    return f"{TICKET_PREFIX}consumed:{token}"


def require_realtime_member(
    *,
    salon: Salon,
    user: Any,
) -> None:
    if salon.status != Salon.STATUS_OPEN:
        raise ValidationError(
            {"salon": "This salon is closed."}
        )

    if salon.host_id == user.id:
        return

    if not SalonMember.objects.filter(
        salon=salon,
        user=user,
        left_at__isnull=True,
    ).exists():
        raise PermissionDenied(
            "You must be an active salon member."
        )


def create_realtime_ticket(
    *,
    salon: Salon,
    user: Any,
) -> str:
    require_realtime_member(
        salon=salon,
        user=user,
    )

    token = secrets.token_urlsafe(32)

    ttl = int(
        getattr(
            settings,
            "SALON_REALTIME_TICKET_TTL",
            60,
        )
    )

    cache.set(
        _ticket_key(token),
        {
            "salon_id": str(salon.pk),
            "user_id": str(user.pk),
        },
        timeout=ttl,
    )

    return token


def consume_realtime_ticket(
    *,
    token: str,
) -> dict[str, str] | None:
    if not token:
        return None

    payload = cache.get(
        _ticket_key(token)
    )

    if not payload:
        return None

    ttl = int(
        getattr(
            settings,
            "SALON_REALTIME_TICKET_TTL",
            60,
        )
    )

    first_consumer = cache.add(
        _consumed_key(token),
        "1",
        timeout=ttl,
    )

    if not first_consumer:
        return None

    cache.delete(
        _ticket_key(token)
    )

    return payload
