from django.contrib.auth import get_user_model
from django.test import TestCase
from rest_framework.test import APIClient

from core.models import Content


User = get_user_model()


class RecommendationExplanationAPITests(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            email="explain@example.com",
            password="test-password",
        )

        self.client = APIClient()

        self.content = Content.objects.create(
            title="Explanation API Target",
            description="Grounded API explanation.",
            type="movie",
            producer_submission_status="approved",
            trending_score=100,
            popularity_score=100,
        )




