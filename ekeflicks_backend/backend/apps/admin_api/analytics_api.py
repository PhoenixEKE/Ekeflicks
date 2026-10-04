from datetime import timedelta

from django.conf import settings
from django.db.models import Count, F, Q, Sum
from django.db.models.functions import TruncDate
from django.utils import timezone
from django.utils.dateparse import parse_date
from rest_framework import exceptions, generics
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from apps.admin_api.security import AdminPermission
from core.models import (
    AdCampaign, AdEvent, Content, Payment, ProducerAdvertisingRevenue,
    Subscription, User, VideoAsset, ViewingSession,
)


def _period(request):
    today = timezone.localdate()
    days_value = request.query_params.get("days", "30")
    try:
        days = int(days_value)
    except (TypeError, ValueError):
        raise exceptions.ValidationError({"days": "Utilisez un nombre de jours entre 1 et 366."})
    if not 1 <= days <= 366:
        raise exceptions.ValidationError({"days": "Utilisez un nombre de jours entre 1 et 366."})

    start = parse_date(request.query_params.get("from", "")) if request.query_params.get("from") else None
    end = parse_date(request.query_params.get("to", "")) if request.query_params.get("to") else None
    if request.query_params.get("from") and start is None:
        raise exceptions.ValidationError({"from": "Date ISO invalide (AAAA-MM-JJ)."})
    if request.query_params.get("to") and end is None:
        raise exceptions.ValidationError({"to": "Date ISO invalide (AAAA-MM-JJ)."})
    end = end or today
    start = start or (end - timedelta(days=days - 1))
    if start > end or (end - start).days > 365:
        raise exceptions.ValidationError({"period": "La période doit couvrir de 1 à 366 jours."})
    return start, end


def _ad_kpis(start, end):
    events = AdEvent.objects.filter(occurred_at__date__range=(start, end))
    totals = events.aggregate(
        requests=Count("id", filter=Q(event_type="request")),
        filled=Count("id", filter=Q(event_type="filled")),
        impressions=Count("id", filter=Q(event_type="impression")),
        completed=Count("id", filter=Q(event_type="complete")),
        clicks=Count("id", filter=Q(event_type="click")),
        errors=Count("id", filter=Q(event_type="error")),
    )
    requests = totals["requests"] or 0
    filled = totals["filled"] or 0
    impressions = totals["impressions"] or 0
    completed = totals["completed"] or 0
    clicks = totals["clicks"] or 0
    revenue = ProducerAdvertisingRevenue.objects.filter(period__range=(start, end)).aggregate(total=Sum("net_revenue_eur"))["total"] or 0
    totals.update({
        "active_campaigns": AdCampaign.objects.filter(status="active").count(),
        "fill_rate_percent": round((filled * 100.0 / requests), 2) if requests else 0,
        "completion_rate_percent": round((completed * 100.0 / impressions), 2) if impressions else 0,
        "click_through_rate_percent": round((clicks * 100.0 / impressions), 2) if impressions else 0,
        "net_revenue_eur": float(revenue),
        "ssai_configured": bool(getattr(settings, "AD_SSAI_ENABLED", False) and getattr(settings, "AD_SSAI_SESSION_URL", "")),
    })
    return totals


def _timeline(start, end):
    days = {}
    current = start
    while current <= end:
        days[current.isoformat()] = {
            "date": current.isoformat(), "new_users": 0, "views": 0,
            "watch_seconds": 0, "ad_requests": 0, "ad_impressions": 0,
            "ad_completions": 0, "ad_clicks": 0, "payments": 0,
        }
        current += timedelta(days=1)

    for row in User.objects.filter(is_staff=False, created_at__date__range=(start, end)).annotate(day=TruncDate("created_at")).values("day").annotate(total=Count("id")):
        days[row["day"].isoformat()]["new_users"] = row["total"]
    for row in ViewingSession.objects.filter(start_time__date__range=(start, end)).annotate(day=TruncDate("start_time")).values("day").annotate(total=Count("id"), watch=Sum("duration_watched")):
        item = days[row["day"].isoformat()]
        item["views"] = row["total"]
        item["watch_seconds"] = row["watch"] or 0
    event_rows = AdEvent.objects.filter(occurred_at__date__range=(start, end)).annotate(day=TruncDate("occurred_at")).values("day").annotate(
        requests=Count("id", filter=Q(event_type="request")),
        impressions=Count("id", filter=Q(event_type="impression")),
        completions=Count("id", filter=Q(event_type="complete")),
        clicks=Count("id", filter=Q(event_type="click")),
    )
    for row in event_rows:
        item = days[row["day"].isoformat()]
        item["ad_requests"] = row["requests"]
        item["ad_impressions"] = row["impressions"]
        item["ad_completions"] = row["completions"]
        item["ad_clicks"] = row["clicks"]
    for row in Payment.objects.filter(status="success", paid_at__date__range=(start, end)).annotate(day=TruncDate("paid_at")).values("day").annotate(total=Count("id")):
        days[row["day"].isoformat()]["payments"] = row["total"]
    return list(days.values())


