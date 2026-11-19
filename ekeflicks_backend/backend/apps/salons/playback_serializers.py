from decimal import Decimal

from django.utils import timezone
from rest_framework import serializers

from .models import SalonPlaybackState


class SalonPlaybackStateSerializer(serializers.ModelSerializer):
    salon_id = serializers.UUIDField(
        source="salon.id",
        read_only=True,
    )

    updated_by_id = serializers.UUIDField(
        source="updated_by.id",
        read_only=True,
        allow_null=True,
    )

    server_time = serializers.SerializerMethodField()
    effective_position_ms = serializers.SerializerMethodField()

    class Meta:
        model = SalonPlaybackState
        fields = (
            "salon_id",
            "position_ms",
            "effective_position_ms",
            "is_playing",
            "playback_rate",
            "sequence",
            "last_event",
            "updated_by_id",
            "updated_at",
            "server_time",
        )
        read_only_fields = fields

    def get_server_time(self, obj):
        return timezone.now().isoformat()

    def get_effective_position_ms(self, obj):
        position = int(obj.position_ms)

        if not obj.is_playing:
            return position

        elapsed = max(
            0.0,
            (timezone.now() - obj.updated_at).total_seconds(),
        )

        rate = float(obj.playback_rate)

        return position + int(
            elapsed * 1000.0 * rate
        )


class SalonPlaybackUpdateSerializer(serializers.Serializer):
    expected_sequence = serializers.IntegerField(
        min_value=0,
    )

    position_ms = serializers.IntegerField(
        min_value=0,
        required=False,
    )

    is_playing = serializers.BooleanField(
        required=False,
    )

    playback_rate = serializers.DecimalField(
        max_digits=4,
        decimal_places=2,
        min_value=Decimal("0.50"),
        max_value=Decimal("2.00"),
        required=False,
    )

    event_type = serializers.ChoiceField(
        choices=SalonPlaybackState.EVENT_CHOICES,
        required=False,
    )

    def validate(self, attrs):
        mutable_fields = (
            "position_ms",
            "is_playing",
            "playback_rate",
        )

        if not any(
            field in attrs
            for field in mutable_fields
        ):
            raise serializers.ValidationError(
                "At least one playback field must be provided."
            )

        return attrs
