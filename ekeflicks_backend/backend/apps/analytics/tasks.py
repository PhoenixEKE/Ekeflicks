from celery import shared_task

from apps.analytics.services import write_analytics_event


@shared_task(
    bind=True,
    max_retries=5,
)
def write_analytics_event_task(self, payload):
    try:
        result = write_analytics_event(payload)

        if result.get('status') == 'locked':
            raise self.retry(
                countdown=2,
            )

        return result

    except Exception as exc:
        raise self.retry(
            exc=exc,
            countdown=min(
                60,
                2 ** (self.request.retries + 1),
            ),
        )


# ==========================================================
# G5-1D7-C4 — DAILY PRODUCT TOP10 PUBLICATION
# ==========================================================

@shared_task(
    autoretry_for=(Exception,),
    retry_backoff=60,
    retry_backoff_max=900,
    retry_jitter=True,
    retry_kwargs={
        'max_retries': 3,
    },
)
def publish_global_top10_daily():
    """
    Publish the persisted global Top10 from the rolling
    seven-day D4 analytics window.

    Safety:
    - Redis/Django cache lock prevents concurrent execution;
    - PostgreSQL publication itself remains transactional;
    - existing published snapshot remains authoritative if
      calculation fails before a new snapshot is committed.
    """
    from django.core.cache import cache
    from django.utils import timezone

    from apps.analytics.services import (
        publish_global_top10,
    )

    lock_key = (
        'analytics:top10:global:publication'
    )

    acquired = cache.add(
        lock_key,
        '1',
        timeout=30 * 60,
    )

    if not acquired:
        return {
            'status': 'locked',
            'published': False,
        }

    try:
        snapshot = publish_global_top10(
            end_at=timezone.now(),
            window_days=7,
        )

        return {
            'status': 'published',
            'published': True,
            'snapshot_id': str(
                snapshot.id
            ),
            'scope': snapshot.scope,
            'algorithm_version':
                snapshot.algorithm_version,
            'entries':
                snapshot.entries.count(),
            'window_start':
                snapshot.window_start.isoformat(),
            'window_end':
                snapshot.window_end.isoformat(),
        }

    finally:
        cache.delete(
            lock_key
        )

