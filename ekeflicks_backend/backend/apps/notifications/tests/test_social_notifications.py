from django.core import mail
from django.test import TestCase

from apps.notifications.social_notifications import (
    EVENT_CONNECTION_ACCEPTED,
    EVENT_CONNECTION_REQUESTED,
    EVENT_SALON_INVITATION_ACCEPTED,
    EVENT_SALON_INVITATION_RECEIVED,
    SOCIAL_NOTIFICATION_VERSION,
    notify_connection_accepted,
    notify_connection_requested,
    notify_salon_invitation_accepted,
    notify_salon_invitation_received,
)
from core.models import Notification, User


class DummyProfile:
    def __init__(self, *, pk, user, name):
        self.pk = pk
        self.id = pk
        self.user = user
        self.name = name
        self.is_active = True


class DummySocial:
    def __init__(self, *, pk, profile, name):
        self.pk = pk
        self.id = pk
        self.profile = profile
        self.profile_id = profile.pk
        self.public_display_name = name


class DummyConnection:
    def __init__(self, *, pk, requester, target):
        self.pk = pk
        self.id = pk
        self.requester = requester
        self.target = target


class DummySalon:
    def __init__(self, *, pk, name):
        self.pk = pk
        self.id = pk
        self.name = name


class DummyInvitation:
    def __init__(self, *, pk, salon, inviter, invitee):
        self.pk = pk
        self.id = pk
        self.salon = salon
        self.salon_id = salon.pk
        self.inviter = inviter
        self.inviter_id = inviter.pk
        self.invitee = invitee
        self.invitee_id = invitee.pk


class SocialNotificationTests(TestCase):
    def setUp(self):
        self.user_a = User.objects.create_user(
            email="social-a@example.com",
            password="secret",
        )

        self.user_b = User.objects.create_user(
            email="social-b@example.com",
            password="secret",
        )

        profile_a = DummyProfile(
            pk=101,
            user=self.user_a,
            name="Social A",
        )

        profile_b = DummyProfile(
            pk=202,
            user=self.user_b,
            name="Social B",
        )

        self.social_a = DummySocial(
            pk=1001,
            profile=profile_a,
            name="Social A",
        )

        self.social_b = DummySocial(
            pk=2002,
            profile=profile_b,
            name="Social B",
        )

        self.connection = DummyConnection(
            pk=303,
            requester=self.social_a,
            target=self.social_b,
        )

        self.salon = DummySalon(
            pk="00000000-0000-0000-0000-000000000111",
            name="Salon Test",
        )

        self.invitation = DummyInvitation(
            pk="00000000-0000-0000-0000-000000000222",
            salon=self.salon,
            inviter=self.user_a,
            invitee=self.user_b,
        )

    def _capture_commit(self, callback):
        with self.captureOnCommitCallbacks(
            execute=True
        ):
            callback()

    def test_version(self):
        self.assertEqual(
            SOCIAL_NOTIFICATION_VERSION,
            "g5_3k_v1",
        )

    def test_connection_request_notifies_target(self):
        self._capture_commit(
            lambda: notify_connection_requested(
                connection=self.connection
            )
        )

        notification = Notification.objects.get(
            user=self.user_b,
            type__name=EVENT_CONNECTION_REQUESTED,
        )

        self.assertEqual(
            notification.data["connection_id"],
            303,
        )

        self.assertEqual(
            notification.data["action"],
            "requested",
        )

    def test_connection_accept_notifies_requester(self):
        self._capture_commit(
            lambda: notify_connection_accepted(
                connection=self.connection
            )
        )

        notification = Notification.objects.get(
            user=self.user_a,
            type__name=EVENT_CONNECTION_ACCEPTED,
        )

        self.assertEqual(
            notification.data["action"],
            "accepted",
        )

    def test_salon_invitation_notifies_invitee(self):
        self._capture_commit(
            lambda: notify_salon_invitation_received(
                invitation=self.invitation
            )
        )

        notification = Notification.objects.get(
            user=self.user_b,
            type__name=EVENT_SALON_INVITATION_RECEIVED,
        )

        self.assertEqual(
            notification.data["salon_id"],
            str(self.salon.pk),
        )

    def test_salon_accept_notifies_inviter(self):
        self._capture_commit(
            lambda: notify_salon_invitation_accepted(
                invitation=self.invitation
            )
        )

        notification = Notification.objects.get(
            user=self.user_a,
            type__name=EVENT_SALON_INVITATION_ACCEPTED,
        )

        self.assertEqual(
            notification.data["action"],
            "accepted",
        )

    def test_social_notifications_do_not_send_email(self):
        before = len(mail.outbox)

        self._capture_commit(
            lambda: notify_connection_requested(
                connection=self.connection
            )
        )

        self.assertEqual(
            len(mail.outbox),
            before,
        )

    def test_notification_is_deferred_until_commit(self):
        notify_connection_requested(
            connection=self.connection
        )

        self.assertFalse(
            Notification.objects.filter(
                user=self.user_b,
                type__name=EVENT_CONNECTION_REQUESTED,
            ).exists()
        )
