from django.contrib.auth import get_user_model
from django.test import TestCase
from rest_framework.test import APIClient

from core.models import (
    Content,
    Like,
)


User = get_user_model()


class FeedbackLearningAPITests(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            email="feedback-api@example.com",
            password="test-password",
        )

        self.profile = (
            self.user.profiles
            .filter(
                is_active=True
            )
            .first()
        )

        self.client = APIClient()

        self.content = Content.objects.create(
            title="Feedback API Target",
            description="Feedback API test.",
            type="movie",
            producer_submission_status="approved",
        )






