from django.urls import include, path
from rest_framework.routers import DefaultRouter

from apps.recommendations.public_views import EkeAIViewSet

router = DefaultRouter()
router.register(r'eke-ai', EkeAIViewSet, basename='eke-ai')

urlpatterns = [
    path('', include(router.urls)),
]
