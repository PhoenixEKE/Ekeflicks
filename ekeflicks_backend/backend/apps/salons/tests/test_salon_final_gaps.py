from apps.salons.services import (
    transfer_salon_host,
    update_salon_host_leave_policy,
)
from rest_framework.exceptions import PermissionDenied
from django.contrib.auth import get_user_model
from django.core.cache import cache
from django.test import TestCase
from rest_framework.exceptions import (
    PermissionDenied,
    ValidationError,
)

from apps.salons.chat_services import (
    create_salon_message,
    moderate_delete_salon_message,
)
from apps.salons.models import (
    Salon,
    SalonMember,
)
from apps.salons.services import (
    create_salon,
    join_salon,
    join_salon_by_code,
    leave_salon,
    leave_salon_as_host,
)
from apps.salons.throttles import (
    REALTIME_LIMIT,
    allow_salon_realtime_event,
)


User = get_user_model()


class SalonFinalGapsTests(TestCase):
    def make_user(self, suffix):
        return User.objects.create_user(
            email=f"g5s-{suffix}@example.com",
            password="test-password",
        )

    def make_salon(
        self,
        *,
        host,
        capacity=10,
        policy=Salon.HOST_LEAVE_CLOSE,
    ):
        return create_salon(
            host=host,
            name="G5-3S Test Salon",
            capacity=capacity,
            host_leave_policy=policy,
        )

    def test_join_code_is_generated_and_can_join(self):
        host = self.make_user("host-code")
        guest = self.make_user("guest-code")

        salon = self.make_salon(
            host=host,
        )

        self.assertTrue(
            salon.join_code
        )

        membership = join_salon_by_code(
            join_code=salon.join_code,
            user=guest,
        )

        self.assertEqual(
            membership.user_id,
            guest.pk,
        )

        self.assertEqual(
            membership.salon_id,
            salon.pk,
        )

    def test_join_code_preserves_capacity(self):
        host = self.make_user("host-capacity")
        guest = self.make_user("guest-capacity")
        extra = self.make_user("extra-capacity")

        salon = self.make_salon(
            host=host,
            capacity=2,
        )

        join_salon_by_code(
            join_code=salon.join_code,
            user=guest,
        )

        with self.assertRaises(
            ValidationError
        ):
            join_salon_by_code(
                join_code=salon.join_code,
                user=extra,
            )

    def test_join_code_rejects_closed_salon(self):
        host = self.make_user("host-closed")
        guest = self.make_user("guest-closed")

        salon = self.make_salon(
            host=host,
        )

        salon.status = Salon.STATUS_CLOSED
        salon.save(
            update_fields=("status",)
        )

        with self.assertRaises(
            ValidationError
        ):
            join_salon_by_code(
                join_code=salon.join_code,
                user=guest,
            )

    def test_host_leave_default_closes_salon(self):
        host = self.make_user("host-close")
        guest = self.make_user("guest-close")

        salon = self.make_salon(
            host=host,
        )

        join_salon(
            salon=salon,
            user=guest,
        )

        leave_salon_as_host(
            salon=salon,
            user=host,
        )

        salon.refresh_from_db()

        self.assertEqual(
            salon.status,
            Salon.STATUS_CLOSED,
        )

    def test_host_leave_transfers_to_oldest_member(self):
        host = self.make_user("host-transfer")
        oldest = self.make_user("oldest")
        newest = self.make_user("newest")

        salon = self.make_salon(
            host=host,
            policy=(
                Salon
                .HOST_LEAVE_TRANSFER_OLDEST
            ),
        )

        join_salon(
            salon=salon,
            user=oldest,
        )

        join_salon(
            salon=salon,
            user=newest,
        )

        leave_salon_as_host(
            salon=salon,
            user=host,
        )

        salon.refresh_from_db()

        self.assertEqual(
            salon.status,
            Salon.STATUS_OPEN,
        )

        self.assertEqual(
            salon.host_id,
            oldest.pk,
        )

        old_host_membership = (
            SalonMember.objects.get(
                salon=salon,
                user=host,
            )
        )

        self.assertIsNotNone(
            old_host_membership.left_at
        )

        new_host_membership = (
            SalonMember.objects.get(
                salon=salon,
                user=oldest,
                left_at__isnull=True,
            )
        )

        self.assertEqual(
            new_host_membership.role,
            SalonMember.ROLE_HOST,
        )

    def test_mentions_accept_active_members(self):
        host = self.make_user("host-mention")
        guest = self.make_user("guest-mention")

        salon = self.make_salon(
            host=host,
        )

        join_salon(
            salon=salon,
            user=guest,
        )

        message = create_salon_message(
            salon=salon,
            user=host,
            text="Hello",
            mention_ids=[
                guest.pk,
            ],
        )

        self.assertEqual(
            list(
                message.mentions.values_list(
                    "pk",
                    flat=True,
                )
            ),
            [guest.pk],
        )

    def test_mentions_reject_non_member(self):
        host = self.make_user("host-invalid-mention")
        outsider = self.make_user("outsider")

        salon = self.make_salon(
            host=host,
        )

        with self.assertRaises(
            ValidationError
        ):
            create_salon_message(
                salon=salon,
                user=host,
                text="Hello",
                mention_ids=[
                    outsider.pk,
                ],
            )

    def test_host_can_soft_delete_message(self):
        host = self.make_user("host-delete")
        guest = self.make_user("guest-delete")

        salon = self.make_salon(
            host=host,
        )

        join_salon(
            salon=salon,
            user=guest,
        )

        message = create_salon_message(
            salon=salon,
            user=guest,
            text="Persistent audit message",
        )

        moderate_delete_salon_message(
            salon=salon,
            user=host,
            message=message,
        )

        message.refresh_from_db()

        self.assertTrue(
            message.is_deleted
        )

        self.assertIsNotNone(
            message.deleted_at
        )

        self.assertEqual(
            message.deleted_by_id,
            host.pk,
        )

        # Audit/history content is still present
        # in persistent storage.
        self.assertEqual(
            message.text,
            "Persistent audit message",
        )

    def test_member_cannot_delete_another_message(self):
        host = self.make_user("host-deny-delete")
        guest = self.make_user("guest-deny-delete")

        salon = self.make_salon(
            host=host,
        )

        join_salon(
            salon=salon,
            user=guest,
        )

        message = create_salon_message(
            salon=salon,
            user=host,
            text="Host message",
        )

        with self.assertRaises(
            PermissionDenied
        ):
            moderate_delete_salon_message(
                salon=salon,
                user=guest,
                message=message,
            )

    def test_realtime_throttle_is_deterministic(self):
        cache.clear()

        host = self.make_user("host-throttle")
        salon = self.make_salon(
            host=host,
        )

        for _ in range(
            REALTIME_LIMIT
        ):
            self.assertTrue(
                allow_salon_realtime_event(
                    user_id=host.pk,
                    salon_id=salon.pk,
                )
            )

        self.assertFalse(
            allow_salon_realtime_event(
                user_id=host.pk,
                salon_id=salon.pk,
            )
        )


