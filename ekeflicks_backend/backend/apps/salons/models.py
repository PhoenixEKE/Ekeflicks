import uuid

from django.conf import settings
from django.db import models
from django.db.models import Q

from core.models.content import Content


SALON_MODE_VERSION = "g5_3m_v1"


class Salon(models.Model):
    HOST_LEAVE_CLOSE = "close"
    HOST_LEAVE_TRANSFER_OLDEST = "transfer_to_oldest_active_member"

    HOST_LEAVE_POLICY_CHOICES = (
        (HOST_LEAVE_CLOSE, "Close"),
        (
            HOST_LEAVE_TRANSFER_OLDEST,
            "Transfer to oldest active member",
        ),
    )

    MODE_SOCIAL = "social"
    MODE_FRIENDS = "friends"
    MODE_MIXED = "mixed"
    MODE_THEMATIC = "thematic"

    MODE_CHOICES = (
        (MODE_SOCIAL, "Social"),
        (MODE_FRIENDS, "Friends"),
        (MODE_MIXED, "Mixed"),
        (MODE_THEMATIC, "Thematic"),
    )

    VISIBILITY_PRIVATE = "private"
    VISIBILITY_PUBLIC = "public"

    VISIBILITY_CHOICES = (
        (VISIBILITY_PRIVATE, "Private"),
        (VISIBILITY_PUBLIC, "Public"),
    )

    STATUS_OPEN = "open"
    STATUS_CLOSED = "closed"

    STATUS_CHOICES = (
        (STATUS_OPEN, "Open"),
        (STATUS_CLOSED, "Closed"),
    )

    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False,
    )

    name = models.CharField(
        max_length=120,
    )

    host = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="hosted_salons",
    )

    content = models.ForeignKey(
        Content,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="salons",
    )

    visibility = models.CharField(
        max_length=16,
        choices=VISIBILITY_CHOICES,
        default=VISIBILITY_PRIVATE,
        db_index=True,
    )

    mode = models.CharField(
        max_length=16,
        choices=MODE_CHOICES,
        default=MODE_SOCIAL,
        db_index=True,
    )

    status = models.CharField(
        max_length=16,
        choices=STATUS_CHOICES,
        default=STATUS_OPEN,
        db_index=True,
    )

    capacity = models.PositiveSmallIntegerField(
        default=10,
    )

    audio_enabled = models.BooleanField(
        default=True,
    )

    video_enabled = models.BooleanField(
        default=True,
    )

    join_code = models.CharField(
        max_length=64,
        unique=True,
        null=True,
        blank=True,
        editable=False,
        db_index=True,
    )

    host_leave_policy = models.CharField(
        max_length=40,
        choices=HOST_LEAVE_POLICY_CHOICES,
        default=HOST_LEAVE_CLOSE,
    )

    created_at = models.DateTimeField(
        auto_now_add=True,
    )

    updated_at = models.DateTimeField(
        auto_now=True,
    )

    closed_at = models.DateTimeField(
        null=True,
        blank=True,
    )

    class Meta:
        db_table = "salons"
        ordering = ("-created_at",)
        constraints = [
            models.CheckConstraint(
                check=Q(capacity__gte=2)
                & Q(capacity__lte=10),
                name="salon_capacity_2_10",
            ),
        ]
        indexes = [
            models.Index(
                fields=("status", "visibility"),
                name="salon_status_visibility_idx",
            ),
            models.Index(
                fields=("host", "status"),
                name="salon_host_status_idx",
            ),
        ]

    def __str__(self):
        return self.name


