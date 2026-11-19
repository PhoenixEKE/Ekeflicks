from django.contrib.auth import get_user_model
from django.test import TestCase
from rest_framework.test import APIClient

from core.models import Content


User = get_user_model()


class EkeAIIntelligentSearchAPITests(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            email="search@example.com",
            password="test-password",
        )

        self.client = APIClient()

        self.content = Content.objects.create(
            title="Search Target",
            description="Grounded catalogue result.",
            type="movie",
            producer_submission_status="approved",
        )