class SalonHostLeavePolicyConfigurationTests(
    TestCase
):
    def setUp(self):
        User = get_user_model()

        self.host = User.objects.create_user(
            email="g5s-policy-host@example.com",
            password="test-password",
        )

        self.member = User.objects.create_user(
            email="g5s-policy-member@example.com",
            password="test-password",
        )

        self.salon = create_salon(
            host=self.host,
            name="G5-S Policy Salon",
        )

        join_salon(
            salon=self.salon,
            user=self.member,
        )

    def test_current_host_can_update_policy(self):
        salon = update_salon_host_leave_policy(
            salon=self.salon,
            user=self.host,
            host_leave_policy=(
                Salon.HOST_LEAVE_TRANSFER_OLDEST
            ),
        )

        salon.refresh_from_db()

        self.assertEqual(
            salon.host_leave_policy,
            Salon.HOST_LEAVE_TRANSFER_OLDEST,
        )

    def test_member_cannot_update_policy(self):
        with self.assertRaises(PermissionDenied):
            update_salon_host_leave_policy(
                salon=self.salon,
                user=self.member,
                host_leave_policy=(
                    Salon.HOST_LEAVE_TRANSFER_OLDEST
                ),
            )

    def test_former_host_loses_policy_authority(self):
        transfer_salon_host(
            salon=self.salon,
            user=self.host,
            target_user=self.member,
        )

        with self.assertRaises(PermissionDenied):
            update_salon_host_leave_policy(
                salon=self.salon,
                user=self.host,
                host_leave_policy=(
                    Salon.HOST_LEAVE_TRANSFER_OLDEST
                ),
            )

        salon = update_salon_host_leave_policy(
            salon=self.salon,
            user=self.member,
            host_leave_policy=(
                Salon.HOST_LEAVE_TRANSFER_OLDEST
            ),
        )

        self.assertEqual(
            salon.host_leave_policy,
            Salon.HOST_LEAVE_TRANSFER_OLDEST,
        )
