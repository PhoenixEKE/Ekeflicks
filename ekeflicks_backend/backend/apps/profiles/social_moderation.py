"""
G5-3H — Social moderation domain service.

PostgreSQL remains authoritative for moderation and eligibility.
EKE IA must never evaluate a socially ineligible candidate.
"""

from django.db import transaction
from django.utils import timezone

from .social_models import (
    SocialModeration,
    SocialReputation,
)


SOCIAL_MODERATION_VERSION = "g5_3h_v1"

REPUTATION_ACTIVE = 100
REPUTATION_LIMITED_MAX = 60
REPUTATION_SUSPENDED_MAX = 20


def ensure_social_moderation(profile):
    moderation, _ = SocialModeration.objects.get_or_create(
        profile=profile,
    )
    return moderation


def is_socially_moderated(profile):
    """
    True when the profile must be excluded from social discovery/matching.
    """

    moderation = (
        SocialModeration.objects
        .filter(profile=profile)
        .only("status")
        .first()
    )

    if moderation is None:
        return False

    return moderation.status in {
        SocialModeration.STATUS_LIMITED,
        SocialModeration.STATUS_SUSPENDED,
    }


def is_social_moderation_allowed(profile):
    return not is_socially_moderated(profile)


def _reputation_for(profile):
    reputation, _ = SocialReputation.objects.get_or_create(
        profile=profile,
        defaults={"score": REPUTATION_ACTIVE},
    )
    return reputation


@transaction.atomic
def moderate_social_profile(
    *,
    profile,
    status,
    reviewer,
    reason="",
):
    if status not in {
        SocialModeration.STATUS_ACTIVE,
        SocialModeration.STATUS_LIMITED,
        SocialModeration.STATUS_SUSPENDED,
    }:
        raise ValueError("Invalid social moderation status.")

    if not reviewer or not reviewer.is_authenticated:
        raise PermissionError("Authenticated reviewer required.")

    if not reviewer.is_staff:
        raise PermissionError("Staff reviewer required.")

    moderation, _ = (
        SocialModeration.objects
        .select_for_update()
        .get_or_create(profile=profile)
    )

    moderation.status = status
    moderation.reason = (reason or "").strip()[:500]
    moderation.reviewed_by = reviewer
    moderation.reviewed_at = timezone.now()

    moderation.save(
        update_fields=[
            "status",
            "reason",
            "reviewed_by",
            "reviewed_at",
            "updated_at",
        ]
    )

    reputation = _reputation_for(profile)

    if status == SocialModeration.STATUS_ACTIVE:
        # Reactivation does not fabricate a perfect reputation.
        # It only guarantees a valid bounded score.
        reputation.score = max(
            0,
            min(100, reputation.score),
        )

    elif status == SocialModeration.STATUS_LIMITED:
        reputation.score = min(
            reputation.score,
            REPUTATION_LIMITED_MAX,
        )

    elif status == SocialModeration.STATUS_SUSPENDED:
        reputation.score = min(
            reputation.score,
            REPUTATION_SUSPENDED_MAX,
        )

    reputation.save(
        update_fields=[
            "score",
            "updated_at",
        ]
    )

    return moderation, reputation
