from rest_framework import serializers

from apps.catalog.serializers import ContentListSerializer
from apps.profiles.serializers import ProfileSummarySerializer
from core.models import Recommendation, TrendingCache


class RecommendationSerializer(serializers.ModelSerializer):
    profile = ProfileSummarySerializer(read_only=True)
    content = ContentListSerializer(read_only=True)

    class Meta:
        model = Recommendation
        fields = [
            'id',
            'profile',
            'content',
            'score',
            'reason',
            'is_viewed',
            'expires_at',
            'created_at',
        ]
        read_only_fields = fields


class TrendingCacheSerializer(serializers.ModelSerializer):
    content = ContentListSerializer(read_only=True)

    class Meta:
        model = TrendingCache
        fields = ['id', 'content', 'score', 'period', 'rank', 'calculated_at']
        read_only_fields = fields


class RecommendationGenerateSerializer(serializers.Serializer):
    profile_id = serializers.UUIDField(required=False)
    profile = serializers.UUIDField(required=False)
    limit = serializers.IntegerField(required=False, min_value=1, max_value=50)
