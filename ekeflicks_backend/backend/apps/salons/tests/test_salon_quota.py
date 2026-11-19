from datetime import timedelta

from django.contrib.auth import get_user_model
from django.urls import reverse
from django.utils import timezone

from rest_framework import status
from rest_framework.test import APITestCase

from apps.salons.models import (
    SalonMember,
    SalonSessionQuotaEntry,
)
from apps.salons.services import (
    close_salon,
    create_salon,
    join_salon,
)
from core.models.subscriptions import (
    Subscription,
    SubscriptionPlan,
)


User = get_user_model()


class SalonQuotaTests(APITestCase):
    def setUp(self):
        self.host = User.objects.create_user(
            email="quota-host@example.com",
            password="StrongPass123!",
        )

        self.member = User.objects.create_user(
            email="quota-member@example.com",
            password="StrongPass123!",
        )

        self.premium = SubscriptionPlan.objects.create(
            name="Quota Premium",
            slug="premium",
            price="13.99",
            currency="EUR",
            duration_days=30,
            max_profiles=4,
            max_devices=4,
            max_quality="4K",
            download_enabled=True,
            features=[],
            display_order=1,
            is_active=True,
        )

        self.premium_tv = SubscriptionPlan.objects.create(
            name="Quota Premium TV",
            slug="premium-tv",
            price="17.99",
            currency="EUR",
            duration_days=30,
            max_profiles=4,
            max_devices=4,
            max_quality="4K",
            download_enabled=True,
            features=[],
            display_order=2,
            is_active=True,
        )

        self.standard = SubscriptionPlan.objects.create(
            name="Quota Standard",
            slug="standard",
            price="9.99",
            currency="EUR",
            duration_days=30,
            max_profiles=2,
            max_devices=2,
            max_quality="HD",
            download_enabled=True,
            features=[],
            display_order=3,
            is_active=True,
        )

    def _subscribe(
        self,
        plan,
    ):
        return Subscription.objects.create(
            user=self.host,
            plan=plan,
            status="active",
            expires_at=(
                timezone.now()
                + timedelta(days=30)
            ),
        )

    def _api_create(
        self,
        name="Quota Room",
    ):
        self.client.force_authenticate(
            user=self.host,
        )

        return self.client.post(
            reverse("salon-list"),
            {
                "name": name,
                "visibility": "private",
                "capacity": 4,
            },
            format="json",
        )

    def test_standard_subscription_cannot_create_salon(self):
        self._subscribe(
            self.standard
        )

        response = self._api_create()

        self.assertEqual(
            response.status_code,
            status.HTTP_403_FORBIDDEN,
        )

        self.assertEqual(
            SalonSessionQuotaEntry.objects.count(),
            0,
        )

    def test_premium_subscription_creates_reserved_entry(self):
        self._subscribe(
            self.premium
        )

        response = self._api_create()

        self.assertEqual(
            response.status_code,
            status.HTTP_201_CREATED,
        )

        entry = (
            SalonSessionQuotaEntry.objects
            .get(
                salon_id=response.data["id"]
            )
        )

        self.assertEqual(
            entry.status,
            SalonSessionQuotaEntry.STATUS_RESERVED,
        )

        self.assertEqual(
            entry.plan_slug,
            "premium",
        )

    def test_premium_tv_is_eligible(self):
        self._subscribe(
            self.premium_tv
        )

        response = self._api_create(
            "Premium TV Room"
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_201_CREATED,
        )

        entry = (
            SalonSessionQuotaEntry.objects
            .get(
                salon_id=response.data["id"]
            )
        )

        self.assertEqual(
            entry.plan_slug,
            "premium-tv",
        )

    def test_two_reserved_slots_block_third_creation(self):
        self._subscribe(
            self.premium
        )

        first = self._api_create(
            "Room One"
        )
        second = self._api_create(
            "Room Two"
        )
        third = self._api_create(
            "Room Three"
        )

        self.assertEqual(
            first.status_code,
            status.HTTP_201_CREATED,
        )

        self.assertEqual(
            second.status_code,
            status.HTTP_201_CREATED,
        )

        self.assertEqual(
            third.status_code,
            status.HTTP_403_FORBIDDEN,
        )

    def test_empty_closed_salon_releases_slot(self):
        self._subscribe(
            self.premium
        )

        first = self._api_create(
            "Empty Room"
        )

        salon_id = first.data["id"]

        from apps.salons.models import Salon

        salon = Salon.objects.get(
            pk=salon_id
        )

        close_salon(
            salon=salon,
            user=self.host,
        )

        entry = (
            SalonSessionQuotaEntry.objects
            .get(
                salon=salon
            )
        )

        self.assertEqual(
            entry.status,
            SalonSessionQuotaEntry.STATUS_RELEASED,
        )

        replacement = self._api_create(
            "Replacement Room"
        )

        self.assertEqual(
            replacement.status_code,
            status.HTTP_201_CREATED,
        )

    def test_qualifying_session_is_consumed(self):
        self._subscribe(
            self.premium
        )

        response = self._api_create(
            "Qualified Room"
        )

        from apps.salons.models import Salon

        salon = Salon.objects.get(
            pk=response.data["id"]
        )

        membership = join_salon(
            salon=salon,
            user=self.member,
        )

        six_minutes_ago = (
            timezone.now()
            - timedelta(minutes=6)
        )

        SalonMember.objects.filter(
            pk=membership.pk
        ).update(
            joined_at=six_minutes_ago
        )

        close_salon(
            salon=salon,
            user=self.host,
        )

        entry = (
            SalonSessionQuotaEntry.objects
            .get(
                salon=salon
            )
        )

        self.assertEqual(
            entry.status,
            SalonSessionQuotaEntry.STATUS_CONSUMED,
        )

        self.assertIsNotNone(
            entry.qualified_at
        )

    def test_close_is_idempotent_for_quota_entry(self):
        self._subscribe(
            self.premium
        )

        response = self._api_create(
            "Idempotent Room"
        )

        from apps.salons.models import Salon

        salon = Salon.objects.get(
            pk=response.data["id"]
        )

        membership = join_salon(
            salon=salon,
            user=self.member,
        )

        SalonMember.objects.filter(
            pk=membership.pk
        ).update(
            joined_at=(
                timezone.now()
                - timedelta(minutes=6)
            )
        )

        close_salon(
            salon=salon,
            user=self.host,
        )

        close_salon(
            salon=salon,
            user=self.host,
        )

        self.assertEqual(
            SalonSessionQuotaEntry.objects
            .filter(
                salon=salon
            )
            .count(),
            1,
        )

        entry = (
            SalonSessionQuotaEntry.objects
            .get(
                salon=salon
            )
        )

        self.assertEqual(
            entry.status,
            SalonSessionQuotaEntry.STATUS_CONSUMED,
        )

    def test_quota_endpoint_reports_consumed_reserved_remaining(self):
        self._subscribe(
            self.premium
        )

        response = self._api_create(
            "Reserved Room"
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_201_CREATED,
        )

        quota = self.client.get(
            reverse("salon-quota")
        )

        self.assertEqual(
            quota.status_code,
            status.HTTP_200_OK,
        )

        self.assertTrue(
            quota.data["premium_eligible"]
        )

        self.assertEqual(
            quota.data["limit"],
            2,
        )

        self.assertEqual(
            quota.data["consumed"],
            0,
        )

        self.assertEqual(
            quota.data["reserved"],
            1,
        )

        self.assertEqual(
            quota.data["remaining"],
            1,
        )

    def test_domain_create_salon_remains_subscription_agnostic(self):
        salon = create_salon(
            host=self.host,
            name="Internal Domain Room",
            capacity=4,
        )

        self.assertIsNotNone(
            salon.pk
        )

        self.assertFalse(
            SalonSessionQuotaEntry.objects
            .filter(
                salon=salon
            )
            .exists()
        )


