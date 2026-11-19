"""
G5-3I — Persistent social connection graph.

Security architecture:

    active Profile
        ↓
    SocialProfile
        ↓
    discoverability
        ↓
    block / mute / moderation gate
        ↓
    SocialConnection

PostgreSQL owns authorization and relationship state.
"""

from __future__ import annotations

from django.db import transaction
from django.db.models import Q
from django.utils import timezone
from rest_framework.exceptions import (
    NotFound,
    PermissionDenied,
    ValidationError,
)

from apps.recommendations.user_context import (
    resolve_active_profile,
)

from apps.notifications.social_notifications import (
    notify_connection_accepted,
    notify_connection_requested,
)

from .social_models import (
    SocialConnection,
    SocialProfile,
)
from .social_safety import (
    is_social_match_allowed,
)


SOCIAL_CONNECTION_VERSION = "g5_3i_v1"


def resolve_requester_social(*, user):
    profile = resolve_active_profile(
        user=user,
    )

    social, _ = SocialProfile.objects.get_or_create(
        profile=profile,
        defaults={
            "display_name": profile.name,
            "is_discoverable": False,
        },
    )

    return social


def resolve_target_social(*, profile_id):
    try:
        return (
            SocialProfile.objects
            .select_related(
                "profile",
                "profile__user",
            )
            .get(
                profile_id=profile_id,
                profile__is_active=True,
                profile__user__is_active=True,
            )
        )
    except SocialProfile.DoesNotExist as exc:
        raise NotFound(
            "Social profile not found."
        ) from exc


def _pair_query(*, left, right):
    return (
        Q(
            requester=left,
            target=right,
        )
        | Q(
            requester=right,
            target=left,
        )
    )


def ensure_connection_eligibility(
    *,
    requester_social,
    target_social,
):
    if requester_social.pk == target_social.pk:
        raise ValidationError(
            {
                "target_profile_id":
                    "You cannot connect with yourself."
            }
        )

    if not target_social.is_discoverable:
        raise NotFound(
            "Social profile not found."
        )

    if not is_social_match_allowed(
        requester_social=requester_social,
        candidate_social=target_social,
    ):
        raise PermissionDenied(
            "Social connection is not allowed."
        )


@transaction.atomic
def create_connection_request(
    *,
    requester_social,
    target_social,
):
    ensure_connection_eligibility(
        requester_social=requester_social,
        target_social=target_social,
    )

    existing = (
        SocialConnection.objects
        .select_for_update()
        .filter(
            _pair_query(
                left=requester_social,
                right=target_social,
            )
        )
        .order_by("-created_at")
        .first()
    )

    if existing is not None:
        if (
            existing.status
            == SocialConnection.STATUS_ACCEPTED
        ):
            raise ValidationError(
                {
                    "connection":
                        "Profiles are already connected."
                }
            )

        if (
            existing.status
            == SocialConnection.STATUS_PENDING
        ):
            if (
                existing.requester_id
                == requester_social.pk
            ):
                return existing

            raise ValidationError(
                {
                    "connection":
                        "A connection request is already pending."
                }
            )

        # Previous declined request:
        # reuse the row and restart a clean pending request.
        existing.requester = requester_social
        existing.target = target_social
        existing.status = (
            SocialConnection.STATUS_PENDING
        )
        existing.responded_at = None

        existing.save(
            update_fields=(
                "requester",
                "target",
                "status",
                "responded_at",
                "updated_at",
            )
        )

        notify_connection_requested(
            connection=existing,
        )

        return existing

    connection = SocialConnection.objects.create(
        requester=requester_social,
        target=target_social,
        status=SocialConnection.STATUS_PENDING,
    )

    notify_connection_requested(
        connection=connection,
    )

    return connection


@transaction.atomic
def accept_connection_request(
    *,
    connection,
    actor_social,
):
    locked = (
        SocialConnection.objects
        .select_for_update()
        .get(pk=connection.pk)
    )

    if locked.target_id != actor_social.pk:
        raise PermissionDenied(
            "Only the target profile may accept this request."
        )

    if locked.status != SocialConnection.STATUS_PENDING:
        raise ValidationError(
            {
                "connection":
                    "Connection request is not pending."
            }
        )

    ensure_connection_eligibility(
        requester_social=locked.requester,
        target_social=locked.target,
    )

    locked.status = SocialConnection.STATUS_ACCEPTED
    locked.responded_at = timezone.now()

    locked.save(
        update_fields=(
            "status",
            "responded_at",
            "updated_at",
        )
    )

    notify_connection_accepted(
        connection=locked,
    )

    return locked


@transaction.atomic
def decline_connection_request(
    *,
    connection,
    actor_social,
):
    locked = (
        SocialConnection.objects
        .select_for_update()
        .get(pk=connection.pk)
    )

    if locked.target_id != actor_social.pk:
        raise PermissionDenied(
            "Only the target profile may decline this request."
        )

    if locked.status != SocialConnection.STATUS_PENDING:
        raise ValidationError(
            {
                "connection":
                    "Connection request is not pending."
            }
        )

    locked.status = SocialConnection.STATUS_DECLINED
    locked.responded_at = timezone.now()

    locked.save(
        update_fields=(
            "status",
            "responded_at",
            "updated_at",
        )
    )

    return locked


@transaction.atomic
def remove_connection(
    *,
    connection,
    actor_social,
):
    locked = (
        SocialConnection.objects
        .select_for_update()
        .get(pk=connection.pk)
    )

    if actor_social.pk not in (
        locked.requester_id,
        locked.target_id,
    ):
        raise PermissionDenied(
            "You do not own this social relationship."
        )

    locked.delete()


def connection_queryset_for(*, social_profile):
    return (
        SocialConnection.objects
        .select_related(
            "requester",
            "requester__profile",
            "target",
            "target__profile",
        )
        .filter(
            Q(requester=social_profile)
            | Q(target=social_profile)
        )
        .order_by(
            "-created_at",
            "pk",
        )
    )


def accepted_connections_for(*, social_profile):
    return connection_queryset_for(
        social_profile=social_profile,
    ).filter(
        status=SocialConnection.STATUS_ACCEPTED,
    )
