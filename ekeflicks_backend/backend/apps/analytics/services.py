from decimal import Decimal, ROUND_HALF_UP

from django.db.models import Count, Sum, Value
from django.db.models.functions import Coalesce, TruncMinute
from django.utils import timezone

from core.models import (
    ProducerContentView,
    ProducerCountryCurrency,
    ProducerPayoutRequest,
    ProducerRevenueSetting,
    ViewingSession,
)


def revenue_settings():
    setting, _created = ProducerRevenueSetting.objects.get_or_create(pk=1)
    return setting


def producer_currency(producer):
    country_code = (producer.country_code or '').upper()
    if country_code:
        currency = ProducerCountryCurrency.objects.filter(
            country_code=country_code,
            is_active=True,
        ).first()
        if currency:
            return currency.currency, Decimal(currency.eur_to_currency_rate)
    return 'EUR', Decimal('1')


def convert_eur_for_producer(amount_eur, producer):
    currency, rate = producer_currency(producer)
    amount_local = (Decimal(amount_eur) * rate).quantize(Decimal('0.0001'), rounding=ROUND_HALF_UP)
    return currency, amount_local


def _total_seconds_for_session(session):
    if session.episode and session.episode.duration:
        return int(session.episode.duration) * 60
    if session.content.duration:
        return int(session.content.duration) * 60
    if session.was_completed and session.duration_watched:
        return int(session.duration_watched)
    return 0


def record_producer_viewing_session(session):
    session = (
        ViewingSession.objects.select_related(
            'profile',
            'profile__user',
            'content',
            'content__producer',
            'episode',
        )
        .get(pk=session.pk)
    )
    producer = session.content.producer
    if not producer:
        return None

    setting = revenue_settings()
    if not setting.remuneration_enabled or not producer.producer_remuneration_enabled:
        return None

    if ProducerContentView.objects.filter(viewing_session=session).exists():
        return session.producer_view

    total_seconds = _total_seconds_for_session(session)
    if total_seconds <= 0:
        return None

    watched_seconds = int(session.duration_watched or 0)
    progress_percent = (Decimal(watched_seconds) * Decimal('100')) / Decimal(total_seconds)
    if progress_percent < Decimal(setting.eligible_progress_percent):
        return None

    amount_eur = (Decimal(setting.rate_per_1000_views_eur) / Decimal('1000')).quantize(
        Decimal('0.000001'),
        rounding=ROUND_HALF_UP,
    )
    currency, amount_local = convert_eur_for_producer(amount_eur, producer)
    return ProducerContentView.objects.create(
        viewing_session=session,
        producer=producer,
        content=session.content,
        episode=session.episode,
        watched_seconds=watched_seconds,
        total_seconds=total_seconds,
        progress_percent=progress_percent.quantize(Decimal('0.01'), rounding=ROUND_HALF_UP),
        viewer_country_code=(session.profile.user.country_code or '').upper(),
        amount_eur=amount_eur,
        currency=currency,
        amount_local=amount_local,
    )


def clickhouse_client():
    from django.conf import settings

    if not getattr(settings, 'CLICKHOUSE_HOST', None):
        return None
    try:
        import clickhouse_connect
    except Exception:
        return None

    try:
        return clickhouse_connect.get_client(
            host=settings.CLICKHOUSE_HOST,
            port=settings.CLICKHOUSE_PORT,
            username=getattr(settings, 'CLICKHOUSE_USER', None) or 'default',
            password=getattr(settings, 'CLICKHOUSE_PASSWORD', None) or '',
            connect_timeout=1,
            send_receive_timeout=1,
        )
    except Exception:
        return None


def clickhouse_status():
    client = clickhouse_client()
    if not client:
        return {'enabled': False, 'available': False}
    try:
        client.query('SELECT 1')
        return {'enabled': True, 'available': True}
    except Exception as exc:
        return {'enabled': True, 'available': False, 'error': str(exc)}


def _filtered_sessions(request, queryset=None):
    queryset = queryset or ViewingSession.objects.select_related('profile__user', 'content__producer', 'content')
    params = request.query_params

    if not request.user.is_staff and getattr(request.user, 'is_producer', False):
        queryset = queryset.filter(content__producer=request.user)

    content_id = params.get('content')
    producer_id = params.get('producer')
    country = params.get('country')
    start = params.get('start')
    end = params.get('end')

    if content_id:
        queryset = queryset.filter(content_id=content_id)
    if producer_id and request.user.is_staff:
        queryset = queryset.filter(content__producer_id=producer_id)
    if country:
        queryset = queryset.filter(profile__user__country_code__iexact=country)
    if start:
        queryset = queryset.filter(start_time__date__gte=start)
    if end:
        queryset = queryset.filter(start_time__date__lte=end)

    return queryset


def views_by_minute(request):
    queryset = _filtered_sessions(request)
    rows = (
        queryset.annotate(
            minute=TruncMinute('start_time'),
            country=Coalesce('profile__user__country_code', Value('')),
        )
        .values('minute', 'country', 'content_id', 'content__title')
        .annotate(views=Count('id'), watch_seconds=Sum('duration_watched'))
        .order_by('minute', 'country', 'content__title')
    )
    return [
        {
            'minute': row['minute'],
            'country': row['country'],
            'content_id': str(row['content_id']),
            'content_title': row['content__title'],
            'views': row['views'],
            'watch_seconds': row['watch_seconds'] or 0,
        }
        for row in rows
    ]


def views_by_country(request):
    queryset = _filtered_sessions(request)
    rows = (
        queryset.annotate(country=Coalesce('profile__user__country_code', Value('')))
        .values('country')
        .annotate(views=Count('id'), watch_seconds=Sum('duration_watched'))
        .order_by('-views', 'country')
    )
    return list(rows)


def dashboard_summary(request):
    sessions = _filtered_sessions(request)
    producer_views = ProducerContentView.objects.all()
    payout_requests = ProducerPayoutRequest.objects.all()
    if not request.user.is_staff and getattr(request.user, 'is_producer', False):
        producer_views = producer_views.filter(producer=request.user)
        payout_requests = payout_requests.filter(producer=request.user)

    return {
        'generated_at': timezone.now(),
        'clickhouse': clickhouse_status(),
        'total_views': sessions.count(),
        'total_watch_seconds': sessions.aggregate(total=Sum('duration_watched'))['total'] or 0,
        'eligible_producer_views': producer_views.count(),
        'producer_revenue_eur': producer_views.aggregate(total=Sum('amount_eur'))['total'] or 0,
        'pending_payout_requests': payout_requests.filter(status='pending').count(),
        'approved_payout_requests': payout_requests.filter(status='approved').count(),
        'paid_payout_requests': payout_requests.filter(status='paid').count(),
        'views_by_country': views_by_country(request),
    }
