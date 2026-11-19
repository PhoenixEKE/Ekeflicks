from django.urls import path
from .invitation_views import (
    SalonInvitationDecisionView,
    SalonInvitationListCreateView,
)
from django.urls import path
from rest_framework.routers import DefaultRouter

from .playback_views import (
    SalonPlaybackView,
    SalonResyncView,
)
from .realtime_views import (
    SalonRealtimeTicketView,
)
from .views import SalonViewSet
from .matching_views import SalonSocialMatchingView
from .icebreaker_views import SalonIcebreakerView


router = DefaultRouter()

router.register(
    "salons",
    SalonViewSet,
    basename="salon",
)


urlpatterns = [
    path(
        "salons/<uuid:salon_id>/invitations/",
        SalonInvitationListCreateView.as_view(),
        name="salon-invitations",
    ),
    path(
        "salons/invitations/<uuid:invitation_id>/<str:action>/",
        SalonInvitationDecisionView.as_view(),
        name="salon-invitation-decision",
    ),

    path(
        "salons/<uuid:pk>/matches/",
        SalonSocialMatchingView.as_view(),
        name="salon-social-matches",
    ),

    path(
        "salons/<uuid:pk>/icebreakers/",
        SalonIcebreakerView.as_view(),
        name="salon-icebreakers",
    ),

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
    path(
        "salons/<uuid:pk>/realtime-ticket/",
        SalonRealtimeTicketView.as_view(),
        name="salon-realtime-ticket",
    ),
]

urlpatterns += router.urls
