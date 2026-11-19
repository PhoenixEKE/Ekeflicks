from datetime import timedelta
import uuid

from django.contrib.auth import get_user_model
from django.urls import reverse
from django.utils import timezone

from rest_framework import status
from rest_framework.exceptions import (
    PermissionDenied,
    ValidationError,
)
from rest_framework.test import APITestCase

from apps.salons.models import (
    SalonMember,
    SalonSessionQuotaEntry,
)
from apps.salons.services import (
    close_salon,
    create_salon,
    join_salon,
    kick_salon_member,
    transfer_salon_host,
)


User = get_user_model()


class SalonParticipantManagementTests(APITestCase):

    def setUp(self):
        self.host = User.objects.create_user(
            email="g53q-host@example.com",
            password="test-pass",
        )

        self.member = User.objects.create_user(
            email="g53q-member@example.com",
            password="test-pass",
        )

        self.other = User.objects.create_user(
            email="g53q-other@example.com",
            password="test-pass",
        )

        self.salon = create_salon(
            host=self.host,
            name="G5-3Q Salon",
        )

        self.membership = join_salon(
            salon=self.salon,
            user=self.member,
        )

    def test_current_host_can_kick_active_member(self):
        membership = kick_salon_member(
            salon=self.salon,
            user=self.host,
            target_user=self.member,
        )

        membership.refresh_from_db()

        self.assertIsNotNone(
            membership.left_at
        )

        self.assertFalse(
            SalonMember.objects.filter(
                salon=self.salon,
                user=self.member,
                left_at__isnull=True,
            ).exists()
        )

    def test_non_host_cannot_kick_member(self):
        with self.assertRaises(
            PermissionDenied
        ):
            kick_salon_member(
                salon=self.salon,
                user=self.other,
                target_user=self.member,
            )

        self.membership.refresh_from_db()

        self.assertIsNone(
            self.membership.left_at
        )

    def test_host_cannot_kick_self(self):
        with self.assertRaises(
            ValidationError
        ):
            kick_salon_member(
                salon=self.salon,
                user=self.host,
                target_user=self.host,
            )

    def test_non_member_cannot_be_kicked(self):
        with self.assertRaises(
            ValidationError
        ):
            kick_salon_member(
                salon=self.salon,
                user=self.host,
                target_user=self.other,
            )

    def test_already_left_member_cannot_be_kicked(self):
        self.membership.left_at = timezone.now()
        self.membership.save(
            update_fields=("left_at",)
        )

        with self.assertRaises(
            ValidationError
        ):
            kick_salon_member(
                salon=self.salon,
                user=self.host,
                target_user=self.member,
            )

    def test_closed_salon_rejects_kick(self):
        close_salon(
            salon=self.salon,
            user=self.host,
        )

        with self.assertRaises(
            ValidationError
        ):
            kick_salon_member(
                salon=self.salon,
                user=self.host,
                target_user=self.member,
            )

    def test_kick_preserves_membership_history(self):
        membership_id = self.membership.pk

        kick_salon_member(
            salon=self.salon,
            user=self.host,
            target_user=self.member,
        )

        membership = SalonMember.objects.get(
            pk=membership_id
        )

        self.assertIsNotNone(
            membership.left_at
        )

    def test_new_host_can_kick_after_transfer(self):
        transfer_salon_host(
            salon=self.salon,
            user=self.host,
            target_user=self.member,
        )

        other_membership = join_salon(
            salon=self.salon,
            user=self.other,
        )

        kick_salon_member(
            salon=self.salon,
            user=self.member,
            target_user=self.other,
        )

        other_membership.refresh_from_db()

        self.assertIsNotNone(
            other_membership.left_at
        )

    def test_old_host_cannot_kick_after_transfer(self):
        transfer_salon_host(
            salon=self.salon,
            user=self.host,
            target_user=self.member,
        )

        join_salon(
            salon=self.salon,
            user=self.other,
        )

        with self.assertRaises(
            PermissionDenied
        ):
            kick_salon_member(
                salon=self.salon,
                user=self.host,
                target_user=self.other,
            )

    def test_quota_ledger_owner_does_not_change(self):
        entry = (
            SalonSessionQuotaEntry.objects.create(
                salon=self.salon,
                host=self.host,
                period_start=(
                    timezone.now()
                    .date()
                    .replace(day=1)
                ),
                status=(
                    SalonSessionQuotaEntry
                    .STATUS_RESERVED
                ),
                plan_slug="premium",
            )
        )

        kick_salon_member(
            salon=self.salon,
            user=self.host,
            target_user=self.member,
        )

        entry.refresh_from_db()

        self.assertEqual(
            entry.host_id,
            self.host.pk,
        )

    def test_kick_preserves_completed_presence_interval(
        self
    ):
        joined_at = (
            timezone.now()
            - timedelta(minutes=10)
        )

        SalonMember.objects.filter(
            pk=self.membership.pk
        ).update(
            joined_at=joined_at
        )

        kick_salon_member(
            salon=self.salon,
            user=self.host,
            target_user=self.member,
        )

        self.membership.refresh_from_db()

        self.assertEqual(
            self.membership.joined_at,
            joined_at,
        )

        self.assertIsNotNone(
            self.membership.left_at
        )

        self.assertGreater(
            self.membership.left_at,
            self.membership.joined_at,
        )

    def test_api_host_can_kick_active_member(self):
        self.client.force_authenticate(
            user=self.host
        )

        response = self.client.post(
            reverse(
                "salon-kick",
                kwargs={
                    "pk": self.salon.pk
                },
            ),
            {
                "target_user_id":
                str(self.member.pk),
            },
            format="json",
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_200_OK,
        )

        self.assertFalse(
            SalonMember.objects.filter(
                salon=self.salon,
                user=self.member,
                left_at__isnull=True,
            ).exists()
        )

    def test_api_requires_target_user_id(self):
        self.client.force_authenticate(
            user=self.host
        )

        response = self.client.post(
            reverse(
                "salon-kick",
                kwargs={
                    "pk": self.salon.pk
                },
            ),
            {},
            format="json",
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_400_BAD_REQUEST,
        )

    def test_api_rejects_unknown_target_user(self):
        self.client.force_authenticate(
            user=self.host
        )

        response = self.client.post(
            reverse(
                "salon-kick",
                kwargs={
                    "pk": self.salon.pk
                },
            ),
            {
                "target_user_id":
                str(uuid.uuid4()),
            },
            format="json",
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_400_BAD_REQUEST,
        )
