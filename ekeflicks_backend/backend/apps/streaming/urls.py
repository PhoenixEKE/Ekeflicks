from django.urls import include, path
from rest_framework.routers import DefaultRouter

from apps.streaming.views import OfflineDownloadLicenseViewSet, VideoAssetViewSet
from apps.streaming.advertising_api import AdDecisionView, AdEventView

router = DefaultRouter()
router.register('video-assets', VideoAssetViewSet, basename='video-asset')
router.register('offline-licenses', OfflineDownloadLicenseViewSet, basename='offline-license')

urlpatterns = [
    path('ads/decision/', AdDecisionView.as_view(), name='ad-decision'),
    path('ads/events/', AdEventView.as_view(), name='ad-event'),
    path('', include(router.urls)),
]
