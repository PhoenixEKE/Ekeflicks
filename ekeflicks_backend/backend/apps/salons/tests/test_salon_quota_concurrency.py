from concurrent.futures import ThreadPoolExecutor
from datetime import timedelta

from django.contrib.auth import get_user_model
from django.db import (
    close_old_connections,
    connections,
)
from django.test import TransactionTestCase
from django.utils import timezone
from rest_framework.exceptions import PermissionDenied

from apps.salons.models import (
    Salon,
    SalonSessionQuotaEntry,
)
from apps.salons.quota_services import (
    create_entitled_salon,
)
from core.models.subscriptions import (
    Subscription,
    SubscriptionPlan,
)


User = get_user_model()


class SalonQuotaConcurrencyTests(
    TransactionTestCase
):
    reset_sequences = False

    def setUp(self):
        self.host = User.objects.create_user(
            email="quota-concurrency@example.com",
            password="StrongPass123!",
        )

        self.plan = (
            SubscriptionPlan.objects.create(
                name="Concurrency Premium",
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
        )

        Subscription.objects.create(
            user=self.host,
            plan=self.plan,
            status="active",
            expires_at=(
                timezone.now()
                + timedelta(days=30)
            ),
        )

    def _create(self, index):
        close_old_connections()

        try:
            host = User.objects.get(
                pk=self.host.pk
            )

            salon = create_entitled_salon(
                host=host,
                name=f"Concurrent {index}",
                visibility=Salon.VISIBILITY_PRIVATE,
                mode=Salon.MODE_SOCIAL,
                capacity=4,
            )

            return (
                "created",
                str(salon.pk),
            )

        except PermissionDenied:
            return (
                "denied",
                None,
            )

        finally:
            # ThreadPoolExecutor workers keep their own
            # Django/PostgreSQL connection state.
            #
            # close_old_connections() only closes unusable
            # or obsolete connections and can therefore leave
            # an otherwise healthy worker connection attached
            # to test_ekeflicks.
            #
            # Explicitly close every connection owned by this
            # worker before the thread returns so Django can
            # destroy the test database cleanly.
            connections.close_all()

    def test_three_concurrent_creations_never_exceed_two_slots(self):
        with ThreadPoolExecutor(
            max_workers=3
        ) as executor:
            results = list(
                executor.map(
                    self._create,
                    range(3),
                )
            )

        created = [
            result
            for result in results
            if result[0] == "created"
        ]

        denied = [
            result
            for result in results
            if result[0] == "denied"
        ]

        self.assertEqual(
            len(created),
            2,
            results,
        )

        self.assertEqual(
            len(denied),
            1,
            results,
        )

        self.assertEqual(
            SalonSessionQuotaEntry.objects
            .filter(
                host=self.host,
                status=(
                    SalonSessionQuotaEntry
                    .STATUS_RESERVED
                ),
            )
            .count(),
            2,
        )

        self.assertEqual(
            Salon.objects.filter(
                host=self.host,
            ).count(),
            2,
        )

    def test_one_ledger_entry_per_salon(self):
        salon = create_entitled_salon(
            host=self.host,
            name="Unique Ledger",
            visibility=Salon.VISIBILITY_PRIVATE,
            mode=Salon.MODE_SOCIAL,
            capacity=4,
        )

        self.assertEqual(
            SalonSessionQuotaEntry.objects
            .filter(
                salon=salon,
            )
            .count(),
            1,
        )

        self.assertTrue(
            SalonSessionQuotaEntry._meta
            .get_field("salon")
            .one_to_one
        )