class SalonQuotaHardeningTests(SalonQuotaTests):
    def test_guest_leaves_before_five_minutes_does_not_consume(self):
        self._subscribe(
            self.premium
        )

        response = self._api_create(
            "Short Guest Room"
        )

        from apps.salons.models import Salon

        salon = Salon.objects.get(
            pk=response.data["id"]
        )

        membership = join_salon(
            salon=salon,
            user=self.member,
        )

        now = timezone.now()

        SalonMember.objects.filter(
            pk=membership.pk
        ).update(
            joined_at=(
                now
                - timedelta(minutes=10)
            ),
            left_at=(
                now
                - timedelta(minutes=9)
            ),
        )

        close_salon(
            salon=salon,
            user=self.host,
        )

        entry = (
            SalonSessionQuotaEntry.objects
            .get(
                salon=salon
            )
        )

        self.assertEqual(
            entry.status,
            SalonSessionQuotaEntry.STATUS_RELEASED,
        )

    def test_second_guest_can_qualify_after_first_guest_leaves_early(self):
        second_member = User.objects.create_user(
            email="quota-member-2@example.com",
            password="StrongPass123!",
        )

        self._subscribe(
            self.premium
        )

        response = self._api_create(
            "Second Guest Qualifies"
        )

        from apps.salons.models import Salon

        salon = Salon.objects.get(
            pk=response.data["id"]
        )

        first = join_salon(
            salon=salon,
            user=self.member,
        )

        second = join_salon(
            salon=salon,
            user=second_member,
        )

        now = timezone.now()

        SalonMember.objects.filter(
            pk=first.pk
        ).update(
            joined_at=(
                now
                - timedelta(minutes=10)
            ),
            left_at=(
                now
                - timedelta(minutes=9)
            ),
        )

        SalonMember.objects.filter(
            pk=second.pk
        ).update(
            joined_at=(
                now
                - timedelta(minutes=6)
            ),
        )

        close_salon(
            salon=salon,
            user=self.host,
        )

        entry = (
            SalonSessionQuotaEntry.objects
            .get(
                salon=salon
            )
        )

        self.assertEqual(
            entry.status,
            SalonSessionQuotaEntry.STATUS_CONSUMED,
        )

    def test_no_subscription_cannot_create_salon_via_api(self):
        response = self._api_create(
            "No Subscription"
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_403_FORBIDDEN,
        )

        self.assertEqual(
            SalonSessionQuotaEntry.objects.count(),
            0,
        )

    def test_expired_premium_cannot_create_salon(self):
        Subscription.objects.create(
            user=self.host,
            plan=self.premium,
            status="active",
            expires_at=(
                timezone.now()
                - timedelta(seconds=1)
            ),
        )

        response = self._api_create(
            "Expired Premium"
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_403_FORBIDDEN,
        )

        self.assertEqual(
            SalonSessionQuotaEntry.objects.count(),
            0,
        )
