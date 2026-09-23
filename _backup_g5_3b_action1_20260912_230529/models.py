import uuid

from django.conf import settings
from django.db import models
from django.db.models import Q

from core.models.content import Content


class Salon(models.Model):
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

    status = models.CharField(
        max_length=16,
        choices=STATUS_CHOICES,
        default=STATUS_OPEN,
        db_index=True,
    )

    capacity = models.PositiveSmallIntegerField(
        default=10,
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
                & Q(capacity__lte=100),
                name="salon_capacity_2_100",
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
