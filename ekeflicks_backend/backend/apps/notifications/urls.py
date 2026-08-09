from django.urls import include, path
from rest_framework.routers import DefaultRouter

from apps.notifications.views import NotificationViewSet, UnsubscribeViewSet

router = DefaultRouter()
router.register("notifications", NotificationViewSet, basename="notification")
router.register(
    "notification-unsubscribe", UnsubscribeViewSet, basename="notification-unsubscribe"
)

urlpatterns = [
    path("", include(router.urls)),
]
