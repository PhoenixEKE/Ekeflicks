from django.urls import path
from rest_framework.routers import DefaultRouter

from .playback_views import (
    SalonPlaybackView,
    SalonResyncView,
)
from .views import SalonViewSet


router = DefaultRouter()
router.register(
    "salons",
    SalonViewSet,
    basename="salon",
)


urlpatterns = [
    path(
        "salons/<uuid:pk>/playback/",
        SalonPlaybackView.as_view(),
        name="salon-playback",
    ),
    path(
        "salons/<uuid:pk>/resync/",
        SalonResyncView.as_view(),
        name="salon-resync",
    ),
]

urlpatterns += router.urls
