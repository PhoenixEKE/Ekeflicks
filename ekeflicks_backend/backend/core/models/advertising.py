import uuid

from django.conf import settings
from django.db import models

from .base import TimeStampedModel
from .content import Content
from .profiles import Profile


class AdCampaign(TimeStampedModel):
    STATUS_CHOICES = [
        ("draft", "Draft"),
        ("active", "Active"),
        ("paused", "Paused"),
        ("archived", "Archived"),
    ]
    DELIVERY_CHOICES = [
        ("client_side", "Client side"),
        ("ssai", "Server side"),
    ]
    FORMAT_CHOICES = ("preroll", "midroll", "pause")

    name = models.CharField(max_length=160)
    advertiser = models.CharField(max_length=160, blank=True)
    status = models.CharField(max_length=16, choices=STATUS_CHOICES, default="draft", db_index=True)
    delivery_mode = models.CharField(max_length=16, choices=DELIVERY_CHOICES, default="client_side")
    formats = models.JSONField(default=list)
    media_url = models.URLField(max_length=1000, blank=True)
    vast_tag_url = models.URLField(max_length=1000, blank=True)
    image_url = models.URLField(max_length=1000, blank=True)
    media_duration_seconds = models.PositiveSmallIntegerField(default=0)
    cta_label = models.CharField(max_length=80, blank=True)
    cta_url = models.URLField(max_length=1000, blank=True)

    target_countries = models.JSONField(default=list, blank=True)
    contextual_genres = models.JSONField(default=list, blank=True)
    interest_tags = models.JSONField(default=list, blank=True)
    target_age_min = models.PositiveSmallIntegerField(null=True, blank=True)
    target_age_max = models.PositiveSmallIntegerField(null=True, blank=True)
    contents = models.ManyToManyField(Content, blank=True, related_name="ad_campaigns")
    cue_points_seconds = models.JSONField(default=list, blank=True)

    active_from = models.DateTimeField(null=True, blank=True)
    active_until = models.DateTimeField(null=True, blank=True)
    priority = models.SmallIntegerField(default=0)
    delivery_weight = models.PositiveSmallIntegerField(default=100)
    frequency_cap_per_day = models.PositiveSmallIntegerField(default=3)
    skip_after_seconds = models.PositiveSmallIntegerField(null=True, blank=True)
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        related_name="created_ad_campaigns",
        null=True,
        blank=True,
    )

    class Meta:
        db_table = "ad_campaigns"
        ordering = ["-priority", "-created_at"]
        indexes = [
            models.Index(fields=["status", "active_from", "active_until"], name="ad_campaign_status_dates"),
            models.Index(fields=["delivery_mode", "status"], name="ad_campaign_delivery_status"),
        ]

    def __str__(self):
        return self.name


class AdTargetingConsent(TimeStampedModel):
    profile = models.OneToOneField(
        Profile,
        on_delete=models.CASCADE,
        related_name="ad_targeting_consent",
    )
    personalized_ads = models.BooleanField(default=False)
    consent_version = models.CharField(max_length=24, default="1")
    consented_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = "ad_targeting_consents"

    def __str__(self):
        return f"{self.profile_id}: personalized ads {self.personalized_ads}"


class AdEvent(models.Model):
    EVENT_CHOICES = [
        ("request", "Request"),
        ("filled", "Filled"),
        ("impression", "Impression"),
        ("start", "Start"),
        ("first_quartile", "First quartile"),
        ("midpoint", "Midpoint"),
        ("third_quartile", "Third quartile"),
        ("complete", "Complete"),
        ("skip", "Skip"),
        ("click", "Click"),
        ("error", "Error"),
    ]
    PLACEMENT_CHOICES = [
        ("preroll", "Preroll"),
        ("midroll", "Midroll"),
        ("pause", "Pause"),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    event_id = models.UUIDField(default=uuid.uuid4, unique=True, editable=False)
    campaign = models.ForeignKey(
        AdCampaign,
        on_delete=models.SET_NULL,
        related_name="events",
        null=True,
        blank=True,
    )
    content = models.ForeignKey(
        Content,
        on_delete=models.SET_NULL,
        related_name="ad_events",
        null=True,
        blank=True,
    )
    profile = models.ForeignKey(
        Profile,
        on_delete=models.SET_NULL,
        related_name="ad_events",
        null=True,
        blank=True,
    )
    playback_session_id = models.UUIDField(db_index=True)
    event_type = models.CharField(max_length=24, choices=EVENT_CHOICES, db_index=True)
    placement = models.CharField(max_length=12, choices=PLACEMENT_CHOICES)
    device_type = models.CharField(max_length=24, blank=True)
    country_code = models.CharField(max_length=2, blank=True)
    position_seconds = models.PositiveIntegerField(default=0)
    occurred_at = models.DateTimeField(auto_now_add=True, db_index=True)
    metadata = models.JSONField(default=dict, blank=True)

    class Meta:
        db_table = "ad_events"
        indexes = [
            models.Index(fields=["campaign", "occurred_at"], name="ad_events_campaign_time"),
            models.Index(fields=["event_type", "occurred_at"], name="ad_events_type_time"),
            models.Index(fields=["profile", "occurred_at"], name="ad_events_profile_time"),
            models.Index(fields=["playback_session_id", "event_type"], name="ad_events_session_type"),
        ]

    def __str__(self):
        return f"{self.event_type} / {self.placement} / {self.playback_session_id}"
