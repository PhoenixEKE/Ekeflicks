"""
G5-3L — EKE Salon facilitation / icebreakers.

Icebreakers are calculated on demand.

No persistence.
No automatic message publication.
No private user behavioral data is exposed.
"""

from __future__ import annotations

from dataclasses import dataclass

from rest_framework.exceptions import (
    PermissionDenied,
    ValidationError,
)

from .models import Salon, SalonMember


SALON_FACILITATION_VERSION = "g5_3l_v1"

MAX_ICEBREAKERS = 4


@dataclass(frozen=True)
class SalonIcebreaker:
    id: str
    text: str
    kind: str


@dataclass(frozen=True)
class SalonFacilitation:
    version: str
    context_level: str
    icebreakers: tuple[SalonIcebreaker, ...]


def _clean_public_text(value, *, fallback):
    """
    Normalize public Salon/content text before it enters a prompt.

    This helper deliberately receives only collective Salon context,
    never user email/profile/history data.
    """

    value = " ".join(
        str(value or "").split()
    ).strip()

    if not value:
        return fallback

    return value[:120]


def _require_active_member(*, salon, user):
    if salon.status != Salon.STATUS_OPEN:
        raise ValidationError(
            "Salon is not open."
        )

    if not SalonMember.objects.filter(
        salon=salon,
        user=user,
        left_at__isnull=True,
    ).exists():
        raise PermissionDenied(
            "Active Salon membership required."
        )


def _content_title(salon):
    content = getattr(
        salon,
        "content",
        None,
    )

    if content is None:
        return ""

    return _clean_public_text(
        getattr(content, "title", ""),
        fallback="",
    )


def build_salon_icebreakers(
    *,
    salon,
    user,
):
    """
    Build deterministic, privacy-safe conversation starters.

    Authorization:
        authenticated API layer +
        active Salon membership here.

    Context:
        collective Salon metadata only.

    The service never posts a message on behalf of a participant.
    """

    _require_active_member(
        salon=salon,
        user=user,
    )

    salon_name = _clean_public_text(
        salon.name,
        fallback="ce Salon",
    )

    content_title = _content_title(
        salon
    )

    if content_title:
        context_level = "content"

        items = (
            SalonIcebreaker(
                id="content_first_impression",
                text=(
                    f"Quelle est votre première impression "
                    f"sur « {content_title} » ?"
                ),
                kind="content",
            ),
            SalonIcebreaker(
                id="content_highlight",
                text=(
                    f"Quel moment de « {content_title} » "
                    f"vous a le plus marqué jusqu’ici ?"
                ),
                kind="content",
            ),
            SalonIcebreaker(
                id="content_prediction",
                text=(
                    f"Que pensez-vous qu’il va se passer "
                    f"ensuite dans « {content_title} » ?"
                ),
                kind="content",
            ),
            SalonIcebreaker(
                id="content_recommendation",
                text=(
                    f"À qui recommanderiez-vous "
                    f"« {content_title} » et pourquoi ?"
                ),
                kind="content",
            ),
        )
    else:
        context_level = "salon"

        items = (
            SalonIcebreaker(
                id="salon_current_watch",
                text=(
                    "Quel film ou quelle série "
                    "vous a récemment marqué ?"
                ),
                kind="salon",
            ),
            SalonIcebreaker(
                id="salon_recommendation",
                text=(
                    "Quel contenu recommanderiez-vous "
                    "au groupe en ce moment ?"
                ),
                kind="salon",
            ),
            SalonIcebreaker(
                id="salon_genre",
                text=(
                    "Quel genre choisissez-vous "
                    "presque toujours quand vous hésitez ?"
                ),
                kind="salon",
            ),
            SalonIcebreaker(
                id="salon_expectation",
                text=(
                    f"Qu’aimeriez-vous découvrir ou "
                    f"partager dans « {salon_name} » ?"
                ),
                kind="salon",
            ),
        )

    return SalonFacilitation(
        version=SALON_FACILITATION_VERSION,
        context_level=context_level,
        icebreakers=tuple(
            items[:MAX_ICEBREAKERS]
        ),
    )