class SalonMember(models.Model):
    ROLE_HOST = "host"
    ROLE_MEMBER = "member"

    ROLE_CHOICES = (
        (ROLE_HOST, "Host"),
        (ROLE_MEMBER, "Member"),
    )

    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False,
    )

    salon = models.ForeignKey(
        Salon,
        on_delete=models.CASCADE,
        related_name="memberships",
    )

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="salon_memberships",
    )

    role = models.CharField(
        max_length=16,
        choices=ROLE_CHOICES,
        default=ROLE_MEMBER,
    )

    joined_at = models.DateTimeField(
        auto_now_add=True,
    )

    left_at = models.DateTimeField(
        null=True,
        blank=True,
    )

    class Meta:
        db_table = "salon_members"
        ordering = ("joined_at",)
        constraints = [
            models.UniqueConstraint(
                fields=("salon", "user"),
                condition=Q(left_at__isnull=True),
                name="salon_one_active_membership_per_user",
            ),
            models.UniqueConstraint(
                fields=("salon",),
                condition=Q(
                    role="host",
                    left_at__isnull=True,
                ),
                name="salon_one_active_host",
            ),
        ]
        indexes = [
            models.Index(
                fields=("salon", "left_at"),
                name="salon_member_active_idx",
            ),
            models.Index(
                fields=("user", "left_at"),
                name="salon_user_active_idx",
            ),
        ]

    def __str__(self):
        return f"{self.salon_id}:{self.user_id}:{self.role}"


# ---------------------------------------------------------------------------
# G5-3B — Authoritative synchronized playback state
# ---------------------------------------------------------------------------

from decimal import Decimal


class SalonPlaybackState(models.Model):
    EVENT_SYNC = "sync"
    EVENT_PLAY = "play"
    EVENT_PAUSE = "pause"
    EVENT_SEEK = "seek"
    EVENT_RATE = "rate"

    EVENT_CHOICES = (
        (EVENT_SYNC, "Sync"),
        (EVENT_PLAY, "Play"),
        (EVENT_PAUSE, "Pause"),
        (EVENT_SEEK, "Seek"),
        (EVENT_RATE, "Rate"),
    )

    salon = models.OneToOneField(
        Salon,
        on_delete=models.CASCADE,
        related_name="playback_state",
        primary_key=True,
    )

    position_ms = models.PositiveBigIntegerField(
        default=0,
    )

    is_playing = models.BooleanField(
        default=False,
    )

    playback_rate = models.DecimalField(
        max_digits=4,
        decimal_places=2,
        default=Decimal("1.00"),
    )

    sequence = models.PositiveBigIntegerField(
        default=0,
    )

    last_event = models.CharField(
        max_length=16,
        choices=EVENT_CHOICES,
        default=EVENT_SYNC,
    )

    updated_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="salon_playback_updates",
    )

    updated_at = models.DateTimeField(
        auto_now=True,
    )

    class Meta:
        db_table = "salon_playback_states"
        constraints = [
            models.CheckConstraint(
                check=(
                    Q(playback_rate__gte=Decimal("0.50"))
                    & Q(playback_rate__lte=Decimal("2.00"))
                ),
                name="salon_playback_rate_050_200",
            ),
        ]

    def __str__(self):
        return (
            f"SalonPlaybackState("
            f"salon={self.salon_id}, "
            f"sequence={self.sequence}"
            f")"
        )


class SalonInvitation(models.Model):
    """
    G5-3J — Persistent invitation from a Salon host to one user.

    Membership remains authoritative in SalonMember.
    This model stores only the invitation workflow.
    """

    STATUS_PENDING = "pending"
    STATUS_ACCEPTED = "accepted"
    STATUS_DECLINED = "declined"
    STATUS_CANCELLED = "cancelled"

    STATUS_CHOICES = (
        (STATUS_PENDING, "Pending"),
        (STATUS_ACCEPTED, "Accepted"),
        (STATUS_DECLINED, "Declined"),
        (STATUS_CANCELLED, "Cancelled"),
    )

    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False,
    )

    salon = models.ForeignKey(
        Salon,
        on_delete=models.CASCADE,
        related_name="invitations",
    )

    inviter = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="salon_invitations_sent",
    )

    invitee = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="salon_invitations_received",
    )

    status = models.CharField(
        max_length=16,
        choices=STATUS_CHOICES,
        default=STATUS_PENDING,
        db_index=True,
    )

    created_at = models.DateTimeField(
        auto_now_add=True,
    )

    updated_at = models.DateTimeField(
        auto_now=True,
    )

    responded_at = models.DateTimeField(
        null=True,
        blank=True,
    )

    class Meta:
        db_table = "salon_invitations"

        ordering = (
            "-created_at",
        )

        constraints = (
            models.CheckConstraint(
                check=~Q(inviter=models.F("invitee")),
                name="salon_invitation_no_self",
            ),
            models.UniqueConstraint(
                fields=(
                    "salon",
                    "invitee",
                ),
                condition=Q(
                    status="pending",
                ),
                name="salon_one_pending_invitation_per_user",
            ),
        )

        indexes = (
            models.Index(
                fields=(
                    "salon",
                    "status",
                ),
                name="salon_invite_status_idx",
            ),
            models.Index(
                fields=(
                    "invitee",
                    "status",
                ),
                name="salon_invitee_status_idx",
            ),
        )



