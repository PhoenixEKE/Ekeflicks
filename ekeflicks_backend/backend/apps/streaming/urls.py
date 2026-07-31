from django.urls import include, path
from rest_framework.routers import DefaultRouter

from apps.streaming.views import OfflineDownloadLicenseViewSet, VideoAssetViewSet

router = DefaultRouter()
router.register('video-assets', VideoAssetViewSet, basename='video-asset')
router.register('offline-licenses', OfflineDownloadLicenseViewSet, basename='offline-license')

urlpatterns = [
    path('', include(router.urls)),
]
