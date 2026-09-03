import uuid

from django.db import models

from .base import TimeStampedModel
from .content import Content
from .profiles import Profile
from .seasons import Episode
from .users import User


class VideoAsset(TimeStampedModel):
    """Playable video source generated from an original media file."""

    STATUS_CHOICES = [
        ('draft', 'Draft'),
        ('processing', 'Processing'),
        ('ready', 'Ready'),
        ('failed', 'Failed'),
    ]

    MODERATION_STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('approved', 'Approved'),
        ('rejected', 'Rejected'),
    ]

    DRM_CHOICES = [
        ('none', 'None'),
        ('aes_128', 'HLS AES-128'),
        ('widevine', 'Widevine'),
        ('fairplay', 'FairPlay'),
        ('playready', 'PlayReady'),
        ('axinom', 'Axinom Multi-DRM'),
    ]

    content = models.ForeignKey(
        Content,
        on_delete=models.CASCADE,
        related_name='video_assets'
    )
    episode = models.ForeignKey(
        Episode,
        on_delete=models.CASCADE,
        related_name='video_assets',
        null=True,
        blank=True
    )

    title = models.CharField(max_length=255, blank=True)
    source_file_url = models.URLField(max_length=1000, blank=True)
    source_file_path = models.CharField(max_length=1000, blank=True)
    source_file_size_bytes = models.BigIntegerField(default=0)
    source_uploaded_at = models.DateTimeField(null=True, blank=True)
    source_uploaded_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        related_name='uploaded_video_assets',
        null=True,
        blank=True
    )
    hls_master_url = models.URLField(max_length=1000, blank=True)
    dash_manifest_url = models.URLField(max_length=1000, blank=True)
    thumbnail_url = models.URLField(max_length=1000, blank=True)

    duration_seconds = models.IntegerField(default=0)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='draft')
    moderation_status = models.CharField(
        max_length=20,
        choices=MODERATION_STATUS_CHOICES,
        default='pending'
    )
    moderation_reason = models.TextField(blank=True)
    moderated_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        related_name='moderated_video_assets',
        null=True,
        blank=True
    )
    moderated_at = models.DateTimeField(null=True, blank=True)
    is_default = models.BooleanField(default=True)
    is_downloadable = models.BooleanField(default=True)

    drm_provider = models.CharField(max_length=20, choices=DRM_CHOICES, default='none')
    encryption_key_id = models.CharField(max_length=255, blank=True)

    published_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = 'video_assets'
        indexes = [
            models.Index(fields=['content', 'status']),
            models.Index(fields=['episode', 'status']),
            models.Index(fields=['moderation_status']),
            models.Index(fields=['source_uploaded_by', 'source_uploaded_at']),
            models.Index(fields=['is_default']),
        ]

    def __str__(self):
        title = self.title or self.content.title
        if self.episode:
            return f"{title} - {self.episode.title}"
        return title


class VideoRendition(TimeStampedModel):
    """One HLS/DASH rendition generated for adaptive streaming."""

    QUALITY_CHOICES = [
        ('240p', '240p'),
        ('360p', '360p'),
        ('480p', '480p'),
        ('720p', '720p'),
        ('1080p', '1080p'),
        ('1440p', '1440p'),
        ('2160p', '4K'),
    ]

    asset = models.ForeignKey(
        VideoAsset,
        on_delete=models.CASCADE,
        related_name='renditions'
    )
    quality = models.CharField(max_length=20, choices=QUALITY_CHOICES)
    width = models.IntegerField(default=0)
    height = models.IntegerField(default=0)
    bandwidth = models.IntegerField(default=0)
    codec = models.CharField(max_length=100, blank=True)
    frame_rate = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True)
    hls_playlist_url = models.URLField(max_length=1000, blank=True)
    file_size_bytes = models.BigIntegerField(default=0)
    display_order = models.IntegerField(default=0)

    class Meta:
        db_table = 'video_renditions'
        ordering = ['display_order', 'height']
        unique_together = ['asset', 'quality']
        indexes = [
            models.Index(fields=['asset', 'quality']),
        ]

    def __str__(self):
        return f"{self.asset} - {self.quality}"


class SubtitleTrack(TimeStampedModel):
    """Subtitle or closed-caption track linked to a playable asset."""

    KIND_CHOICES = [
        ('subtitle', 'Subtitle'),
        ('caption', 'Caption'),
    ]

    asset = models.ForeignKey(
        VideoAsset,
        on_delete=models.CASCADE,
        related_name='subtitle_tracks'
    )
    language = models.CharField(max_length=10)
    label = models.CharField(max_length=100)
    kind = models.CharField(max_length=20, choices=KIND_CHOICES, default='subtitle')
    url = models.URLField(max_length=1000)
    is_default = models.BooleanField(default=False)

    class Meta:
        db_table = 'subtitle_tracks'
        ordering = ['language', 'label']
        unique_together = ['asset', 'language', 'kind']

    def __str__(self):
        return f"{self.asset} - {self.label}"


