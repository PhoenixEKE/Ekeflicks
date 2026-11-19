from unittest.mock import patch

from django.contrib.auth import get_user_model
from django.test import TestCase
from rest_framework.test import APIClient

from apps.recommendations.observability import (
    REQUEST_ID_HEADER,
    RESPONSE_TIME_HEADER,
    SERVER_TIMING_HEADER,
)


class EkeAIObservabilityTests(TestCase):
    def setUp(self):
        user_model = get_user_model()

        self.user = user_model.objects.create_user(
            email="eke-ai-observability@example.com",
            password="TestPassword123!",
        )

        self.client = APIClient()
        self.client.force_authenticate(
            user=self.user
        )

    def test_status_exposes_observability_headers(self):
        response = self.client.get(
            "/api/v1/eke-ai/status/"
        )

        self.assertEqual(
            response.status_code,
            200,
        )

        self.assertTrue(
            response[REQUEST_ID_HEADER]
        )

        self.assertRegex(
            response[RESPONSE_TIME_HEADER],
            r"^\d+\.\d{2}$",
        )

        self.assertIn(
            "eke_ai;dur=",
            response[SERVER_TIMING_HEADER],
        )

        self.assertIn(
            'desc="status"',
            response[SERVER_TIMING_HEADER],
        )

    def test_global_request_id_is_propagated(self):
        request_id = "g5-2m-test-request"

        with self.assertLogs(
            "apps.recommendations.eke_ai",
            level="INFO",
        ) as captured:
            response = self.client.get(
                "/api/v1/eke-ai/status/",
                HTTP_X_REQUEST_ID=request_id,
            )

        self.assertEqual(
            response.status_code,
            200,
        )

        self.assertEqual(
            response[REQUEST_ID_HEADER],
            request_id,
        )

        self.assertTrue(
            any(
                f"request_id={request_id}" in message
                for message in captured.output
            )
        )

    def test_middleware_generated_request_id_is_reused_in_log(self):
        with self.assertLogs(
            "apps.recommendations.eke_ai",
            level="INFO",
        ) as captured:
            response = self.client.get(
                "/api/v1/eke-ai/status/"
            )

        self.assertEqual(
            response.status_code,
            200,
        )

        request_id = response[
            REQUEST_ID_HEADER
        ]

        self.assertTrue(request_id)

        self.assertTrue(
            any(
                f"request_id={request_id}" in message
                for message in captured.output
            )
        )

    @patch(
        "apps.recommendations.observability."
        "time.perf_counter"
    )
    def test_latency_is_deterministic(
        self,
        perf_counter,
    ):
        perf_counter.side_effect = [
            10.0,
            10.125,
        ]

        response = self.client.get(
            "/api/v1/eke-ai/status/"
        )

        self.assertEqual(
            response.status_code,
            200,
        )

        self.assertEqual(
            response[RESPONSE_TIME_HEADER],
            "125.00",
        )

        self.assertIn(
            "eke_ai;dur=125.00",
            response[SERVER_TIMING_HEADER],
        )
