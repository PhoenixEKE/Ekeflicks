from django.contrib.auth import get_user_model
from django.test import TestCase
from django.urls import resolve
from rest_framework.test import APIClient

from core.models import Content


User = get_user_model()


class PublicEkeAIAPITests(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            email="public-eke-ai@example.com",
            password="test-password",
        )

        self.profile = (
            self.user.profiles
            .filter(
                is_active=True
            )
            .first()
        )

        self.assertIsNotNone(
            self.profile
        )

        self.client = APIClient()

        self.content = Content.objects.create(
            title="Public EKE AI Target",
            description=(
                "Stable client API target."
            ),
            type="movie",
            producer_submission_status="approved",
            trending_score=100,
            popularity_score=100,
        )

    def _authenticate(self):
        self.client.force_authenticate(
            user=self.user
        )

    def test_status_requires_authentication(self):
        response = self.client.get(
            "/api/v1/eke-ai/status/"
        )

        self.assertIn(
            response.status_code,
            {
                401,
                403,
            },
        )

    def test_status_contract(self):
        self._authenticate()

        response = self.client.get(
            "/api/v1/eke-ai/status/"
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

        self.assertTrue(
            payload["capabilities"]["for_you"]
        )

        self.assertTrue(
            payload["capabilities"]["search"]
        )

        self.assertTrue(
            payload["capabilities"]["chat"]
        )

        self.assertTrue(
            payload["capabilities"]["explain"]
        )

        self.assertTrue(
            payload["capabilities"]["feedback"]
        )

    def test_for_you_requires_authentication(self):
        response = self.client.get(
            "/api/v1/eke-ai/for-you/"
        )

        self.assertIn(
            response.status_code,
            {
                401,
                403,
            },
        )

    def test_for_you_returns_authorized_content(self):
        self._authenticate()

        response = self.client.get(
            "/api/v1/eke-ai/for-you/?limit=10"
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

        ids = {
            item["content_id"]
            for item
            in payload["recommendations"]
        }

        self.assertIn(
            str(
                self.content.id
            ),
            ids,
        )

    def test_search_requires_authentication(self):
        response = self.client.post(
            "/api/v1/eke-ai/search/",
            {
                "query": self.content.title,
            },
            format="json",
        )

        self.assertIn(
            response.status_code,
            {
                401,
                403,
            },
        )

    def test_search_public_contract(self):
        self._authenticate()

        response = self.client.post(
            "/api/v1/eke-ai/search/",
            {
                "query": self.content.title,
            },
            format="json",
        )

        self.assertEqual(
            response.status_code,
            200,
        )

        payload = response.json()

        self.assertEqual(
            payload["api_version"],
            "g5_2k_v1",
        )

        self.assertEqual(
            payload["version"],
            "g5_2g_v1",
        )

        self.assertEqual(
            payload["result_count"],
            1,
        )

        self.assertEqual(
            payload["results"][0]["content_id"],
            str(
                self.content.id
            ),
        )

    def test_chat_requires_authentication(self):
        response = self.client.post(
            "/api/v1/eke-ai/chat/",
            {
                "message": "help",
            },
            format="json",
        )

        self.assertIn(
            response.status_code,
            {
                401,
                403,
            },
        )

    def test_chat_public_contract(self):
        self._authenticate()

        response = self.client.post(
            "/api/v1/eke-ai/chat/",
            {
                "message": "help",
            },
            format="json",
        )

        self.assertEqual(
            response.status_code,
            200,
        )

        payload = response.json()

        self.assertEqual(
            payload["api_version"],
            "g5_2k_v1",
        )

        self.assertEqual(
            payload["version"],
            "g5_2h_v1",
        )

        self.assertEqual(
            payload["intent"],
            "help",
        )

    def test_explain_requires_authentication(self):
        response = self.client.post(
            "/api/v1/eke-ai/explain/",
            {
                "content_id": str(
                    self.content.id
                ),
            },
            format="json",
        )

        self.assertIn(
            response.status_code,
            {
                401,
                403,
            },
        )

    def test_explain_invalid_content_is_grounded_400(self):
        self._authenticate()

        response = self.client.post(
            "/api/v1/eke-ai/explain/",
            {
                "content_id": (
                    "00000000-0000-0000-0000-000000000001"
                ),
            },
            format="json",
        )

        self.assertEqual(
            response.status_code,
            400,
        )

        self.assertIn(
            "detail",
            response.json(),
        )

    def test_feedback_requires_authentication(self):
        response = self.client.post(
            "/api/v1/eke-ai/feedback/",
            {
                "content_id": str(
                    self.content.id
                ),
                "action": "like",
            },
            format="json",
        )

        self.assertIn(
            response.status_code,
            {
                401,
                403,
            },
        )

    def test_feedback_invalid_content_is_grounded_400(self):
        self._authenticate()

        response = self.client.post(
            "/api/v1/eke-ai/feedback/",
            {
                "content_id": (
                    "00000000-0000-0000-0000-000000000001"
                ),
                "action": "like",
            },
            format="json",
        )

        self.assertEqual(
            response.status_code,
            400,
        )

        self.assertIn(
            "detail",
            response.json(),
        )

    def test_public_route_names(self):
        expected = {
            "/api/v1/eke-ai/status/":
                "eke-ai-status",

            "/api/v1/eke-ai/for-you/":
                "eke-ai-for-you",

            "/api/v1/eke-ai/search/":
                "eke-ai-search",

            "/api/v1/eke-ai/chat/":
                "eke-ai-chat",

            "/api/v1/eke-ai/explain/":
                "eke-ai-explain",

            "/api/v1/eke-ai/feedback/":
                "eke-ai-feedback",
        }

        for path, name in expected.items():
            with self.subTest(
                path=path
            ):
                self.assertEqual(
                    resolve(
                        path
                    ).url_name,
                    name,
                )

    def test_invalid_for_you_limit_is_400(self):
        self._authenticate()

        response = self.client.get(
            "/api/v1/eke-ai/for-you/?limit=999"
        )

        self.assertEqual(
            response.status_code,
            400,
        )
