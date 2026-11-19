from rest_framework import serializers

from .social_models import SocialConnection


class SocialConnectionSerializer(
    serializers.ModelSerializer
):
    requester_profile_id = serializers.UUIDField(
        source="requester.profile_id",
        read_only=True,
    )

    requester_display_name = serializers.CharField(
        source="requester.public_display_name",
        read_only=True,
    )

    target_profile_id = serializers.UUIDField(
        source="target.profile_id",
        read_only=True,
    )

    target_display_name = serializers.CharField(
        source="target.public_display_name",
        read_only=True,
    )

    class Meta:
        model = SocialConnection
        fields = (
            "id",
            "requester_profile_id",
            "requester_display_name",
            "target_profile_id",
            "target_display_name",
            "status",
            "created_at",
            "updated_at",
            "responded_at",
        )
        read_only_fields = fields


class SocialConnectionCreateSerializer(
    serializers.Serializer
):
    target_profile_id = serializers.UUIDField()
