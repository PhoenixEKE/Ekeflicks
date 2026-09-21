from django.urls import include, path
from rest_framework.routers import DefaultRouter

from apps.analytics.views import (
    AudienceAnalyticsViewSet,
    DailyStatViewSet,
    ProducerContentViewViewSet,
    ProducerCountryCurrencyViewSet,
    ProducerRevenueSettingViewSet,
)

from apps.analytics.views import ContentAnalyticsViewSet
from apps.analytics.views import AppSessionAnalyticsViewSet
from apps.analytics.views import EngagementAnalyticsViewSet

from apps.analytics.views import ProducerAnalyticsViewSet

router = DefaultRouter()
router.register(
    'audience',
    AudienceAnalyticsViewSet,
    basename='audience',
)
router.register('daily-stats', DailyStatViewSet, basename='daily-stat')
router.register('producer-revenue-settings', ProducerRevenueSettingViewSet, basename='producer-revenue-setting')
router.register('producer-country-currencies', ProducerCountryCurrencyViewSet, basename='producer-country-currency')
router.register('producer-content-views', ProducerContentViewViewSet, basename='producer-content-view')


router.register(
    r'content-analytics',
    ContentAnalyticsViewSet,
    basename='content-analytics',
)


router.register(
    r'app-sessions',
    AppSessionAnalyticsViewSet,
    basename='app-session',
)


router.register(
    r'engagement-analytics',
    EngagementAnalyticsViewSet,
    basename='engagement-analytics',
)


# G5-1D7-C3 — persisted product Top10 API
from apps.analytics.views import Top10AnalyticsViewSet

router.register(
    r'top10-analytics',
    Top10AnalyticsViewSet,
    basename='top10-analytics',
)


router.register(
    r'producer-analytics',
    ProducerAnalyticsViewSet,
    basename='producer-analytics',
)

urlpatterns = [
    path('', include(router.urls)),
]