class SalonMessage(models.Model):
    """
    Persistent text message for an active Salon.

    G5-3N:
    - text only;
    - author must be an active Salon member at creation time;
    - realtime delivery remains the responsibility of SalonConsumer.
    """

    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False,
    )

    salon = models.ForeignKey(
        Salon,
        on_delete=models.CASCADE,
        related_name="messages",
    )

    author = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="salon_messages",
    )

    text = models.CharField(
        max_length=1000,
    )

    mentions = models.ManyToManyField(
        settings.AUTH_USER_MODEL,
        blank=True,
        related_name="salon_message_mentions",
    )

    is_deleted = models.BooleanField(
        default=False,
        db_index=True,
    )

    deleted_at = models.DateTimeField(
        null=True,
        blank=True,
    )

    deleted_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="moderated_salon_messages",
    )

    created_at = models.DateTimeField(
        auto_now_add=True,
        db_index=True,
    )

    class Meta:
        ordering = (
            "-created_at",
            "-id",
        )
        indexes = [
            models.Index(
                fields=(
                    "salon",
                    "-created_at",
                ),
                name="salon_msg_recent_idx",
            ),
        ]

    def __str__(self):
        return (
            f"{self.salon_id}:"
            f"{self.author_id}:"
            f"{self.id}"
        )


class SalonSessionQuotaEntry(models.Model):
    """
    G5-3O — Premium Salon monthly quota ledger.

    A row is created only by the entitled API creation path.

    RESERVED:
        Salon exists and currently reserves one monthly slot.

    CONSUMED:
        At least one non-host member joined and the Salon remained
        alive for strictly more than five minutes after that join.

    RELEASED:
        Salon closed before becoming a qualifying session.

    The commercial entitlement used at creation is snapshotted in
    plan_slug so later subscription expiry does not rewrite history.
    """

    STATUS_RESERVED = "reserved"
    STATUS_CONSUMED = "consumed"
    STATUS_RELEASED = "released"

    STATUS_CHOICES = (
        (STATUS_RESERVED, "Reserved"),
        (STATUS_CONSUMED, "Consumed"),
        (STATUS_RELEASED, "Released"),
    )

    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False,
    )

    salon = models.OneToOneField(
        Salon,
        on_delete=models.CASCADE,
        related_name="quota_entry",
    )

    host = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="salon_quota_entries",
    )

    period_start = models.DateField(
        db_index=True,
    )

    status = models.CharField(
        max_length=16,
        choices=STATUS_CHOICES,
        default=STATUS_RESERVED,
        db_index=True,
    )

    plan_slug = models.CharField(
        max_length=50,
    )

    first_guest_joined_at = models.DateTimeField(
        null=True,
        blank=True,
    )

    qualified_at = models.DateTimeField(
        null=True,
        blank=True,
    )

    released_at = models.DateTimeField(
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
        db_table = "salon_session_quota_entries"
        ordering = (
            "-created_at",
        )
        indexes = (
            models.Index(
                fields=(
                    "host",
                    "period_start",
                    "status",
                ),
                name="salon_quota_period_idx",
            ),
        )

    def __str__(self):
        return (
            f"{self.host_id}:"
            f"{self.period_start}:"
            f"{self.salon_id}:"
            f"{self.status}"
        )

