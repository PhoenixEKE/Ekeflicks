from rest_framework import serializers


class SalonSocialMatchSerializer(
    serializers.Serializer
):
    user_id = serializers.UUIDField()
    profile_id = serializers.UUIDField()
    display_name = serializers.CharField()

    avatar_url = serializers.CharField(
        allow_blank=True,
    )

    score = serializers.IntegerField()

    reasons = serializers.ListField(
        child=serializers.CharField(),
    )
