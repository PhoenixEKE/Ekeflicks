from django.core.cache import cache
from rest_framework.throttling import (
    UserRateThrottle,
)


class SalonMutationThrottle(
    UserRateThrottle
):
    """
    G5-3S REST mutation boundary.

    Deliberately local to Salon operations.
    It does not replace authentication or permissions.
    """

    scope = "salon_mutation"
    rate = "60/min"


REALTIME_LIMIT = 120
REALTIME_WINDOW_SECONDS = 60


def allow_salon_realtime_event(
    *,
    user_id,
    salon_id,
):
    """
    Fixed-window Salon realtime throttle.

    120 mutating realtime events / minute
    per authenticated user + Salon.
    """

    key = (
        "salon:realtime:"
        f"{user_id}:"
        f"{salon_id}"
    )

    created = cache.add(
        key,
        1,
        timeout=REALTIME_WINDOW_SECONDS,
    )

    if created:
        return True

    try:
        current = cache.incr(
            key,
        )
    except ValueError:
        cache.set(
            key,
            1,
            timeout=REALTIME_WINDOW_SECONDS,
        )
        current = 1

    return current <= REALTIME_LIMIT
