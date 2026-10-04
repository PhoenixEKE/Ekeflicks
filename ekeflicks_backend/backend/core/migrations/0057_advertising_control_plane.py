import uuid

from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):
    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
        ("core", "0056_recurring_subscription_consent"),
    ]

    operations = [
        migrations.CreateModel(
            name="AdCampaign",
            fields=[
                ("id", models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ("created_at", models.DateTimeField(auto_now_add=True, db_index=True)),
                ("updated_at", models.DateTimeField(auto_now=True)),
                ("name", models.CharField(max_length=160)),
                ("advertiser", models.CharField(blank=True, max_length=160)),
                ("status", models.CharField(choices=[("draft", "Draft"), ("active", "Active"), ("paused", "Paused"), ("archived", "Archived")], db_index=True, default="draft", max_length=16)),
                ("delivery_mode", models.CharField(choices=[("client_side", "Client side"), ("ssai", "Server side")], default="client_side", max_length=16)),
                ("formats", models.JSONField(default=list)),
                ("media_url", models.URLField(blank=True, max_length=1000)),
                ("vast_tag_url", models.URLField(blank=True, max_length=1000)),
                ("image_url", models.URLField(blank=True, max_length=1000)),
                ("media_duration_seconds", models.PositiveSmallIntegerField(default=0)),
                ("cta_label", models.CharField(blank=True, max_length=80)),
                ("cta_url", models.URLField(blank=True, max_length=1000)),
                ("target_countries", models.JSONField(blank=True, default=list)),
                ("contextual_genres", models.JSONField(blank=True, default=list)),
                ("interest_tags", models.JSONField(blank=True, default=list)),
                ("target_age_min", models.PositiveSmallIntegerField(blank=True, null=True)),
                ("target_age_max", models.PositiveSmallIntegerField(blank=True, null=True)),
                ("cue_points_seconds", models.JSONField(blank=True, default=list)),
                ("active_from", models.DateTimeField(blank=True, null=True)),
                ("active_until", models.DateTimeField(blank=True, null=True)),
                ("priority", models.SmallIntegerField(default=0)),
                ("delivery_weight", models.PositiveSmallIntegerField(default=100)),
                ("frequency_cap_per_day", models.PositiveSmallIntegerField(default=3)),
                ("skip_after_seconds", models.PositiveSmallIntegerField(blank=True, null=True)),
                ("contents", models.ManyToManyField(blank=True, related_name="ad_campaigns", to="core.content")),
                ("created_by", models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name="created_ad_campaigns", to=settings.AUTH_USER_MODEL)),
            ],
            options={
                "db_table": "ad_campaigns",
                "ordering": ["-priority", "-created_at"],
                "indexes": [
                    models.Index(fields=["status", "active_from", "active_until"], name="ad_campaign_status_dates"),
                    models.Index(fields=["delivery_mode", "status"], name="ad_campaign_delivery_status"),
                ],
            },
        ),
        migrations.CreateModel(
            name="AdTargetingConsent",
            fields=[
                ("id", models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ("created_at", models.DateTimeField(auto_now_add=True, db_index=True)),
                ("updated_at", models.DateTimeField(auto_now=True)),
                ("personalized_ads", models.BooleanField(default=False)),
                ("consent_version", models.CharField(default="1", max_length=24)),
                ("consented_at", models.DateTimeField(blank=True, null=True)),
                ("profile", models.OneToOneField(on_delete=django.db.models.deletion.CASCADE, related_name="ad_targeting_consent", to="core.profile")),
            ],
            options={"db_table": "ad_targeting_consents"},
        ),
        migrations.CreateModel(
            name="AdEvent",
            fields=[
                ("id", models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ("event_id", models.UUIDField(default=uuid.uuid4, editable=False, unique=True)),
                ("playback_session_id", models.UUIDField(db_index=True)),
                ("event_type", models.CharField(choices=[("request", "Request"), ("filled", "Filled"), ("impression", "Impression"), ("start", "Start"), ("first_quartile", "First quartile"), ("midpoint", "Midpoint"), ("third_quartile", "Third quartile"), ("complete", "Complete"), ("skip", "Skip"), ("click", "Click"), ("error", "Error")], db_index=True, max_length=24)),
                ("placement", models.CharField(choices=[("preroll", "Preroll"), ("midroll", "Midroll"), ("pause", "Pause")], max_length=12)),
                ("device_type", models.CharField(blank=True, max_length=24)),
                ("country_code", models.CharField(blank=True, max_length=2)),
                ("position_seconds", models.PositiveIntegerField(default=0)),
                ("occurred_at", models.DateTimeField(auto_now_add=True, db_index=True)),
                ("metadata", models.JSONField(blank=True, default=dict)),
                ("campaign", models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name="events", to="core.adcampaign")),
                ("content", models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name="ad_events", to="core.content")),
                ("profile", models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name="ad_events", to="core.profile")),
            ],
            options={
                "db_table": "ad_events",
                "indexes": [
                    models.Index(fields=["campaign", "occurred_at"], name="ad_events_campaign_time"),
                    models.Index(fields=["event_type", "occurred_at"], name="ad_events_type_time"),
                    models.Index(fields=["profile", "occurred_at"], name="ad_events_profile_time"),
                    models.Index(fields=["playback_session_id", "event_type"], name="ad_events_session_type"),
                ],
            },
        ),
    ]
