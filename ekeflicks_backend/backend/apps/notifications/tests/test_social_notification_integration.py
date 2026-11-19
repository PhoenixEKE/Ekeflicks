from django.contrib.auth import get_user_model
from django.db import transaction
from django.test import TransactionTestCase

from apps.notifications.social_notifications import (
    EVENT_CONNECTION_ACCEPTED,
    EVENT_CONNECTION_REQUESTED,
    EVENT_SALON_INVITATION_ACCEPTED,
    EVENT_SALON_INVITATION_RECEIVED,
)
from apps.profiles.social_connections import (
    accept_connection_request,
    create_connection_request,
    decline_connection_request,
)
from apps.profiles.social_models import (
    SocialConnection,
    SocialProfile,
)
from apps.salons.invitations import (
    accept_salon_invitation,
    create_salon_invitation,
)
from apps.salons.models import (
    Salon,
    SalonInvitation,
    SalonMember,
)
from core.models import Notification
from core.models.profiles import (
    Profile,
    ProfileType,
)


User = get_user_model()


class BaseSocialNotificationIntegrationTests(
    TransactionTestCase
):

    def _profile_and_social(
        self,
        *,
        user,
        name,
    ):
        profile = (
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

        if profile is None:
            profile = (
                Profile.objects
                .filter(user=user)
                .order_by(
                    "created_at",
                    "pk",
                )
                .first()
            )

        if profile is None:
            profile = Profile.objects.create(
                user=user,
                type=self.profile_type,
                name=name,
                is_active=True,
            )
        else:
            profile.type = self.profile_type
            profile.name = name
            profile.is_active = True
            profile.save(
                update_fields=(
                    "type",
                    "name",
                    "is_active",
                    "updated_at",
                )
            )

        social, _created = (
            SocialProfile.objects
            .get_or_create(
                profile=profile,
                defaults={
                    "display_name": name,
                    "is_discoverable": True,
                },
            )
        )

        changed = []

        if social.display_name != name:
            social.display_name = name
            changed.append(
                "display_name"
            )

        if not social.is_discoverable:
            social.is_discoverable = True
            changed.append(
                "is_discoverable"
            )

        if changed:
            social.save(
                update_fields=tuple(changed)
            )

        return profile, social

    def _notification_count(
        self,
        *,
        user,
        event_name,
    ):
        return (
            Notification.objects
            .filter(
                user=user,
                type__name=event_name,
            )
            .count()
        )


class ConnectionNotificationIntegrationTests(
    BaseSocialNotificationIntegrationTests
):
    def setUp(self):
        self.profile_type, _ = (
            ProfileType.objects.get_or_create(
                name="main"
            )
        )

        self.user_a = User.objects.create_user(
            email="g53k-connection-a@example.com",
            password="Password123!",
        )

        self.user_b = User.objects.create_user(
            email="g53k-connection-b@example.com",
            password="Password123!",
        )

        (
            self.profile_a,
            self.social_a,
        ) = self._profile_and_social(
            user=self.user_a,
            name="G53K Connection A",
        )

        (
            self.profile_b,
            self.social_b,
        ) = self._profile_and_social(
            user=self.user_b,
            name="G53K Connection B",
        )

    def test_fresh_request_emits_exactly_one_notification(
        self,
    ):
        connection = create_connection_request(
            requester_social=self.social_a,
            target_social=self.social_b,
        )

        self.assertEqual(
            connection.status,
            SocialConnection.STATUS_PENDING,
        )

        self.assertEqual(
            self._notification_count(
                user=self.user_b,
                event_name=EVENT_CONNECTION_REQUESTED,
            ),
            1,
        )

        notification = Notification.objects.get(
            user=self.user_b,
            type__name=EVENT_CONNECTION_REQUESTED,
        )

        self.assertEqual(
            notification.data["connection_id"],
            connection.pk,
        )

    def test_duplicate_pending_does_not_duplicate_notification(
        self,
    ):
        first = create_connection_request(
            requester_social=self.social_a,
            target_social=self.social_b,
        )

        second = create_connection_request(
            requester_social=self.social_a,
            target_social=self.social_b,
        )

        self.assertEqual(
            first.pk,
            second.pk,
        )

        self.assertEqual(
            SocialConnection.objects.count(),
            1,
        )

        self.assertEqual(
            self._notification_count(
                user=self.user_b,
                event_name=EVENT_CONNECTION_REQUESTED,
            ),
            1,
        )

    def test_accept_emits_exactly_one_notification(
        self,
    ):
        connection = create_connection_request(
            requester_social=self.social_a,
            target_social=self.social_b,
        )

        Notification.objects.all().delete()

        connection = accept_connection_request(
            connection=connection,
            actor_social=self.social_b,
        )

        self.assertEqual(
            connection.status,
            SocialConnection.STATUS_ACCEPTED,
        )

        self.assertEqual(
            self._notification_count(
                user=self.user_a,
                event_name=EVENT_CONNECTION_ACCEPTED,
            ),
            1,
        )

        self.assertEqual(
            self._notification_count(
                user=self.user_b,
                event_name=EVENT_CONNECTION_REQUESTED,
            ),
            0,
        )

    def test_declined_request_restart_emits_one_fresh_notification(
        self,
    ):
        connection = create_connection_request(
            requester_social=self.social_a,
            target_social=self.social_b,
        )

        Notification.objects.all().delete()

        declined = decline_connection_request(
            connection=connection,
            actor_social=self.social_b,
        )

        self.assertEqual(
            declined.status,
            SocialConnection.STATUS_DECLINED,
        )

        restarted = create_connection_request(
            requester_social=self.social_a,
            target_social=self.social_b,
        )

        self.assertEqual(
            restarted.pk,
            connection.pk,
        )

        self.assertEqual(
            restarted.status,
            SocialConnection.STATUS_PENDING,
        )

        self.assertEqual(
            self._notification_count(
                user=self.user_b,
                event_name=EVENT_CONNECTION_REQUESTED,
            ),
            1,
        )

    def test_rolled_back_request_emits_no_notification(
        self,
    ):
        try:
            with transaction.atomic():
                create_connection_request(
                    requester_social=self.social_a,
                    target_social=self.social_b,
                )

                raise RuntimeError(
                    "force rollback"
                )
        except RuntimeError:
            pass

        self.assertEqual(
            SocialConnection.objects.count(),
            0,
        )

        self.assertEqual(
            self._notification_count(
                user=self.user_b,
                event_name=EVENT_CONNECTION_REQUESTED,
            ),
            0,
        )


class SalonInvitationNotificationIntegrationTests(
    BaseSocialNotificationIntegrationTests
):
    def setUp(self):
        self.profile_type, _ = (
            ProfileType.objects.get_or_create(
                name="main"
            )
        )

        self.host = User.objects.create_user(
            email="g53k-host@example.com",
            password="Password123!",
        )

        self.invitee = User.objects.create_user(
            email="g53k-invitee@example.com",
            password="Password123!",
        )

        (
            self.host_profile,
            self.host_social,
        ) = self._profile_and_social(
            user=self.host,
            name="G53K Host",
        )

        (
            self.invitee_profile,
            self.invitee_social,
        ) = self._profile_and_social(
            user=self.invitee,
            name="G53K Invitee",
        )

        self.connection = (
            SocialConnection.objects.create(
                requester=self.host_social,
                target=self.invitee_social,
                status=SocialConnection.STATUS_ACCEPTED,
            )
        )

        self.salon = Salon.objects.create(
            name="G5-3K Salon",
            host=self.host,
            visibility=Salon.VISIBILITY_PRIVATE,
            capacity=10,
        )

        SalonMember.objects.get_or_create(
            salon=self.salon,
            user=self.host,
            defaults={
                "role": SalonMember.ROLE_HOST,
            },
        )

    def test_fresh_invitation_emits_exactly_one_notification(
        self,
    ):
        invitation = create_salon_invitation(
            salon=self.salon,
            inviter=self.host,
            invitee=self.invitee,
        )

        self.assertEqual(
            invitation.status,
            SalonInvitation.STATUS_PENDING,
        )

        self.assertEqual(
            self._notification_count(
                user=self.invitee,
                event_name=EVENT_SALON_INVITATION_RECEIVED,
            ),
            1,
        )

        notification = Notification.objects.get(
            user=self.invitee,
            type__name=EVENT_SALON_INVITATION_RECEIVED,
        )

        self.assertNotIn(
            self.host.email,
            notification.message,
        )

        self.assertNotIn(
            self.invitee.email,
            notification.message,
        )

        self.assertNotIn(
            "@",
            notification.message,
        )

    def test_duplicate_pending_invitation_does_not_duplicate_notification(
        self,
    ):
        first = create_salon_invitation(
            salon=self.salon,
            inviter=self.host,
            invitee=self.invitee,
        )

        second = create_salon_invitation(
            salon=self.salon,
            inviter=self.host,
            invitee=self.invitee,
        )

        self.assertEqual(
            first.pk,
            second.pk,
        )

        self.assertEqual(
            SalonInvitation.objects.count(),
            1,
        )

        self.assertEqual(
            self._notification_count(
                user=self.invitee,
                event_name=EVENT_SALON_INVITATION_RECEIVED,
            ),
            1,
        )

    def test_accept_invitation_emits_exactly_one_notification(
        self,
    ):
        invitation = create_salon_invitation(
            salon=self.salon,
            inviter=self.host,
            invitee=self.invitee,
        )

        Notification.objects.all().delete()

        invitation, membership = (
            accept_salon_invitation(
                invitation=invitation,
                user=self.invitee,
            )
        )

        self.assertEqual(
            invitation.status,
            SalonInvitation.STATUS_ACCEPTED,
        )

        self.assertEqual(
            membership.user_id,
            self.invitee.pk,
        )

        self.assertEqual(
            self._notification_count(
                user=self.host,
                event_name=EVENT_SALON_INVITATION_ACCEPTED,
            ),
            1,
        )

        notification = Notification.objects.get(
            user=self.host,
            type__name=EVENT_SALON_INVITATION_ACCEPTED,
        )

        self.assertNotIn(
            self.host.email,
            notification.message,
        )

        self.assertNotIn(
            self.invitee.email,
            notification.message,
        )

        self.assertNotIn(
            "@",
            notification.message,
        )

    def test_rolled_back_invitation_emits_no_notification(
        self,
    ):
        try:
            with transaction.atomic():
                create_salon_invitation(
                    salon=self.salon,
                    inviter=self.host,
                    invitee=self.invitee,
                )

                raise RuntimeError(
                    "force rollback"
                )
        except RuntimeError:
            pass

        self.assertEqual(
            SalonInvitation.objects.count(),
            0,
        )

        self.assertEqual(
            self._notification_count(
                user=self.invitee,
                event_name=EVENT_SALON_INVITATION_RECEIVED,
            ),
            0,
        )
