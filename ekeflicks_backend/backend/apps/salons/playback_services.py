from __future__ import annotations

from typing import Any

from django.db import transaction
from rest_framework.exceptions import PermissionDenied, ValidationError

from .models import (
    Salon,
    SalonMember,
    SalonPlaybackState,
)


def _require_open_salon(salon: Salon) -> None:
    if salon.status != Salon.STATUS_OPEN:
        raise ValidationError(
            {"salon": "This salon is closed."}
        )


def _require_active_member(
    *,
    salon: Salon,
    user: Any,
) -> None:
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


def get_playback_state(
    *,
    salon: Salon,
    user: Any,
) -> SalonPlaybackState:
    _require_open_salon(salon)

    _require_active_member(
        salon=salon,
        user=user,
    )

    state, _ = SalonPlaybackState.objects.get_or_create(
        salon=salon,
    )

    return state


@transaction.atomic
def update_playback_state(
    *,
    salon: Salon,
    user: Any,
    expected_sequence: int,
    position_ms: int | None = None,
    is_playing: bool | None = None,
    playback_rate: Any | None = None,
    event_type: str | None = None,
) -> SalonPlaybackState:
    salon = Salon.objects.select_for_update().get(
        pk=salon.pk,
    )

    _require_open_salon(salon)

    if salon.host_id != user.id:
        raise PermissionDenied(
            "Only the salon host can control playback."
        )

    state, _ = SalonPlaybackState.objects.select_for_update().get_or_create(
        salon=salon,
    )

    if state.sequence != expected_sequence:
        raise ValidationError(
            {
                "expected_sequence": (
                    "Playback state is stale. "
                    f"Expected current sequence {state.sequence}."
                ),
                "current_sequence": state.sequence,
            }
        )

    if position_ms is not None:
        state.position_ms = position_ms

    if is_playing is not None:
        state.is_playing = is_playing

    if playback_rate is not None:
        state.playback_rate = playback_rate

    if event_type:
        state.last_event = event_type
    elif is_playing is True:
        state.last_event = SalonPlaybackState.EVENT_PLAY
    elif is_playing is False:
        state.last_event = SalonPlaybackState.EVENT_PAUSE
    elif position_ms is not None:
        state.last_event = SalonPlaybackState.EVENT_SEEK
    elif playback_rate is not None:
        state.last_event = SalonPlaybackState.EVENT_RATE
    else:
        state.last_event = SalonPlaybackState.EVENT_SYNC

    state.sequence += 1
    state.updated_by = user

    state.save(
        update_fields=(
            "position_ms",
            "is_playing",
            "playback_rate",
            "sequence",
            "last_event",
            "updated_by",
            "updated_at",
        )
    )

    return state
