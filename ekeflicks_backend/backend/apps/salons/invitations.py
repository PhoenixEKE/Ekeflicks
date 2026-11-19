"""
G5-3J — Social Salon invitations.

Contract:
- only the active Salon host may invite;
- invitee must be an accepted SocialConnection;
- social safety remains authoritative;
- no self invitation;
- no duplicate pending invitation;
- no invitation to an active member;
- accepting delegates membership creation to join_salon();
- Salon capacity/status remain authoritative in the existing Salon service;
- notifications are intentionally deferred to G5-3K.
"""

from django.core.exceptions import ValidationError
from django.db import transaction
from django.db.models import Q
from django.utils import timezone

from apps.notifications.social_notifications import (
    notify_salon_invitation_accepted,
    notify_salon_invitation_received,
)

from apps.profiles.social_models import (
    SocialConnection,
    SocialProfile,
)
from apps.profiles.social_safety import (
    is_social_match_allowed,
)

from .models import (
    Salon,
    SalonInvitation,
    SalonMember,
)
from .services import join_salon


SALON_INVITATION_VERSION = "g5_3j_v1"


def _social_profile_for_user(user):
    profile = (
        user.profiles
        .filter(is_active=True)
        .first()
    )

    if profile is None:
        profile = user.profiles.first()

    if profile is None:
        raise ValidationError(
            {"profile": "Active profile required."}
        )

    social = (
        SocialProfile.objects
        .filter(profile=profile)
        .first()
    )

    if social is None:
        raise ValidationError(
            {"social_profile": "Social profile required."}
        )

    return social


def _accepted_connection_exists(left, right):
    return SocialConnection.objects.filter(
        Q(
            requester=left,
            target=right,
            status=SocialConnection.STATUS_ACCEPTED,
        )
        |
        Q(
            requester=right,
            target=left,
            status=SocialConnection.STATUS_ACCEPTED,
        )
    ).exists()


def _require_open_host(*, salon, user):
    if salon.status != Salon.STATUS_OPEN:
        raise ValidationError(
            {"salon": "Salon is closed."}
        )

    if salon.host_id != user.pk:
        raise ValidationError(
            {"permission": "Only the Salon host may invite users."}
        )


def _require_invitation_eligibility(
    *,
    salon,
    inviter,
    invitee,
):
    _require_open_host(
        salon=salon,
        user=inviter,
    )

    if inviter.pk == invitee.pk:
        raise ValidationError(
            {"invitee": "You cannot invite yourself."}
        )

    if SalonMember.objects.filter(
        salon=salon,
        user=invitee,
        left_at__isnull=True,
    ).exists():
        raise ValidationError(
            {"invitee": "User is already an active Salon member."}
        )

    inviter_social = _social_profile_for_user(inviter)
    invitee_social = _social_profile_for_user(invitee)

    if not _accepted_connection_exists(
        inviter_social,
        invitee_social,
    ):
        raise ValidationError(
            {
                "connection":
                    "An accepted social connection is required."
            }
        )

    if not is_social_match_allowed(
        requester_social=inviter_social,
        candidate_social=invitee_social,
    ):
        raise ValidationError(
            {"social": "Social interaction is not allowed."}
        )


@transaction.atomic
def create_salon_invitation(
    *,
    salon,
    inviter,
    invitee,
):
    _require_invitation_eligibility(
        salon=salon,
        inviter=inviter,
        invitee=invitee,
    )

    existing = (
        SalonInvitation.objects
        .select_for_update()
        .filter(
            salon=salon,
            invitee=invitee,
            status=SalonInvitation.STATUS_PENDING,
        )
        .first()
    )

    if existing is not None:
        return existing

    invitation = SalonInvitation.objects.create(
        salon=salon,
        inviter=inviter,
        invitee=invitee,
    )

    notify_salon_invitation_received(
        invitation=invitation,
    )

    return invitation


@transaction.atomic
def accept_salon_invitation(
    *,
    invitation,
    user,
):
    invitation = (
        SalonInvitation.objects
        .select_for_update()
        .select_related(
            "salon",
            "inviter",
            "invitee",
        )
        .get(pk=invitation.pk)
    )

    if invitation.invitee_id != user.pk:
        raise ValidationError(
            {"permission": "Only the invitee may accept this invitation."}
        )

    if invitation.status != SalonInvitation.STATUS_PENDING:
        raise ValidationError(
            {"status": "Invitation is not pending."}
        )

    # Safety is re-evaluated at acceptance time.
    inviter_social = _social_profile_for_user(
        invitation.inviter
    )
    invitee_social = _social_profile_for_user(
        invitation.invitee
    )

    if not _accepted_connection_exists(
        inviter_social,
        invitee_social,
    ):
        raise ValidationError(
            {"connection": "Accepted social connection no longer exists."}
        )

    if not is_social_match_allowed(
        requester_social=inviter_social,
        candidate_social=invitee_social,
    ):
        raise ValidationError(
            {"social": "Social interaction is no longer allowed."}
        )

    membership = join_salon(
        salon=invitation.salon,
        user=user,
    )

    invitation.status = SalonInvitation.STATUS_ACCEPTED
    invitation.responded_at = timezone.now()
    invitation.save(
        update_fields=(
            "status",
            "responded_at",
            "updated_at",
        )
    )

    notify_salon_invitation_accepted(
        invitation=invitation,
    )

    return invitation, membership


@transaction.atomic
def decline_salon_invitation(
    *,
    invitation,
    user,
):
    invitation = (
        SalonInvitation.objects
        .select_for_update()
        .get(pk=invitation.pk)
    )

    if invitation.invitee_id != user.pk:
        raise ValidationError(
            {"permission": "Only the invitee may decline this invitation."}
        )

    if invitation.status != SalonInvitation.STATUS_PENDING:
        raise ValidationError(
            {"status": "Invitation is not pending."}
        )

    invitation.status = SalonInvitation.STATUS_DECLINED
    invitation.responded_at = timezone.now()
    invitation.save(
        update_fields=(
            "status",
            "responded_at",
            "updated_at",
        )
    )

    return invitation


@transaction.atomic
def cancel_salon_invitation(
    *,
    invitation,
    user,
):
    invitation = (
        SalonInvitation.objects
        .select_for_update()
        .select_related("salon")
        .get(pk=invitation.pk)
    )

    if invitation.salon.host_id != user.pk:
        raise ValidationError(
            {"permission": "Only the Salon host may cancel this invitation."}
        )

    if invitation.status != SalonInvitation.STATUS_PENDING:
        raise ValidationError(
            {"status": "Invitation is not pending."}
        )

    invitation.status = SalonInvitation.STATUS_CANCELLED
    invitation.responded_at = timezone.now()
    invitation.save(
        update_fields=(
            "status",
            "responded_at",
            "updated_at",
        )
    )

    return invitation
