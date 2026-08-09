from rest_framework import serializers

from core.models import Notification, NotificationType


NOTIFICATION_CATEGORIES = ("security", "subscription", "catalog", "account")


def notification_preferences(user):
    stored = (user.preferences or {}).get("notifications", {})
    categories = stored.get("categories", {})
    return {
        "email_enabled": stored.get("email_enabled", True),
        "push_enabled": stored.get("push_enabled", True),
        "categories": {
            name: categories.get(name, True) for name in NOTIFICATION_CATEGORIES
        },
    }


class NotificationPreferencesSerializer(serializers.Serializer):
    email_enabled = serializers.BooleanField()
    push_enabled = serializers.BooleanField()
    categories = serializers.DictField(child=serializers.BooleanField())

    def validate_categories(self, value):
        unknown = set(value) - set(NOTIFICATION_CATEGORIES)
        if unknown:
            raise serializers.ValidationError(
                f"Categories inconnues: {', '.join(sorted(unknown))}"
            )
        return value

    def update(self, instance, validated_data):
        current = notification_preferences(instance)
        current.update(
            {key: value for key, value in validated_data.items() if key != "categories"}
        )
        current["categories"].update(validated_data.get("categories", {}))
        preferences = dict(instance.preferences or {})
        preferences["notifications"] = current
        instance.preferences = preferences
        instance.save(update_fields=["preferences", "updated_at"])
        return instance

    def create(self, validated_data):
        raise NotImplementedError


class NotificationTypeSerializer(serializers.ModelSerializer):
    class Meta:
        model = NotificationType
        fields = [
            "id",
            "name",
            "template",
            "is_push_enabled",
            "is_email_enabled",
            "created_at",
        ]
        read_only_fields = ["id", "created_at"]


class NotificationSerializer(serializers.ModelSerializer):
    type = NotificationTypeSerializer(read_only=True)

    class Meta:
        model = Notification
        fields = [
            "id",
            "type",
            "title",
            "message",
            "data",
            "is_read",
            "is_sent",
            "sent_at",
            "created_at",
        ]
        read_only_fields = [
            "id",
            "type",
            "title",
            "message",
            "data",
            "is_sent",
            "sent_at",
            "created_at",
        ]
