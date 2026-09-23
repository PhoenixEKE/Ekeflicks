from datetime import timedelta
from django.contrib.auth import get_user_model
from django.db import IntegrityError, transaction
from django.urls import reverse
from django.utils import timezone

from rest_framework import status
from rest_framework.exceptions import PermissionDenied, ValidationError
from rest_framework.test import APITestCase

from apps.salons.models import Salon, SalonMember
from core.models.subscriptions import (
    Subscription,
    SubscriptionPlan,
)
from apps.salons.services import (
    close_salon,
    create_salon,
    join_salon,
    leave_salon,
)


User = get_user_model()


class SalonFoundationTests(APITestCase):
    def setUp(self):
        self.host = User.objects.create_user(
            email="salon-host@example.com",
            password="StrongPass123!",
        )
        self.member = User.objects.create_user(
            email="salon-member@example.com",
            password="StrongPass123!",
        )
        self.outsider = User.objects.create_user(
            email="salon-outsider@example.com",
            password="StrongPass123!",
        )

    def test_create_salon_creates_host_membership(self):
        salon = create_salon(
            host=self.host,
            name="Friday Room",
            capacity=4,
        )

        membership = SalonMember.objects.get(
            salon=salon,
            user=self.host,
            left_at__isnull=True,
        )

        self.assertEqual(
            membership.role,
            SalonMember.ROLE_HOST,
        )

    def test_user_can_join_open_salon(self):
        salon = create_salon(
            host=self.host,
            name="Friday Room",
            capacity=4,
        )

        membership = join_salon(
            salon=salon,
            user=self.member,
        )

        self.assertEqual(
            membership.role,
            SalonMember.ROLE_MEMBER,
        )

    def test_join_is_idempotent(self):
        salon = create_salon(
            host=self.host,
            name="Friday Room",
            capacity=4,
        )

        first = join_salon(
            salon=salon,
            user=self.member,
        )
        second = join_salon(
            salon=salon,
            user=self.member,
        )

        self.assertEqual(first.id, second.id)

    def test_capacity_is_enforced(self):
        salon = create_salon(
            host=self.host,
            name="Small Room",
            capacity=2,
        )

        join_salon(
            salon=salon,
            user=self.member,
        )

        with self.assertRaises(ValidationError):
            join_salon(
                salon=salon,
                user=self.outsider,
            )

    def test_member_can_leave(self):
        salon = create_salon(
            host=self.host,
            name="Friday Room",
        )

        membership = join_salon(
            salon=salon,
            user=self.member,
        )

        leave_salon(
            salon=salon,
            user=self.member,
        )

        membership.refresh_from_db()

        self.assertIsNotNone(membership.left_at)

    def test_host_cannot_leave_without_closing(self):
        salon = create_salon(
            host=self.host,
            name="Friday Room",
        )

        with self.assertRaises(ValidationError):
            leave_salon(
                salon=salon,
                user=self.host,
            )

    def test_only_host_can_close(self):
        salon = create_salon(
            host=self.host,
            name="Friday Room",
        )

        with self.assertRaises(PermissionDenied):
            close_salon(
                salon=salon,
                user=self.member,
            )

    def test_close_salon_closes_all_memberships(self):
        salon = create_salon(
            host=self.host,
            name="Friday Room",
        )

        join_salon(
            salon=salon,
            user=self.member,
        )

        close_salon(
            salon=salon,
            user=self.host,
        )

        salon.refresh_from_db()

        self.assertEqual(
            salon.status,
            Salon.STATUS_CLOSED,
        )

        self.assertFalse(
            SalonMember.objects.filter(
                salon=salon,
                left_at__isnull=True,
            ).exists()
        )

    def test_active_membership_unique(self):
        salon = create_salon(
            host=self.host,
            name="Friday Room",
        )

        join_salon(
            salon=salon,
            user=self.member,
        )

        with self.assertRaises(IntegrityError):
            with transaction.atomic():
                SalonMember.objects.create(
                    salon=salon,
                    user=self.member,
                )

    def test_api_requires_authentication(self):
        response = self.client.get(
            reverse("salon-list"),
        )

        self.assertIn(
            response.status_code,
            (
                status.HTTP_401_UNAUTHORIZED,
                status.HTTP_403_FORBIDDEN,
            ),
        )

    def test_authenticated_user_can_create_salon(self):
        plan = SubscriptionPlan.objects.create(
            name="Salon API Premium",
            slug="premium",
            price="13.99",
            currency="EUR",
            duration_days=30,
            max_profiles=4,
            max_devices=4,
            max_quality="4K",
            features=[],
            is_active=True,
        )

        Subscription.objects.create(
            user=self.host,
            plan=plan,
            status="active",
            expires_at=(
                timezone.now()
                + timedelta(days=30)
            ),
        )

        self.client.force_authenticate(
            user=self.host,
        )

        response = self.client.post(
            reverse("salon-list"),
            {
                "name": "API Room",
                "visibility": "private",
                "capacity": 8,
            },
            format="json",
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_201_CREATED,
        )

        salon = Salon.objects.get(
            id=response.data["id"],
        )

        self.assertEqual(
            salon.host,
            self.host,
        )

        self.assertTrue(
            SalonMember.objects.filter(
                salon=salon,
                user=self.host,
                role=SalonMember.ROLE_HOST,
                left_at__isnull=True,
            ).exists()
        )

    def test_private_salon_hidden_from_outsider(self):
        salon = create_salon(
            host=self.host,
            name="Private Room",
            visibility=Salon.VISIBILITY_PRIVATE,
        )

        self.client.force_authenticate(
            user=self.outsider,
        )

        response = self.client.get(
            reverse(
                "salon-detail",
                kwargs={"pk": salon.pk},
            )
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_404_NOT_FOUND,
        )

    def test_public_salon_visible_to_authenticated_outsider(self):
        salon = create_salon(
            host=self.host,
            name="Public Room",
            visibility=Salon.VISIBILITY_PUBLIC,
        )

        self.client.force_authenticate(
            user=self.outsider,
        )

        response = self.client.get(
            reverse(
                "salon-detail",
                kwargs={"pk": salon.pk},
            )
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_200_OK,
        )

    def test_public_salon_can_be_joined(self):
        salon = create_salon(
            host=self.host,
            name="Public Room",
            visibility=Salon.VISIBILITY_PUBLIC,
        )

        self.client.force_authenticate(
            user=self.member,
        )

        response = self.client.post(
            reverse(
                "salon-join",
                kwargs={"pk": salon.pk},
            ),
            {},
            format="json",
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_200_OK,
        )

        self.assertTrue(
            SalonMember.objects.filter(
                salon=salon,
                user=self.member,
                left_at__isnull=True,
            ).exists()
        )
