from __future__ import annotations

from datetime import date
from datetime import timedelta
from datetime import timezone as dt_timezone
from typing import Any

from django.contrib.auth import get_user_model
from django.db import transaction
from django.utils import timezone
from rest_framework.exceptions import PermissionDenied

from apps.streaming.services import get_active_subscription

from .models import (
    Salon,
    SalonMember,
    SalonSessionQuotaEntry,
)


G5_3O_QUOTA_VERSION = "g5_3o_v1"

SALON_MONTHLY_SESSION_LIMIT = 2

PREMIUM_PLAN_SLUGS = frozenset(
    {
        "premium",
        "premium-tv",
    }
)

QUALIFICATION_DURATION = timedelta(
    minutes=5,
)


def _utc_period_start(value) -> date:
    if value is None:
        value = timezone.now()

    if timezone.is_naive(value):
        value = timezone.make_aware(
            value,
            dt_timezone.utc,
        )

    value = value.astimezone(
        dt_timezone.utc
    )

    return date(
        value.year,
        value.month,
        1,
    )


def _premium_subscription(user):
    subscription = get_active_subscription(
        user
    )

    if subscription is None:
        return None

    slug = str(
        subscription.plan.slug or ""
    ).strip().lower()

    if slug not in PREMIUM_PLAN_SLUGS:
        return None

    return subscription


def require_salon_premium_subscription(user):
    subscription = _premium_subscription(
        user
    )

    if subscription is None:
        raise PermissionDenied(
            "A Premium subscription is required "
            "to create a Salon."
        )

    return subscription


def _guest_memberships(salon):
    return (
        SalonMember.objects
        .filter(
            salon=salon,
            role=SalonMember.ROLE_MEMBER,
        )
        .order_by(
            "joined_at",
            "pk",
        )
    )


def _qualifying_guest_membership(
    *,
    salon,
    effective_end,
):
    """
    Return the earliest guest membership whose effective
    presence lasted strictly more than five minutes.

    A guest who leaves early must not qualify the Salon
    merely because the host keeps it open afterwards.
    """

    if effective_end is None:
        return None, None

    for membership in _guest_memberships(
        salon
    ):
        member_end = (
            membership.left_at
            or effective_end
        )

        # A membership end can never extend beyond
        # the Salon evaluation boundary.
        if member_end > effective_end:
            member_end = effective_end

        qualification_time = (
            membership.joined_at
            + QUALIFICATION_DURATION
        )

        if member_end > qualification_time:
            return (
                membership,
                qualification_time,
            )

    return None, None


def _reconcile_entry(
    *,
    entry: SalonSessionQuotaEntry,
    now=None,
):
    if (
        entry.status
        != SalonSessionQuotaEntry.STATUS_RESERVED
    ):
        return entry

    if now is None:
        now = timezone.now()

    salon = (
        Salon.objects
        .select_for_update()
        .get(
            pk=entry.salon_id
        )
    )

    effective_end = (
        salon.closed_at
        if salon.status
        == Salon.STATUS_CLOSED
        else now
    )

    (
        qualifying_guest,
        qualification_time,
    ) = _qualifying_guest_membership(
        salon=salon,
        effective_end=effective_end,
    )

    if qualifying_guest is not None:
        entry.status = (
            SalonSessionQuotaEntry
            .STATUS_CONSUMED
        )
        entry.first_guest_joined_at = (
            qualifying_guest.joined_at
        )
        entry.qualified_at = (
            qualification_time
        )
        entry.released_at = None

        entry.save(
            update_fields=(
                "status",
                "first_guest_joined_at",
                "qualified_at",
                "released_at",
                "updated_at",
            )
        )

        return entry

    if (
        salon.status
        == Salon.STATUS_CLOSED
    ):
        first_guest = (
            _guest_memberships(
                salon
            )
            .first()
        )

        entry.status = (
            SalonSessionQuotaEntry
            .STATUS_RELEASED
        )
        entry.first_guest_joined_at = (
            first_guest.joined_at
            if first_guest is not None
            else None
        )
        entry.released_at = (
            salon.closed_at
            or now
        )

        entry.save(
            update_fields=(
                "status",
                "first_guest_joined_at",
                "released_at",
                "updated_at",
            )
        )

    return entry


