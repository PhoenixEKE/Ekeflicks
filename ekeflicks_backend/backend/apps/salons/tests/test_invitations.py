from django.contrib.auth import get_user_model
from django.test import TestCase

from apps.profiles.social_models import (
    SocialConnection,
    SocialProfile,
)
from core.models.profiles import (
    Profile,
    ProfileType,
)

from apps.salons.invitations import (
    SALON_INVITATION_VERSION,
    accept_salon_invitation,
    cancel_salon_invitation,
    create_salon_invitation,
    decline_salon_invitation,
)
from apps.salons.models import (
    Salon,
    SalonInvitation,
    SalonMember,
)


User = get_user_model()


class SalonInvitationTests(TestCase):
    def setUp(self):
        self.profile_type, _ = (
            ProfileType.objects.get_or_create(
                name="main"
            )
        )

        self.host = User.objects.create_user(
            email="g53j-host@example.com",
            password="test-password",
        )

        self.invitee = User.objects.create_user(
            email="g53j-invitee@example.com",
            password="test-password",
        )

        self.outsider = User.objects.create_user(
            email="g53j-outsider@example.com",
            password="test-password",
        )

        self.host_social = self._social(
            self.host,
            "G53J Host",
        )

        self.invitee_social = self._social(
            self.invitee,
            "G53J Invitee",
        )

        self.outsider_social = self._social(
            self.outsider,
            "G53J Outsider",
        )

        self.salon = Salon.objects.create(
            name="G5-3J Salon",
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

        self.connection = (
            SocialConnection.objects.create(
                requester=self.host_social,
                target=self.invitee_social,
                status=SocialConnection.STATUS_ACCEPTED,
            )
        )

    def _social(self, user, name):
        profile = (
            user.profiles
            .filter(is_active=True)
            .first()
            or user.profiles.first()
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
                )
            )

        social, _ = (
            SocialProfile.objects
            .get_or_create(
                profile=profile,
                defaults={
                    "is_discoverable": True,
                },
            )
        )

        if not social.is_discoverable:
            social.is_discoverable = True
            social.save(
                update_fields=(
                    "is_discoverable",
                )
            )

        return social

    def test_version(self):
        self.assertEqual(
            SALON_INVITATION_VERSION,
            "g5_3j_v1",
        )

    def test_host_can_invite_accepted_connection(self):
        invitation = create_salon_invitation(
            salon=self.salon,
            inviter=self.host,
            invitee=self.invitee,
        )

        self.assertEqual(
            invitation.status,
            SalonInvitation.STATUS_PENDING,
        )

    def test_duplicate_pending_is_idempotent(self):
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

    def test_non_connection_cannot_be_invited(self):
        with self.assertRaises(Exception):
            create_salon_invitation(
                salon=self.salon,
                inviter=self.host,
                invitee=self.outsider,
            )

    def test_non_host_cannot_invite(self):
        with self.assertRaises(Exception):
            create_salon_invitation(
                salon=self.salon,
                inviter=self.invitee,
                invitee=self.outsider,
            )

    def test_invitee_can_accept(self):
        invitation = create_salon_invitation(
            salon=self.salon,
            inviter=self.host,
            invitee=self.invitee,
        )

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

        self.assertTrue(
            SalonMember.objects.filter(
                salon=self.salon,
                user=self.invitee,
                left_at__isnull=True,
            ).exists()
        )

    def test_invitee_can_decline(self):
        invitation = create_salon_invitation(
            salon=self.salon,
            inviter=self.host,
            invitee=self.invitee,
        )

        invitation = decline_salon_invitation(
            invitation=invitation,
            user=self.invitee,
        )

        self.assertEqual(
            invitation.status,
            SalonInvitation.STATUS_DECLINED,
        )

    def test_host_can_cancel(self):
        invitation = create_salon_invitation(
            salon=self.salon,
            inviter=self.host,
            invitee=self.invitee,
        )

        invitation = cancel_salon_invitation(
            invitation=invitation,
            user=self.host,
        )

        self.assertEqual(
            invitation.status,
            SalonInvitation.STATUS_CANCELLED,
        )

    def test_outsider_cannot_accept(self):
        invitation = create_salon_invitation(
            salon=self.salon,
            inviter=self.host,
            invitee=self.invitee,
        )

        with self.assertRaises(Exception):
            accept_salon_invitation(
                invitation=invitation,
                user=self.outsider,
            )

    def test_removed_connection_blocks_acceptance(self):
        invitation = create_salon_invitation(
            salon=self.salon,
            inviter=self.host,
            invitee=self.invitee,
        )

        self.connection.delete()

        with self.assertRaises(Exception):
            accept_salon_invitation(
                invitation=invitation,
                user=self.invitee,
            )

    def test_closed_salon_cannot_create_invitation(self):
        self.salon.status = Salon.STATUS_CLOSED
        self.salon.save(
            update_fields=("status",)
        )

        with self.assertRaises(Exception):
            create_salon_invitation(
                salon=self.salon,
                inviter=self.host,
                invitee=self.invitee,
            )
