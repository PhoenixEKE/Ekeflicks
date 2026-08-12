from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import AdminLoginView, AdminRefreshView, AdminUserViewSet, ClaimViewSet, PermissionListView, RoleViewSet, SessionViewSet

router = DefaultRouter()
router.register('users', AdminUserViewSet, basename='admin-users')
router.register('roles', RoleViewSet, basename='admin-roles')
router.register('claims', ClaimViewSet, basename='admin-claims')
router.register('sessions', SessionViewSet, basename='admin-sessions')

urlpatterns = [
    path('auth/login/', AdminLoginView.as_view(), name='admin-login'),
    path('auth/refresh/', AdminRefreshView.as_view(), name='admin-refresh'),
    path('permissions/', PermissionListView.as_view(), name='admin-permissions'),
    path('', include(router.urls)),
]
