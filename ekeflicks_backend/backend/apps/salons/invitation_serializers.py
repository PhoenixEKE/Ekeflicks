from django.contrib.auth import get_user_model
from rest_framework import serializers

from .models import SalonInvitation


User = get_user_model()


class SalonInvitationSerializer(serializers.ModelSerializer):
    salon_id = serializers.UUIDField(
        source="salon.id",
        read_only=True,
    )

    inviter_id = serializers.IntegerField(
        source="inviter.id",
        read_only=True,
    )

    invitee_id = serializers.IntegerField(
        source="invitee.id",
        read_only=True,
    )

    class Meta:
        model = SalonInvitation
        fields = (
            "id",
            "salon_id",
            "inviter_id",
            "invitee_id",
            "status",
            "created_at",
            "updated_at",
            "responded_at",
        )
        read_only_fields = fields


class SalonInvitationCreateSerializer(serializers.Serializer):
    invitee_id = serializers.IntegerField()

    def validate_invitee_id(self, value):
        if not User.objects.filter(pk=value).exists():
            raise serializers.ValidationError(
                "User does not exist."
            )

        return value
