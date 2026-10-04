from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (AdminDashboardView, AdminLoginView, AdminMFAConfirmView, AdminNotificationView,
                    AdminRefreshView, AdminUserViewSet, ClaimViewSet,
                    AdminPayoutViewSet,AdminSubscriptionListView, ContentModerationViewSet, PermissionListView, RoleViewSet,
                    SessionViewSet, VideoModerationViewSet)
from .advertising_api import AdminAdCampaignViewSet
from .analytics_api import AdminAdvertisingAnalyticsView, AdminPlatformAnalyticsView

router = DefaultRouter()
router.register('users', AdminUserViewSet, basename='admin-users')
router.register('roles', RoleViewSet, basename='admin-roles')
router.register('claims', ClaimViewSet, basename='admin-claims')
router.register('sessions', SessionViewSet, basename='admin-sessions')
router.register('contents', ContentModerationViewSet, basename='admin-contents')
router.register('videos', VideoModerationViewSet, basename='admin-videos')
router.register('payouts', AdminPayoutViewSet, basename='admin-payouts')
router.register('ad-campaigns', AdminAdCampaignViewSet, basename='admin-ad-campaigns')

urlpatterns = [
    path('auth/login/', AdminLoginView.as_view(), name='admin-login'),
    path('auth/mfa/confirm/', AdminMFAConfirmView.as_view(), name='admin-mfa-confirm'),
    path('auth/refresh/', AdminRefreshView.as_view(), name='admin-refresh'),
    path('permissions/', PermissionListView.as_view(), name='admin-permissions'),
    path('subscriptions/', AdminSubscriptionListView.as_view(), name='admin-subscriptions'),
    path('dashboard/', AdminDashboardView.as_view(), name='admin-dashboard'),
    path('analytics/', AdminPlatformAnalyticsView.as_view(), name='admin-platform-analytics'),
    path('advertising/analytics/', AdminAdvertisingAnalyticsView.as_view(), name='admin-advertising-analytics'),
    path('notifications/', AdminNotificationView.as_view(), name='admin-notifications'),
    path('', include(router.urls)),
]
