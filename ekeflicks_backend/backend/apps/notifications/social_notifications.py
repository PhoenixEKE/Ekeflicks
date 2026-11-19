"""
G5-3K — Social notification integration.

Notification delivery is scheduled with transaction.on_commit so a
notification cannot outlive a rolled-back social state transition.
"""

from __future__ import annotations

from uuid import UUID

from django.db import transaction

from apps.notifications.services import notify_user


SOCIAL_NOTIFICATION_VERSION = "g5_3k_v1"

EVENT_CONNECTION_REQUESTED = "social_connection_requested"
EVENT_CONNECTION_ACCEPTED = "social_connection_accepted"
EVENT_SALON_INVITATION_RECEIVED = "salon_invitation_received"
EVENT_SALON_INVITATION_ACCEPTED = "salon_invitation_accepted"


def _json_id(value):
    if isinstance(value, UUID):
        return str(value)

    return value


def _display_name(social_profile):
    value = getattr(
        social_profile,
        "public_display_name",
        "",
    )

    if callable(value):
        value = value()

    value = (value or "").strip()

    if value:
        return value

    return "Un membre"


def _schedule_notification(
    *,
    user,
    event_name,
    title,
    message,
    data,
):
    user_id = user.pk

    def send():
        from core.models import User

        recipient = User.objects.filter(
            pk=user_id,
            is_active=True,
        ).first()

        if recipient is None:
            return

        notify_user(
            recipient,
            event_name,
            title=title,
            message=message,
            data=data,
            email_enabled=False,
        )

    transaction.on_commit(send)


def notify_connection_requested(*, connection):
    requester = connection.requester
    target = connection.target

    _schedule_notification(
        user=target.profile.user,
        event_name=EVENT_CONNECTION_REQUESTED,
        title="Nouvelle demande de connexion",
        message=(
            f"{_display_name(requester)} souhaite se connecter avec vous."
        ),
        data={
            "kind": "social_connection",
            "action": "requested",
            "connection_id": _json_id(connection.pk),
            "requester_profile_id": _json_id(requester.profile_id),
            "target_profile_id": _json_id(target.profile_id),
        },
    )


def notify_connection_accepted(*, connection):
    requester = connection.requester
    target = connection.target

    _schedule_notification(
        user=requester.profile.user,
        event_name=EVENT_CONNECTION_ACCEPTED,
        title="Connexion acceptee",
        message=(
            f"{_display_name(target)} a accepte votre demande de connexion."
        ),
        data={
            "kind": "social_connection",
            "action": "accepted",
            "connection_id": _json_id(connection.pk),
            "requester_profile_id": _json_id(requester.profile_id),
            "target_profile_id": _json_id(target.profile_id),
        },
    )


def notify_salon_invitation_received(*, invitation):
    _schedule_notification(
        user=invitation.invitee,
        event_name=EVENT_SALON_INVITATION_RECEIVED,
        title="Invitation a un Salon",
        message=(
            f"Vous avez recu une invitation a rejoindre "
            f"{invitation.salon.name}."
        ),
        data={
            "kind": "salon_invitation",
            "action": "received",
            "invitation_id": _json_id(invitation.pk),
            "salon_id": _json_id(invitation.salon_id),
            "inviter_id": _json_id(invitation.inviter_id),
            "invitee_id": _json_id(invitation.invitee_id),
        },
    )


def notify_salon_invitation_accepted(*, invitation):
    _schedule_notification(
        user=invitation.inviter,
        event_name=EVENT_SALON_INVITATION_ACCEPTED,
        title="Invitation Salon acceptee",
        message=(
            f"Votre invitation a {invitation.salon.name} "
            f"a ete acceptee."
        ),
        data={
            "kind": "salon_invitation",
            "action": "accepted",
            "invitation_id": _json_id(invitation.pk),
            "salon_id": _json_id(invitation.salon_id),
            "inviter_id": _json_id(invitation.inviter_id),
            "invitee_id": _json_id(invitation.invitee_id),
        },
    )
