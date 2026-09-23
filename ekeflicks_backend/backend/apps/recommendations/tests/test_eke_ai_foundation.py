from datetime import timedelta

from django.test import override_settings
from django.urls import reverse
from django.utils import timezone
from rest_framework import status
from rest_framework.test import APITestCase

from apps.recommendations.eke_ai import (
    EKE_AI_FOUNDATION_VERSION,
    eligible_content_ids,
    eligible_content_queryset,
)
from core.models import Content, User


class EkeAIFoundationTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            email="eke-ai-foundation@example.com",
            password="StrongPass123",
            firstname="EKE",
        )

        today = timezone.localdate()

        self.eligible = Content.objects.create(
            title="EKE AI Eligible",
            type="movie",
            producer_submission_status="approved",
            available_from=today - timedelta(days=1),
            available_until=today + timedelta(days=1),
        )

        self.approved_without_dates = (
            Content.objects.create(
                title="EKE AI Always Available",
                type="series",
                producer_submission_status="approved",
                available_from=None,
                available_until=None,
            )
        )

        self.pending = Content.objects.create(
            title="EKE AI Pending",
            type="movie",
            producer_submission_status="pending",
        )

        self.future = Content.objects.create(
            title="EKE AI Future",
            type="movie",
            producer_submission_status="approved",
            available_from=today + timedelta(days=1),
        )

        self.expired = Content.objects.create(
            title="EKE AI Expired",
            type="movie",
            producer_submission_status="approved",
            available_until=today - timedelta(days=1),
        )

    def test_hard_postgresql_eligibility_gate(self):
        ids = set(
            eligible_content_ids()
        )

        self.assertIn(
            self.eligible.id,
            ids,
        )
        self.assertIn(
            self.approved_without_dates.id,
            ids,
        )

        self.assertNotIn(
            self.pending.id,
            ids,
        )
        self.assertNotIn(
            self.future.id,
            ids,
        )
        self.assertNotIn(
            self.expired.id,
            ids,
        )

        self.assertEqual(
            eligible_content_queryset().count(),
            2,
        )

    def test_status_requires_authentication(self):
        response = self.client.get(
            reverse(
                "eke-ai-status"
            )
        )

        self.assertIn(
            response.status_code,
            {
                401,
                403,
            },
        )

    @override_settings(
        NEO4J_ENABLED=False,
        RECOMMENDATION_ENGINE="django",
    )
    def test_status_exposes_foundation_contract(self):
        self.client.force_authenticate(
            user=self.user
        )

        response = self.client.get(
            reverse(
                "eke-ai-status"
            )
        )

        self.assertEqual(
            response.status_code,
            200,
        )

        payload = response.json()

        self.assertEqual(
            payload["version"],
            "g5_2k_v1",
        )

        self.assertEqual(
            payload["status"],
            "ready",
        )

        self.assertEqual(
            payload["components"]["foundation"],
            EKE_AI_FOUNDATION_VERSION,
        )

        self.assertTrue(
            payload["capabilities"]["for_you"]
        )

        self.assertTrue(
            payload["capabilities"]["search"]
        )
