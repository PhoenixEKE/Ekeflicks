from rest_framework import serializers

from core.models import Notification, NotificationType


class NotificationTypeSerializer(serializers.ModelSerializer):
    class Meta:
        model = NotificationType
        fields = ['id', 'name', 'template', 'is_push_enabled', 'is_email_enabled', 'created_at']
        read_only_fields = ['id', 'created_at']


class NotificationSerializer(serializers.ModelSerializer):
    type = NotificationTypeSerializer(read_only=True)

    class Meta:
        model = Notification
        fields = [
            'id',
            'type',
            'title',
            'message',
            'data',
            'is_read',
            'is_sent',
            'sent_at',
            'created_at',
        ]
        read_only_fields = ['id', 'type', 'title', 'message', 'data', 'is_sent', 'sent_at', 'created_at']
