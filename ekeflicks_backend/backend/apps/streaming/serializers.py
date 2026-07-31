from rest_framework import serializers

from apps.profiles.serializers import ProfileSummarySerializer
from core.models import (
    Content,
    Episode,
    OfflineDownloadLicense,
    PlaybackLicense,
    SubtitleTrack,
    VideoAsset,
    VideoRendition,
)


class VideoRenditionSerializer(serializers.ModelSerializer):
    class Meta:
        model = VideoRendition
        fields = [
            'id',
            'quality',
            'width',
            'height',
            'bandwidth',
            'codec',
            'frame_rate',
            'hls_playlist_url',
            'file_size_bytes',
            'display_order',
            'created_at',
            'updated_at',
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


class SubtitleTrackSerializer(serializers.ModelSerializer):
    class Meta:
        model = SubtitleTrack
        fields = [
            'id',
            'language',
            'label',
            'kind',
            'url',
            'is_default',
            'created_at',
            'updated_at',
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


class SubtitleUploadSerializer(serializers.Serializer):
    file = serializers.FileField(required=True)
    language = serializers.CharField(required=True, max_length=10)
    label = serializers.CharField(required=False, allow_blank=True, max_length=100)
    kind = serializers.ChoiceField(
        choices=SubtitleTrack.KIND_CHOICES,
        required=False,
        default='subtitle',
    )
    is_default = serializers.BooleanField(required=False, default=False)

    def validate_language(self, value):
        language = value.strip().lower()
        normalized = language.replace('-', '')
        if not normalized.isalnum():
            raise serializers.ValidationError(
                'La langue doit contenir uniquement des lettres, chiffres ou tirets.'
            )
        return language


class VideoAssetSerializer(serializers.ModelSerializer):
    content = serializers.StringRelatedField(read_only=True)
    episode = serializers.StringRelatedField(read_only=True)
    source_file_url = serializers.URLField(write_only=True, required=False, allow_blank=True)
    encryption_key_id = serializers.CharField(write_only=True, required=False, allow_blank=True)
    content_id = serializers.PrimaryKeyRelatedField(
        source='content',
        queryset=Content.objects.all(),
        write_only=True,
    )
    episode_id = serializers.PrimaryKeyRelatedField(
        source='episode',
        queryset=Episode.objects.all(),
        write_only=True,
        required=False,
        allow_null=True,
    )
    renditions = VideoRenditionSerializer(many=True, read_only=True)
    subtitle_tracks = SubtitleTrackSerializer(many=True, read_only=True)
    source_uploaded_by = serializers.PrimaryKeyRelatedField(read_only=True)
    source_uploaded_by_email = serializers.EmailField(source='source_uploaded_by.email', read_only=True)
    moderated_by_email = serializers.EmailField(source='moderated_by.email', read_only=True)

    class Meta:
        model = VideoAsset
        fields = [
            'id',
            'content',
            'content_id',
            'episode',
            'episode_id',
            'title',
            'source_file_url',
            'source_file_size_bytes',
            'source_uploaded_at',
            'source_uploaded_by',
            'source_uploaded_by_email',
            'hls_master_url',
            'dash_manifest_url',
            'thumbnail_url',
            'duration_seconds',
            'status',
            'moderation_status',
            'moderation_reason',
            'moderated_by',
            'moderated_by_email',
            'moderated_at',
            'is_default',
            'is_downloadable',
            'drm_provider',
            'encryption_key_id',
            'published_at',
            'renditions',
            'subtitle_tracks',
            'created_at',
            'updated_at',
        ]
        read_only_fields = [
            'id',
            'content',
            'episode',
            'source_file_size_bytes',
            'source_uploaded_at',
            'source_uploaded_by',
            'source_uploaded_by_email',
            'moderated_by',
            'moderated_by_email',
            'moderated_at',
            'created_at',
            'updated_at',
        ]

    def validate(self, attrs):
        episode = attrs.get('episode') or getattr(self.instance, 'episode', None)
        content = attrs.get('content') or getattr(self.instance, 'content', None)
        if episode and content and episode.content_id != content.id:
            raise serializers.ValidationError(
                {'episode_id': "L'episode doit appartenir au contenu."}
            )
        return attrs


class VideoAssetModerationSerializer(serializers.Serializer):
    reason = serializers.CharField(required=False, allow_blank=True)


class VideoAssetRejectSerializer(serializers.Serializer):
    reason = serializers.CharField(required=True, allow_blank=False)

    def validate(self, attrs):
        episode = attrs.get('episode') or getattr(self.instance, 'episode', None)
        content = attrs.get('content') or getattr(self.instance, 'content', None)
        if episode and content and episode.content_id != content.id:
            raise serializers.ValidationError(
                {'episode_id': "L'episode doit appartenir au contenu."}
            )
        return attrs


class PlaybackLicenseRequestSerializer(serializers.Serializer):
    profile_id = serializers.UUIDField(required=False)
    profile = serializers.UUIDField(required=False)
    device_id = serializers.CharField(required=True, allow_blank=False)
    device_type = serializers.CharField(required=False, allow_blank=True)
    platform = serializers.ChoiceField(
        choices=['android', 'ios', 'web', 'tv'],
        required=False,
        allow_blank=True,
    )
    drm_system = serializers.ChoiceField(
        choices=['widevine', 'fairplay', 'playready', 'aes_128', ''],
        required=False,
        allow_blank=True,
    )
    offline = serializers.BooleanField(required=False, default=False)


class PlaybackLicenseSerializer(serializers.ModelSerializer):
    profile = ProfileSummarySerializer(read_only=True)

    class Meta:
        model = PlaybackLicense
        fields = [
            'id',
            'profile',
            'content',
            'episode',
            'asset',
            'subscription',
            'device_id',
            'device_type',
            'license_token',
            'license_mode',
            'drm_provider',
            'key_id',
            'status',
            'expires_at',
            'last_verified_at',
            'created_at',
            'updated_at',
        ]
        read_only_fields = fields


class OfflineDownloadLicenseSerializer(serializers.ModelSerializer):
    profile = ProfileSummarySerializer(read_only=True)
    asset = VideoAssetSerializer(read_only=True)

    class Meta:
        model = OfflineDownloadLicense
        fields = [
            'id',
            'profile',
            'content',
            'episode',
            'asset',
            'device_id',
            'device_name',
            'device_type',
            'max_quality',
            'offline_token',
            'status',
            'expires_at',
            'last_verified_at',
            'created_at',
            'updated_at',
        ]
        read_only_fields = fields
