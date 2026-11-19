from django.urls import include, path
from rest_framework.routers import DefaultRouter

from apps.analytics.views import (
    DailyStatViewSet,
    ProducerContentViewViewSet,
    ProducerCountryCurrencyViewSet,
    ProducerRevenueSettingViewSet,
)

router = DefaultRouter()
router.register('daily-stats', DailyStatViewSet, basename='daily-stat')
router.register('producer-revenue-settings', ProducerRevenueSettingViewSet, basename='producer-revenue-setting')
router.register('producer-country-currencies', ProducerCountryCurrencyViewSet, basename='producer-country-currency')
router.register('producer-content-views', ProducerContentViewViewSet, basename='producer-content-view')

urlpatterns = [
    path('', include(router.urls)),
]
