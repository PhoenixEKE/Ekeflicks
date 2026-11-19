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
    Salon,
    SalonMember,
    SalonSessionQuotaEntry,
)
from apps.salons.services import (
    close_salon,
    create_salon,
    leave_salon,
    transfer_salon_host,
)


User = get_user_model()


class SalonHostManagementTests(APITestCase):
    def setUp(self):
        self.host = User.objects.create_user(
            email="g53p-host@example.com",
            password="test-password",
        )

        self.member = User.objects.create_user(
            email="g53p-member@example.com",
            password="test-password",
        )

        self.other = User.objects.create_user(
            email="g53p-other@example.com",
            password="test-password",
        )

        self.salon = create_salon(
            host=self.host,
            name="G5-3P Host Room",
            visibility=Salon.VISIBILITY_PRIVATE,
            mode=Salon.MODE_SOCIAL,
            capacity=10,
        )

        self.member_membership = (
            SalonMember.objects.create(
                salon=self.salon,
                user=self.member,
                role=SalonMember.ROLE_MEMBER,
            )
        )

    def test_current_host_can_transfer_to_active_member(self):
        salon = transfer_salon_host(
            salon=self.salon,
            user=self.host,
            target_user=self.member,
        )

        salon.refresh_from_db()

        self.assertEqual(
            salon.host_id,
            self.member.pk,
        )

        old_host = SalonMember.objects.get(
            salon=salon,
            user=self.host,
            left_at__isnull=True,
        )

        new_host = SalonMember.objects.get(
            salon=salon,
            user=self.member,
            left_at__isnull=True,
        )

        self.assertEqual(
            old_host.role,
            SalonMember.ROLE_MEMBER,
        )

        self.assertEqual(
            new_host.role,
            SalonMember.ROLE_HOST,
        )

        self.assertEqual(
            SalonMember.objects.filter(
                salon=salon,
                role=SalonMember.ROLE_HOST,
                left_at__isnull=True,
            ).count(),
            1,
        )

    def test_non_host_cannot_transfer(self):
        with self.assertRaises(
            PermissionDenied
        ):
            transfer_salon_host(
                salon=self.salon,
                user=self.member,
                target_user=self.host,
            )

    def test_cannot_transfer_to_non_member(self):
        with self.assertRaises(
            ValidationError
        ):
            transfer_salon_host(
                salon=self.salon,
                user=self.host,
                target_user=self.other,
            )

    def test_cannot_transfer_to_current_host(self):
        with self.assertRaises(
            ValidationError
        ):
            transfer_salon_host(
                salon=self.salon,
                user=self.host,
                target_user=self.host,
            )

    def test_cannot_transfer_closed_salon(self):
        close_salon(
            salon=self.salon,
            user=self.host,
        )

        with self.assertRaises(
            ValidationError
        ):
            transfer_salon_host(
                salon=self.salon,
                user=self.host,
                target_user=self.member,
            )

    def test_old_host_can_leave_after_transfer(self):
        transfer_salon_host(
            salon=self.salon,
            user=self.host,
            target_user=self.member,
        )

        membership = leave_salon(
            salon=self.salon,
            user=self.host,
        )

        membership.refresh_from_db()

        self.assertIsNotNone(
            membership.left_at
        )

        self.salon.refresh_from_db()

        self.assertEqual(
            self.salon.host_id,
            self.member.pk,
        )

    def test_new_host_cannot_use_ordinary_leave(self):
        transfer_salon_host(
            salon=self.salon,
            user=self.host,
            target_user=self.member,
        )

        with self.assertRaises(
            ValidationError
        ):
            leave_salon(
                salon=self.salon,
                user=self.member,
            )

    def test_new_host_can_close_after_transfer(self):
        transfer_salon_host(
            salon=self.salon,
            user=self.host,
            target_user=self.member,
        )

        salon = close_salon(
            salon=self.salon,
            user=self.member,
        )

        self.assertEqual(
            salon.status,
            Salon.STATUS_CLOSED,
        )

    def test_old_host_cannot_close_after_transfer(self):
        transfer_salon_host(
            salon=self.salon,
            user=self.host,
            target_user=self.member,
        )

        with self.assertRaises(
            PermissionDenied
        ):
            close_salon(
                salon=self.salon,
                user=self.host,
            )

    def test_quota_ledger_owner_does_not_change(self):
        entry = SalonSessionQuotaEntry.objects.create(
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

        transfer_salon_host(
            salon=self.salon,
            user=self.host,
            target_user=self.member,
        )

        entry.refresh_from_db()

        self.assertEqual(
            entry.host_id,
            self.host.pk,
        )

        self.assertNotEqual(
            entry.host_id,
            self.member.pk,
        )

    def test_close_after_transfer_preserves_original_quota_owner(
        self,
    ):
        entry = SalonSessionQuotaEntry.objects.create(
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

        transfer_salon_host(
            salon=self.salon,
            user=self.host,
            target_user=self.member,
        )

        # The original commercial owner must remain
        # immutable even though operational authority
        # has moved to the new Salon host.
        close_salon(
            salon=self.salon,
            user=self.member,
        )

        entry.refresh_from_db()

        self.assertEqual(
            entry.host_id,
            self.host.pk,
        )

        self.assertEqual(
            entry.status,
            SalonSessionQuotaEntry.STATUS_RELEASED,
        )

    def test_api_host_can_transfer(self):
        self.client.force_authenticate(
            user=self.host
        )

        response = self.client.post(
            reverse(
                "salon-transfer-host",
                kwargs={
                    "pk": self.salon.pk,
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

        self.salon.refresh_from_db()

        self.assertEqual(
            self.salon.host_id,
            self.member.pk,
        )

        self.assertEqual(
            str(response.data["host_id"]),
            str(self.member.pk),
        )

    def test_api_requires_target_user_id(self):
        self.client.force_authenticate(
            user=self.host
        )

        response = self.client.post(
            reverse(
                "salon-transfer-host",
                kwargs={
                    "pk": self.salon.pk,
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
                "salon-transfer-host",
                kwargs={
                    "pk": self.salon.pk,
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