def _geography(start, end):
    return list(
        AdEvent.objects.filter(occurred_at__date__range=(start, end))
        .exclude(country_code="")
        .values("country_code")
        .annotate(impressions=Count("id", filter=Q(event_type="impression")), clicks=Count("id", filter=Q(event_type="click")))
        .order_by("-impressions")[:20]
    )


def _report(start, end):
    session_qs = ViewingSession.objects.filter(start_time__date__range=(start, end))
    session_totals = session_qs.aggregate(
        views=Count("id"),
        watch_seconds=Sum("duration_watched"),
        completed=Count("id", filter=Q(was_completed=True)),
        unique_viewers=Count("profile__user_id", distinct=True),
    )
    sessions = session_totals["views"] or 0
    completed = session_totals["completed"] or 0
    payments_by_currency = list(
        Payment.objects.filter(status="success", paid_at__date__range=(start, end))
        .values("currency").annotate(amount=Sum("amount"), count=Count("id")).order_by("currency")
    )
    top_content = list(
        session_qs.values(content_id=F("content_id"), title=F("content__title"))
        .annotate(views=Count("id"), watch_seconds=Sum("duration_watched"))
        .order_by("-views", "title")[:10]
    )
    top_producers = list(
        session_qs.exclude(content__producer_id=None)
        .values(
            producer_id=F("content__producer_id"),
            producer=F("content__producer__producer_company"),
            email=F("content__producer__email"),
        )
        .annotate(views=Count("id"), watch_seconds=Sum("duration_watched"))
        .order_by("-views")[:10]
    )
    geography = _geography(start, end)
    net_ad_revenue = ProducerAdvertisingRevenue.objects.filter(period__range=(start, end)).aggregate(total=Sum("net_revenue_eur"))["total"] or 0
    return {
        "period": {"from": start.isoformat(), "to": end.isoformat()},
        "summary": {
            "users": User.objects.filter(is_staff=False).count(),
            "new_users": User.objects.filter(is_staff=False, created_at__date__range=(start, end)).count(),
            "active_producers": User.objects.filter(is_producer=True, is_active=True).count(),
            "new_producers": User.objects.filter(is_producer=True, created_at__date__range=(start, end)).count(),
            "active_subscriptions": Subscription.objects.filter(status="active", expires_at__gt=timezone.now()).count(),
            "published_contents": Content.objects.filter(producer_submission_status="approved").count(),
            "ready_videos": VideoAsset.objects.filter(status="ready", moderation_status="approved").count(),
            "views": sessions,
            "unique_viewers": session_totals["unique_viewers"] or 0,
            "watch_minutes": round((session_totals["watch_seconds"] or 0) / 60.0, 1),
            "completion_rate_percent": round((completed * 100.0 / sessions), 2) if sessions else 0,
            "payment_count": sum(row["count"] for row in payments_by_currency),
            "advertising_net_revenue_eur": float(net_ad_revenue),
        },
        "payments_by_currency": [
            {"currency": row["currency"], "amount": float(row["amount"] or 0), "count": row["count"]}
            for row in payments_by_currency
        ],
        "top_contents": [
            {"content_id": row["content_id"], "title": row["title"], "views": row["views"], "watch_minutes": round((row["watch_seconds"] or 0) / 60.0, 1)}
            for row in top_content
        ],
        "top_producers": [
            {"producer_id": row["producer_id"], "name": row["producer"] or row["email"], "email": row["email"], "views": row["views"], "watch_minutes": round((row["watch_seconds"] or 0) / 60.0, 1)}
            for row in top_producers
        ],
        "geography": geography,
        "advertising": _ad_kpis(start, end),
        "timeline": _timeline(start, end),
    }


class AdminPlatformAnalyticsView(generics.GenericAPIView):
    permission_classes = [IsAuthenticated, AdminPermission]
    required_permission = "core.view_dailystat"

    def get(self, request):
        start, end = _period(request)
        return Response(_report(start, end))


class AdminAdvertisingAnalyticsView(generics.GenericAPIView):
    permission_classes = [IsAuthenticated, AdminPermission]
    required_permission = "core.view_adcampaign"

    def get(self, request):
        start, end = _period(request)
        campaigns = list(
            AdCampaign.objects.annotate(
                impressions=Count("events", filter=Q(events__event_type="impression", events__occurred_at__date__range=(start, end))),
                completed=Count("events", filter=Q(events__event_type="complete", events__occurred_at__date__range=(start, end))),
                clicks=Count("events", filter=Q(events__event_type="click", events__occurred_at__date__range=(start, end))),
            ).order_by("-impressions", "-priority")[:50]
        )
        return Response({
            "period": {"from": start.isoformat(), "to": end.isoformat()},
            "metrics": _ad_kpis(start, end),
            "campaigns": [
                {"id": str(campaign.pk), "name": campaign.name, "status": campaign.status,
                 "delivery_mode": campaign.delivery_mode, "formats": campaign.formats,
                 "impressions": campaign.impressions, "completed": campaign.completed,
                 "clicks": campaign.clicks}
                for campaign in campaigns
            ],
            "geography": _geography(start, end),
        })
