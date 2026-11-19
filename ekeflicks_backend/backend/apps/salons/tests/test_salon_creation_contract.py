from datetime import timedelta

from django.contrib.auth import get_user_model
from django.test import TestCase
from django.urls import reverse
from django.utils import timezone
from rest_framework.test import APIClient

from apps.salons.models import Salon
from apps.salons.serializers import SalonCreateSerializer
from apps.salons.services import create_salon
from core.models.subscriptions import (
    Subscription,
    SubscriptionPlan,
)


User = get_user_model()


class SalonCreationContractTests(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            email="g5-3r@example.com",
            password="test-password",
        )

    def test_serializer_accepts_capacity_2(self):
        serializer = SalonCreateSerializer(
            data={
                "name": "G5-3R Minimum",
                "capacity": 2,
            }
        )

        self.assertTrue(
            serializer.is_valid(),
            serializer.errors,
        )
        self.assertEqual(
            serializer.validated_data["capacity"],
            2,
        )

    def test_serializer_accepts_capacity_10(self):
        serializer = SalonCreateSerializer(
            data={
                "name": "G5-3R Maximum",
                "capacity": 10,
            }
        )

        self.assertTrue(
            serializer.is_valid(),
            serializer.errors,
        )
        self.assertEqual(
            serializer.validated_data["capacity"],
            10,
        )

    def test_serializer_rejects_capacity_1(self):
        serializer = SalonCreateSerializer(
            data={
                "name": "G5-3R Too Small",
                "capacity": 1,
            }
        )

        self.assertFalse(serializer.is_valid())
        self.assertIn(
            "capacity",
            serializer.errors,
        )

    def test_serializer_rejects_capacity_11(self):
        serializer = SalonCreateSerializer(
            data={
                "name": "G5-3R Too Large",
                "capacity": 11,
            }
        )

        self.assertFalse(serializer.is_valid())
        self.assertIn(
            "capacity",
            serializer.errors,
        )

    def test_serializer_defaults_creation_contract(self):
        serializer = SalonCreateSerializer(
            data={
                "name": "G5-3R Defaults",
            }
        )

        self.assertTrue(
            serializer.is_valid(),
            serializer.errors,
        )

        self.assertEqual(
            serializer.validated_data["capacity"],
            10,
        )
        self.assertIs(
            serializer.validated_data[
                "audio_enabled"
            ],
            True,
        )
        self.assertIs(
            serializer.validated_data[
                "video_enabled"
            ],
            True,
        )

    def test_serializer_accepts_audio_video_options(self):
        serializer = SalonCreateSerializer(
            data={
                "name": "G5-3R Media",
                "capacity": 6,
                "audio_enabled": False,
                "video_enabled": False,
            }
        )

        self.assertTrue(
            serializer.is_valid(),
            serializer.errors,
        )
        self.assertIs(
            serializer.validated_data[
                "audio_enabled"
            ],
            False,
        )
        self.assertIs(
            serializer.validated_data[
                "video_enabled"
            ],
            False,
        )

    def test_domain_create_persists_media_options(self):
        salon = create_salon(
            host=self.user,
            name="G5-3R Domain",
            capacity=4,
            audio_enabled=False,
            video_enabled=True,
        )

        salon.refresh_from_db()

        self.assertEqual(salon.capacity, 4)
        self.assertFalse(salon.audio_enabled)
        self.assertTrue(salon.video_enabled)

    def test_capacity_counts_host_in_total(self):
        salon = create_salon(
            host=self.user,
            name="G5-3R Capacity",
            capacity=2,
        )

        self.assertEqual(
            salon.memberships.filter(
                left_at__isnull=True,
            ).count(),
            1,
        )

        self.assertEqual(
            salon.capacity,
            2,
        )


class SalonCreationContractApiTests(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            email="g5-3r-api@example.com",
            password="test-password",
        )

        self.plan = SubscriptionPlan.objects.create(
            name="G5-3R Premium",
            slug="premium",
            price=10,
            duration_days=30,
            is_active=True,
        )

        Subscription.objects.create(
            user=self.user,
            plan=self.plan,
            status="active",
            expires_at=(
                timezone.now()
                + timedelta(days=30)
            ),
        )

        self.client = APIClient()
        self.client.force_authenticate(
            user=self.user
        )

        self.url = reverse("salon-list")

    def test_api_create_persists_and_returns_contract(self):
        response = self.client.post(
            self.url,
            {
                "name": "G5-3R API",
                "capacity": 7,
                "audio_enabled": False,
                "video_enabled": True,
            },
            format="json",
        )

        self.assertEqual(
            response.status_code,
            201,
            response.data,
        )

        salon = Salon.objects.get(
            pk=response.data["id"]
        )

        self.assertEqual(salon.capacity, 7)
        self.assertFalse(salon.audio_enabled)
        self.assertTrue(salon.video_enabled)

        self.assertEqual(
            response.data["capacity"],
            7,
        )
        self.assertFalse(
            response.data["audio_enabled"]
        )
        self.assertTrue(
            response.data["video_enabled"]
        )

    def test_api_rejects_capacity_above_10(self):
        response = self.client.post(
            self.url,
            {
                "name": "G5-3R Invalid",
                "capacity": 11,
            },
            format="json",
        )

        self.assertEqual(
            response.status_code,
            400,
            response.data,
        )

        self.assertIn(
            "capacity",
            response.data,
        )
