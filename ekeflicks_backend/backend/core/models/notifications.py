import uuid
from django.db import models
from .users import User


class NotificationType(models.Model):
    name = models.CharField(max_length=50, unique=True)
    template = models.TextField(blank=True)
    is_push_enabled = models.BooleanField(default=True)
    is_email_enabled = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'notification_types'

    def __str__(self):
        return self.name


class Notification(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='notifications')
    type = models.ForeignKey(NotificationType, on_delete=models.CASCADE)

    title = models.CharField(max_length=255, blank=True)
    message = models.TextField(blank=True)

    data = models.JSONField(default=dict)   # 🔥 FIX ICI (pas list)

    is_read = models.BooleanField(default=False)
    is_sent = models.BooleanField(default=False)

    sent_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'notifications'
        indexes = [
            models.Index(fields=['user', 'created_at']),
            models.Index(fields=['is_read']),
            models.Index(fields=['is_sent']),
        ]

    def __str__(self):
        return f"{self.user.email} - {self.type.name}"
