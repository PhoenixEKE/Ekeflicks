from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (AdminDashboardView, AdminLoginView, AdminMFAConfirmView, AdminNotificationView,
                    AdminRefreshView, AdminUserViewSet, ClaimViewSet,
                    AdminPayoutViewSet, ContentModerationViewSet, PermissionListView, RoleViewSet,
                    SessionViewSet, VideoModerationViewSet)

router = DefaultRouter()
router.register('users', AdminUserViewSet, basename='admin-users')
router.register('roles', RoleViewSet, basename='admin-roles')
router.register('claims', ClaimViewSet, basename='admin-claims')
router.register('sessions', SessionViewSet, basename='admin-sessions')
router.register('contents', ContentModerationViewSet, basename='admin-contents')
router.register('videos', VideoModerationViewSet, basename='admin-videos')
router.register('payouts', AdminPayoutViewSet, basename='admin-payouts')

urlpatterns = [
    path('auth/login/', AdminLoginView.as_view(), name='admin-login'),
    path('auth/mfa/confirm/', AdminMFAConfirmView.as_view(), name='admin-mfa-confirm'),
    path('auth/refresh/', AdminRefreshView.as_view(), name='admin-refresh'),
    path('permissions/', PermissionListView.as_view(), name='admin-permissions'),
    path('dashboard/', AdminDashboardView.as_view(), name='admin-dashboard'),
    path('notifications/', AdminNotificationView.as_view(), name='admin-notifications'),
    path('', include(router.urls)),
]
