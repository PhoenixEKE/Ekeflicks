from django.conf import settings
from django.db import models

from core.models.profiles import Profile


class SocialProfile(models.Model):
    """
    Public social identity attached to one viewing Profile.

    Private account/profile fields remain outside this model.
    """

    profile = models.OneToOneField(
        Profile,
        on_delete=models.CASCADE,
        related_name="social_profile",
    )

    display_name = models.CharField(
        max_length=100,
        blank=True,
    )

    bio = models.CharField(
        max_length=280,
        blank=True,
    )

    is_discoverable = models.BooleanField(
        default=False,
        db_index=True,
    )

    created_at = models.DateTimeField(
        auto_now_add=True,
    )

    updated_at = models.DateTimeField(
        auto_now=True,
    )

    class Meta:
        db_table = "social_profiles"

    def __str__(self):
        return (
            self.display_name
            or self.profile.name
            or str(self.profile_id)
        )

    @property
    def public_display_name(self):
        return (
            self.display_name.strip()
            or self.profile.name
        )


# ---------------------------------------------------------------------------
# G5-3G — Social safety and reputation
# ---------------------------------------------------------------------------


class SocialBlock(models.Model):
    """
    Directional persisted block.

    Matching treats a block in either direction as a hard symmetric
    exclusion. The persisted direction remains useful for ownership
    and future moderation/audit.
    """

    blocker = models.ForeignKey(
        SocialProfile,
        on_delete=models.CASCADE,
        related_name="blocks_created",
    )

    blocked = models.ForeignKey(
        SocialProfile,
        on_delete=models.CASCADE,
        related_name="blocks_received",
    )

    created_at = models.DateTimeField(
        auto_now_add=True,
    )

    class Meta:
        db_table = "social_blocks"
        constraints = [
            models.UniqueConstraint(
                fields=("blocker", "blocked"),
                name="social_unique_block",
            ),
            models.CheckConstraint(
                check=~models.Q(
                    blocker=models.F("blocked"),
                ),
                name="social_block_not_self",
            ),
        ]
        indexes = [
            models.Index(
                fields=("blocker", "blocked"),
                name="social_block_pair_idx",
            ),
        ]


class SocialMute(models.Model):
    """
    Directional social discovery mute.

    A requester who muted a candidate does not receive that candidate.
    The reverse direction is intentionally unaffected.
    """

    muter = models.ForeignKey(
        SocialProfile,
        on_delete=models.CASCADE,
        related_name="mutes_created",
    )

    muted = models.ForeignKey(
        SocialProfile,
        on_delete=models.CASCADE,
        related_name="mutes_received",
    )

    created_at = models.DateTimeField(
        auto_now_add=True,
    )

    class Meta:
        db_table = "social_mutes"
        constraints = [
            models.UniqueConstraint(
                fields=("muter", "muted"),
                name="social_unique_mute",
            ),
            models.CheckConstraint(
                check=~models.Q(
                    muter=models.F("muted"),
                ),
                name="social_mute_not_self",
            ),
        ]
        indexes = [
            models.Index(
                fields=("muter", "muted"),
                name="social_mute_pair_idx",
            ),
        ]


class SocialReport(models.Model):
    """
    User safety report.

    G5-3G persists the signal only.
    Automated or human moderation decisions belong to G5-3H.
    """

    REASON_HARASSMENT = "harassment"
    REASON_HATE = "hate"
    REASON_SPAM = "spam"
    REASON_IMPERSONATION = "impersonation"
    REASON_INAPPROPRIATE = "inappropriate"
    REASON_OTHER = "other"

    REASON_CHOICES = (
        (REASON_HARASSMENT, "Harassment"),
        (REASON_HATE, "Hate"),
        (REASON_SPAM, "Spam"),
        (REASON_IMPERSONATION, "Impersonation"),
        (REASON_INAPPROPRIATE, "Inappropriate"),
        (REASON_OTHER, "Other"),
    )

    reporter = models.ForeignKey(
        SocialProfile,
        on_delete=models.CASCADE,
        related_name="reports_created",
    )

    reported = models.ForeignKey(
        SocialProfile,
        on_delete=models.CASCADE,
        related_name="reports_received",
    )

    reason = models.CharField(
        max_length=32,
        choices=REASON_CHOICES,
    )

    details = models.CharField(
        max_length=500,
        blank=True,
    )

    created_at = models.DateTimeField(
        auto_now_add=True,
    )

    class Meta:
        db_table = "social_reports"
        constraints = [
            models.CheckConstraint(
                check=~models.Q(
                    reporter=models.F("reported"),
                ),
                name="social_report_not_self",
            ),
        ]
        indexes = [
            models.Index(
                fields=("reported", "created_at"),
                name="social_report_target_idx",
            ),
            models.Index(
                fields=("reporter", "created_at"),
                name="social_report_owner_idx",
            ),
        ]


class SocialReputation(models.Model):
    """
    Private internal reputation state.

    It is deliberately absent from public social serializers.
    G5-3H may evolve moderation-driven adjustments later.
    """

    profile = models.OneToOneField(
        SocialProfile,
        on_delete=models.CASCADE,
        related_name="reputation",
    )

    score = models.PositiveSmallIntegerField(
        default=100,
    )

    updated_at = models.DateTimeField(
        auto_now=True,
    )

    class Meta:
        db_table = "social_reputations"
        constraints = [
            models.CheckConstraint(
                check=(
                    models.Q(score__gte=0)
                    & models.Q(score__lte=100)
                ),
                name="social_reputation_0_100",
            ),
        ]


class SocialModeration(models.Model):
    """
    G5-3H — Internal moderation state for a SocialProfile.

    PostgreSQL is authoritative for social eligibility.

    active:
        normal social access.

    limited:
        profile remains usable but is excluded from social discovery
        and social matching.

    suspended:
        social participation is disabled.

    This state is private and must never be exposed by public social
    serializers.
    """

    STATUS_ACTIVE = "active"
    STATUS_LIMITED = "limited"
    STATUS_SUSPENDED = "suspended"

    STATUS_CHOICES = (
        (STATUS_ACTIVE, "Active"),
        (STATUS_LIMITED, "Limited"),
        (STATUS_SUSPENDED, "Suspended"),
    )

    profile = models.OneToOneField(
        "SocialProfile",
        on_delete=models.CASCADE,
        related_name="moderation",
    )

    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default=STATUS_ACTIVE,
        db_index=True,
    )

    reason = models.CharField(
        max_length=500,
        blank=True,
    )

    reviewed_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="reviewed_social_moderations",
    )

    reviewed_at = models.DateTimeField(
        null=True,
        blank=True,
    )

    created_at = models.DateTimeField(
        auto_now_add=True,
    )

    updated_at = models.DateTimeField(
        auto_now=True,
    )

    class Meta:
        db_table = "social_moderations"
        indexes = [
            models.Index(
                fields=["status"],
                name="social_mod_status_idx",
            ),
        ]

    def __str__(self):
        return (
            f"{self.profile_id}:"
            f"{self.status}"
        )