class OfflineDownloadLicense(TimeStampedModel):
    """Offline playback authorization for one profile, asset and device."""

    STATUS_CHOICES = [
        ('active', 'Active'),
        ('expired', 'Expired'),
        ('revoked', 'Revoked'),
    ]

    profile = models.ForeignKey(
        Profile,
        on_delete=models.CASCADE,
        related_name='offline_licenses'
    )
    content = models.ForeignKey(Content, on_delete=models.CASCADE)
    episode = models.ForeignKey(Episode, on_delete=models.CASCADE, null=True, blank=True)
    asset = models.ForeignKey(
        VideoAsset,
        on_delete=models.CASCADE,
        related_name='offline_licenses'
    )

    device_id = models.CharField(max_length=255)
    device_name = models.CharField(max_length=255, blank=True)
    device_type = models.CharField(max_length=50, blank=True)
    max_quality = models.CharField(max_length=20, blank=True)

    offline_token = models.UUIDField(default=uuid.uuid4, unique=True, editable=False)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='active')
    expires_at = models.DateTimeField()
    last_verified_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = 'offline_download_licenses'
        indexes = [
            models.Index(fields=['profile', 'status']),
            models.Index(fields=['device_id', 'status']),
            models.Index(fields=['expires_at']),
        ]

    def __str__(self):
        return f"{self.profile.name} - {self.asset} - {self.device_id}"


class PlaybackLicense(TimeStampedModel):
    """Short-lived streaming authorization for one profile, asset and device."""

    STATUS_CHOICES = [
        ('active', 'Active'),
        ('expired', 'Expired'),
        ('revoked', 'Revoked'),
    ]

    MODE_CHOICES = [
        ('stream', 'Stream'),
        ('offline', 'Offline'),
    ]

    profile = models.ForeignKey(
        Profile,
        on_delete=models.CASCADE,
        related_name='playback_licenses'
    )
    content = models.ForeignKey(Content, on_delete=models.CASCADE)
    episode = models.ForeignKey(Episode, on_delete=models.CASCADE, null=True, blank=True)
    asset = models.ForeignKey(
        VideoAsset,
        on_delete=models.CASCADE,
        related_name='playback_licenses'
    )
    subscription = models.ForeignKey(
        'Subscription',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='playback_licenses'
    )

    device_id = models.CharField(max_length=255)
    device_type = models.CharField(max_length=50, blank=True)
    license_token = models.UUIDField(default=uuid.uuid4, unique=True, editable=False)
    license_mode = models.CharField(max_length=20, choices=MODE_CHOICES, default='stream')
    drm_provider = models.CharField(max_length=20, choices=VideoAsset.DRM_CHOICES, default='none')
    key_id = models.CharField(max_length=255, blank=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='active')
    expires_at = models.DateTimeField()
    last_verified_at = models.DateTimeField(null=True, blank=True)
    metadata = models.JSONField(default=dict, blank=True)

    class Meta:
        db_table = 'playback_licenses'
        indexes = [
            models.Index(fields=['profile', 'status']),
            models.Index(fields=['asset', 'status']),
            models.Index(fields=['device_id', 'status']),
            models.Index(fields=['license_token']),
            models.Index(fields=['expires_at']),
        ]

    def __str__(self):
        return f"{self.profile.name} - {self.asset} - {self.device_id}"


class MediaAnalysisReport(TimeStampedModel):
    """Automated technical QC and AI moderation report for a source video."""

    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('analyzing', 'Analyzing'),
        ('passed', 'Passed'),
        ('review_required', 'Review required'),
        ('failed', 'Failed'),
    ]

    asset = models.OneToOneField(
        VideoAsset,
        on_delete=models.CASCADE,
        related_name='analysis_report',
    )

    status = models.CharField(
        max_length=30,
        choices=STATUS_CHOICES,
        default='pending',
        db_index=True,
    )

    # Technical metadata
    container = models.CharField(max_length=50, blank=True)
    video_codec = models.CharField(max_length=50, blank=True)
    audio_codec = models.CharField(max_length=50, blank=True)

    width = models.PositiveIntegerField(default=0)
    height = models.PositiveIntegerField(default=0)

    frame_rate = models.DecimalField(
        max_digits=8,
        decimal_places=3,
        null=True,
        blank=True,
    )

    video_bitrate = models.BigIntegerField(default=0)
    audio_bitrate = models.BigIntegerField(default=0)

    duration_seconds = models.DecimalField(
        max_digits=12,
        decimal_places=3,
        null=True,
        blank=True,
    )

    audio_channels = models.PositiveSmallIntegerField(default=0)
    sample_rate = models.PositiveIntegerField(default=0)

    # Quality measurements
    loudness_lufs = models.DecimalField(
        max_digits=7,
        decimal_places=3,
        null=True,
        blank=True,
    )

    black_frame_count = models.PositiveIntegerField(default=0)
    freeze_frame_count = models.PositiveIntegerField(default=0)

    technical_score = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        null=True,
        blank=True,
    )

    # AI/moderation scores and detected events.
    moderation_scores = models.JSONField(default=dict, blank=True)
    detected_events = models.JSONField(default=list, blank=True)

    # Complete ffprobe/analysis information for auditing.
    technical_metadata = models.JSONField(default=dict, blank=True)

    flags = models.JSONField(default=list, blank=True)

    analysis_version = models.CharField(
        max_length=50,
        default='eke-qc-v1',
    )

    error_message = models.TextField(blank=True)

    analyzed_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = 'media_analysis_reports'
        indexes = [
            models.Index(fields=['status', 'created_at']),
        ]

    def __str__(self):
        return f"QC {self.asset_id} - {self.status}"