def _reconcile_period_entries(
    *,
    host,
    period_start,
    now=None,
):
    entries = list(
        SalonSessionQuotaEntry.objects
        .select_for_update()
        .select_related(
            "salon",
        )
        .filter(
            host=host,
            period_start=period_start,
            status=(
                SalonSessionQuotaEntry
                .STATUS_RESERVED
            ),
        )
        .order_by(
            "created_at",
            "pk",
        )
    )

    for entry in entries:
        _reconcile_entry(
            entry=entry,
            now=now,
        )


def _period_counts(
    *,
    host,
    period_start,
):
    queryset = (
        SalonSessionQuotaEntry.objects
        .filter(
            host=host,
            period_start=period_start,
        )
    )

    consumed = queryset.filter(
        status=(
            SalonSessionQuotaEntry
            .STATUS_CONSUMED
        )
    ).count()

    reserved = queryset.filter(
        status=(
            SalonSessionQuotaEntry
            .STATUS_RESERVED
        )
    ).count()

    return consumed, reserved


@transaction.atomic
def create_entitled_salon(
    *,
    host,
    name,
    content=None,
    visibility="private",
    mode=Salon.MODE_SOCIAL,
    capacity=10,
    audio_enabled=True,
    video_enabled=True,
    host_leave_policy=Salon.HOST_LEAVE_CLOSE,
):
    User = get_user_model()

    host = (
        User.objects
        .select_for_update()
        .get(
            pk=host.pk
        )
    )

    subscription = (
        require_salon_premium_subscription(
            host
        )
    )

    now = timezone.now()

    period_start = _utc_period_start(
        now
    )

    _reconcile_period_entries(
        host=host,
        period_start=period_start,
        now=now,
    )

    consumed, reserved = (
        _period_counts(
            host=host,
            period_start=period_start,
        )
    )

    if (
        consumed + reserved
        >= SALON_MONTHLY_SESSION_LIMIT
    ):
        raise PermissionDenied(
            "Monthly Salon session quota "
            "is exhausted."
        )

    # Local import deliberately preserves the
    # existing domain primitive and avoids a
    # module import cycle.
    from .services import create_salon

    salon = create_salon(
        host=host,
        name=name,
        content=content,
        visibility=visibility,
        mode=mode,
        capacity=capacity,
        audio_enabled=audio_enabled,
        video_enabled=video_enabled,
        host_leave_policy=host_leave_policy,
    )

    SalonSessionQuotaEntry.objects.create(
        salon=salon,
        host=host,
        period_start=period_start,
        status=(
            SalonSessionQuotaEntry
            .STATUS_RESERVED
        ),
        plan_slug=(
            subscription.plan.slug
        ),
    )

    return salon


@transaction.atomic
def record_salon_usage_if_qualified(
    *,
    salon,
    now=None,
):
    entry = (
        SalonSessionQuotaEntry.objects
        .select_for_update()
        .filter(
            salon=salon,
        )
        .first()
    )

    # Legacy/internal/domain-created Salons have
    # no commercial quota entry and remain outside
    # G5-3O accounting.
    if entry is None:
        return None

    User = get_user_model()

    User.objects.select_for_update().get(
        pk=entry.host_id
    )

    return _reconcile_entry(
        entry=entry,
        now=now,
    )


@transaction.atomic
def get_salon_quota_status(
    *,
    user: Any,
):
    User = get_user_model()

    user = (
        User.objects
        .select_for_update()
        .get(
            pk=user.pk
        )
    )

    now = timezone.now()

    period_start = _utc_period_start(
        now
    )

    _reconcile_period_entries(
        host=user,
        period_start=period_start,
        now=now,
    )

    consumed, reserved = (
        _period_counts(
            host=user,
            period_start=period_start,
        )
    )

    subscription = _premium_subscription(
        user
    )

    premium_eligible = (
        subscription is not None
    )

    remaining = max(
        0,
        SALON_MONTHLY_SESSION_LIMIT
        - consumed
        - reserved,
    )

    if not premium_eligible:
        remaining = 0

    return {
        "premium_eligible": premium_eligible,
        "plan_slug": (
            subscription.plan.slug
            if subscription is not None
            else None
        ),
        "period_start": (
            period_start.isoformat()
        ),
        "limit": (
            SALON_MONTHLY_SESSION_LIMIT
        ),
        "consumed": consumed,
        "reserved": reserved,
        "remaining": remaining,
    }
