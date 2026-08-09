from django.core import mail, signing
from django.test import TestCase, override_settings
from rest_framework.test import APIClient

from apps.notifications.services import notify_user
from core.models import NotificationType, User


class NotificationApiTests(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            email="viewer@example.com", password="secret"
        )
        self.client = APIClient()
        self.client.force_authenticate(self.user)

    def test_preferences_can_be_read_and_partially_updated(self):
        response = self.client.get("/api/v1/notifications/preferences/")
        self.assertEqual(response.status_code, 200)
        self.assertTrue(response.data["email_enabled"])

        response = self.client.patch(
            "/api/v1/notifications/preferences/",
            {"email_enabled": False, "categories": {"catalog": False}},
            format="json",
        )
        self.assertEqual(response.status_code, 200)
        self.assertFalse(response.data["email_enabled"])
        self.assertFalse(response.data["categories"]["catalog"])
        self.assertTrue(response.data["categories"]["security"])

    def test_unsubscribe_token_disables_email_without_authentication(self):
        token = signing.dumps(str(self.user.pk), salt="notification-unsubscribe")
        anonymous = APIClient()
        response = anonymous.post(
            "/api/v1/notification-unsubscribe/", {"token": token}, format="json"
        )
        self.assertEqual(response.status_code, 200)
        self.user.refresh_from_db()
        self.assertFalse(self.user.preferences["notifications"]["email_enabled"])

    def test_invalid_unsubscribe_token_is_rejected(self):
        response = APIClient().post(
            "/api/v1/notification-unsubscribe/", {"token": "bad"}, format="json"
        )
        self.assertEqual(response.status_code, 400)

    @override_settings(FRONTEND_BASE_URL="https://app.example.com")
    def test_email_contains_unsubscribe_link_and_respects_preferences(self):
        NotificationType.objects.create(
            name="subscription_created", is_email_enabled=True
        )
        notify_user(self.user, "subscription_created")
        self.assertEqual(len(mail.outbox), 1)
        self.assertIn(
            "https://app.example.com/unsubscribe?token=",
            mail.outbox[0].alternatives[0].body,
        )

        self.user.preferences = {
            "notifications": {
                "email_enabled": False,
                "push_enabled": True,
                "categories": {"subscription": True},
            }
        }
        self.user.save(update_fields=["preferences"])
        notify_user(self.user, "subscription_created")
        self.assertEqual(len(mail.outbox), 1)
from django.core import mail, signing
from django.test import TestCase, override_settings
from rest_framework.test import APIClient

from apps.notifications.services import notify_user
from core.models import NotificationType, User


class NotificationApiTests(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            email="viewer@example.com", password="secret"
        )
        self.client = APIClient()
        self.client.force_authenticate(self.user)

    def test_preferences_can_be_read_and_partially_updated(self):
        response = self.client.get("/api/v1/notifications/preferences/")
        self.assertEqual(response.status_code, 200)
        self.assertTrue(response.data["email_enabled"])

        response = self.client.patch(
            "/api/v1/notifications/preferences/",
            {"email_enabled": False, "categories": {"catalog": False}},
            format="json",
        )
        self.assertEqual(response.status_code, 200)
        self.assertFalse(response.data["email_enabled"])
        self.assertFalse(response.data["categories"]["catalog"])
        self.assertTrue(response.data["categories"]["security"])

    def test_unsubscribe_token_disables_email_without_authentication(self):
        token = signing.dumps(str(self.user.pk), salt="notification-unsubscribe")
        anonymous = APIClient()
        response = anonymous.post(
            "/api/v1/notification-unsubscribe/", {"token": token}, format="json"
        )
        self.assertEqual(response.status_code, 200)
        self.user.refresh_from_db()
        self.assertFalse(self.user.preferences["notifications"]["email_enabled"])

    def test_invalid_unsubscribe_token_is_rejected(self):
        response = APIClient().post(
            "/api/v1/notification-unsubscribe/", {"token": "bad"}, format="json"
        )
        self.assertEqual(response.status_code, 400)

    @override_settings(FRONTEND_BASE_URL="https://app.example.com")
    def test_email_contains_unsubscribe_link_and_respects_preferences(self):
        NotificationType.objects.create(
            name="subscription_created", is_email_enabled=True
        )
        notify_user(self.user, "subscription_created")
        self.assertEqual(len(mail.outbox), 1)
        self.assertIn(
            "https://app.example.com/unsubscribe?token=",
            mail.outbox[0].alternatives[0].body,
        )

        self.user.preferences = {
            "notifications": {
                "email_enabled": False,
                "push_enabled": True,
                "categories": {"subscription": True},
            }
        }
        self.user.save(update_fields=["preferences"])
        notify_user(self.user, "subscription_created")
        self.assertEqual(len(mail.outbox), 1)
