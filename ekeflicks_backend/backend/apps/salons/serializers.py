from rest_framework import serializers

from core.models.content import Content

from .models import Salon
from .quota_services import create_entitled_salon


class SalonSerializer(serializers.ModelSerializer):
    host_id = serializers.UUIDField(
        source="host.id",
        read_only=True,
    )

    content_id = serializers.UUIDField(
        source="content.id",
        read_only=True,
        allow_null=True,
    )

    member_count = serializers.SerializerMethodField()

    class Meta:
        model = Salon
        fields = (
            "id",
            "name",
            "host_id",
            "content_id",
            "visibility",
            "mode",
            "status",
            "capacity",
            "audio_enabled",
            "video_enabled",
            "host_leave_policy",
            "member_count",
            "created_at",
            "updated_at",
            "closed_at",
        )
        read_only_fields = (
            "id",
            "host_id",
            "status",
            "member_count",
            "created_at",
            "updated_at",
            "closed_at",
        )

    def get_member_count(self, obj):
        return obj.memberships.filter(
            left_at__isnull=True,
        ).count()


class SalonCreateSerializer(serializers.Serializer):
    name = serializers.CharField(
        max_length=120,
    )

    content_id = serializers.PrimaryKeyRelatedField(
        source="content",
        queryset=Content.objects.all(),
        required=False,
        allow_null=True,
    )

    visibility = serializers.ChoiceField(
        choices=Salon.VISIBILITY_CHOICES,
        default=Salon.VISIBILITY_PRIVATE,
    )

    mode = serializers.ChoiceField(
        choices=Salon.MODE_CHOICES,
        default=Salon.MODE_SOCIAL,
    )

    host_leave_policy = serializers.ChoiceField(
        choices=Salon.HOST_LEAVE_POLICY_CHOICES,
        default=Salon.HOST_LEAVE_CLOSE,
    )

    capacity = serializers.IntegerField(
        min_value=2,
        max_value=10,
        default=10,
    )

    audio_enabled = serializers.BooleanField(
        default=True,
    )

    video_enabled = serializers.BooleanField(
        default=True,
    )

    def create(self, validated_data):
        return create_entitled_salon(
            host=self.context["request"].user,
            **validated_data,
        )


class SalonMemberKickSerializer(serializers.Serializer):
    target_user_id = serializers.UUIDField()


class SalonHostTransferSerializer(serializers.Serializer):
    target_user_id = serializers.UUIDField()




class SalonHostLeavePolicySerializer(
    serializers.Serializer
):
    host_leave_policy = serializers.ChoiceField(
        choices=Salon.HOST_LEAVE_POLICY_CHOICES,
    )


class SalonJoinCodeSerializer(
    serializers.Serializer
):
    join_code = serializers.CharField(
        max_length=64,
        trim_whitespace=True,
    )
