from rest_framework import serializers


class SalonSocialMatchSerializer(serializers.Serializer):
    user_id = serializers.UUIDField()
    profile_id = serializers.UUIDField()
    profile_name = serializers.CharField()
    avatar_url = serializers.CharField(
        allow_blank=True,
    )
    country_code = serializers.CharField(
        allow_blank=True,
    )
    score = serializers.IntegerField()
    reasons = serializers.ListField(
        child=serializers.CharField(),
    )
    common_genre_ids = serializers.ListField()
    common_content_ids = serializers.ListField()
