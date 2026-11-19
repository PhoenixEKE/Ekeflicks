from unittest.mock import patch

from django.contrib.auth import get_user_model
from django.test import TestCase

from apps.notifications.services import notify_user


class NotificationEmailDeliveryStateTests(TestCase):
    def setUp(self):
        User = get_user_model()

        self.user = User.objects.create_user(
            email="notification-test@example.com",
            password="Test-password-123!",
        )

    @patch(
        "apps.notifications.services.notification_preferences",
        return_value={
            "email_enabled": True,
            "push_enabled": True,
            "categories": {"account": True},
        },
    )
    @patch("apps.notifications.services.EmailMultiAlternatives.send")
    def test_success_marks_notification_sent(
        self,
        mock_send,
        _mock_preferences,
    ):
        mock_send.return_value = 1

        notification = notify_user(
            self.user,
            "email_verification",
            title="Test",
            message="Test message",
        )

        notification.refresh_from_db()

        self.assertTrue(notification.is_sent)
        self.assertIsNotNone(notification.sent_at)
        mock_send.assert_called_once_with(fail_silently=False)

    @patch(
        "apps.notifications.services.notification_preferences",
        return_value={
            "email_enabled": True,
            "push_enabled": True,
            "categories": {"account": True},
        },
    )
    @patch("apps.notifications.services.EmailMultiAlternatives.send")
    def test_exception_does_not_mark_notification_sent(
        self,
        mock_send,
        _mock_preferences,
    ):
        mock_send.side_effect = RuntimeError("simulated SMTP failure")

        notification = notify_user(
            self.user,
            "email_verification",
            title="Test",
            message="Test message",
        )

        notification.refresh_from_db()

        self.assertFalse(notification.is_sent)
        self.assertIsNone(notification.sent_at)

    @patch(
        "apps.notifications.services.notification_preferences",
        return_value={
            "email_enabled": True,
            "push_enabled": True,
            "categories": {"account": True},
        },
    )
    @patch("apps.notifications.services.EmailMultiAlternatives.send")
    def test_zero_delivery_does_not_mark_notification_sent(
        self,
        mock_send,
        _mock_preferences,
    ):
        mock_send.return_value = 0

        notification = notify_user(
            self.user,
            "email_verification",
            title="Test",
            message="Test message",
        )

        notification.refresh_from_db()

        self.assertFalse(notification.is_sent)
        self.assertIsNone(notification.sent_at)
