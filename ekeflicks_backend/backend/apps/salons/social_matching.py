from __future__ import annotations

from dataclasses import dataclass
from typing import Any

from django.contrib.auth import get_user_model
from django.db.models import Q

from apps.profiles.social_models import (
    SocialConnection,
    SocialProfile,
)
from apps.profiles.social_safety import (
    is_social_match_allowed,
)
from core.models.profiles import Profile

from .eke_social_matching import (
    build_social_context,
    calculate_social_compatibility,
)
from .models import Salon, SalonMember


User = get_user_model()

MAX_MATCH_RESULTS = 20


@dataclass(frozen=True)
class SocialMatch:
    user: Any
    profile: Profile
    score: int
    reasons: tuple[str, ...]


def _active_profile(user):
    return (
        Profile.objects
        .filter(
            user=user,
            is_active=True,
        )
        .order_by(
            "created_at",
            "pk",
        )
        .first()
    )


def _eligible_users(
    *,
    salon,
    requester,
):
    """
    PostgreSQL owns social eligibility.

    EKE IA receives only candidates that have already passed the
    hard account/profile/Salon eligibility boundary.
    """

    excluded_user_ids = set(
        SalonMember.objects
        .filter(
            salon=salon,
            left_at__isnull=True,
        )
        .values_list(
            "user_id",
            flat=True,
        )
    )

    excluded_user_ids.add(
        requester.pk
    )

    active_profile_user_ids = (
        Profile.objects
        .filter(
            is_active=True,
        )
        .values_list(
            "user_id",
            flat=True,
        )
    )

    return (
        User.objects
        .filter(
            is_active=True,
            pk__in=active_profile_user_ids,
        )
        .exclude(
            pk__in=excluded_user_ids,
        )
        .distinct()
        .order_by("pk")
    )


def _accepted_connection_user_ids(
    *,
    requester_social,
):
    connections = (
        SocialConnection.objects
        .filter(
            Q(requester=requester_social)
            | Q(target=requester_social),
            status=SocialConnection.STATUS_ACCEPTED,
        )
        .values_list(
            "requester__profile__user_id",
            "target__profile__user_id",
        )
    )

    user_ids = set()

    for requester_id, target_id in connections:
        if requester_id != requester_social.profile.user_id:
            user_ids.add(requester_id)

        if target_id != requester_social.profile.user_id:
            user_ids.add(target_id)

    return user_ids


def _salon_genre_slugs(salon):
    if salon.content_id is None:
        return frozenset()

    return frozenset(
        salon.content.genres.values_list(
            "slug",
            flat=True,
        )
    )


def match_users_for_salon(
    *,
    salon,
    requester,
    limit=10,
):
    if salon.status != Salon.STATUS_OPEN:
        return tuple()

    limit = max(
        1,
        min(
            int(limit),
            MAX_MATCH_RESULTS,
        ),
    )

    requester_profile = _active_profile(
        requester
    )

    if requester_profile is None:
        return tuple()

    try:
        requester_social = (
            requester_profile.social_profile
        )
    except SocialProfile.DoesNotExist:
        return tuple()

    requester_context = build_social_context(
        user=requester,
        profile=requester_profile,
    )

    connected_user_ids = (
        _accepted_connection_user_ids(
            requester_social=requester_social,
        )
    )

    salon_genres = (
        _salon_genre_slugs(salon)
        if salon.mode == Salon.MODE_THEMATIC
        else frozenset()
    )

    if (
        salon.mode == Salon.MODE_THEMATIC
        and not salon_genres
    ):
        return tuple()

    results = []

    for candidate in _eligible_users(
        salon=salon,
        requester=requester,
    ):
        candidate_profile = _active_profile(
            candidate
        )

        if candidate_profile is None:
            continue

        # Privacy + safety are hard PostgreSQL gates.
        # Rejected candidates never reach EKE IA behavioral processing.
        try:
            candidate_social = (
                candidate_profile.social_profile
            )
        except SocialProfile.DoesNotExist:
            continue

        if not candidate_social.is_discoverable:
            continue

        if not is_social_match_allowed(
            requester_social=requester_social,
            candidate_social=candidate_social,
        ):
            continue

        candidate_context = build_social_context(
            user=candidate,
            profile=candidate_profile,
        )

        is_connected = (
            candidate.pk
            in connected_user_ids
        )

        if (
            salon.mode == Salon.MODE_SOCIAL
            and is_connected
        ):
            continue

        if (
            salon.mode == Salon.MODE_FRIENDS
            and not is_connected
        ):
            continue

        if (
            salon.mode == Salon.MODE_THEMATIC
            and is_connected
        ):
            continue

        compatibility = (
            calculate_social_compatibility(
                requester_context=requester_context,
                candidate_context=candidate_context,
            )
        )

        if (
            salon.mode == Salon.MODE_THEMATIC
            and not (
                set(
                    compatibility.common_genre_slugs
                )
                & salon_genres
            )
        ):
            continue

        results.append(
            SocialMatch(
                user=candidate,
                profile=candidate_profile,
                score=compatibility.score,
                reasons=compatibility.reasons,
            )
        )

    results.sort(
        key=lambda item: (
            -item.score,
            str(item.user.pk),
        )
    )

    return tuple(
        results[:limit]
    )
