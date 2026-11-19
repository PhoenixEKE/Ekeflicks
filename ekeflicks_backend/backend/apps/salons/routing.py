from django.urls import re_path

from .consumers import SalonConsumer
from .realtime_auth import (
    SalonTicketAuthMiddleware,
)


websocket_urlpatterns = [
    re_path(
        r"^ws/salons/"
        r"(?P<salon_id>"
        r"[0-9a-fA-F-]{36}"
        r")/$",
        SalonTicketAuthMiddleware(
            SalonConsumer.as_asgi()
        ),
        name="salon-websocket",
    ),
]
