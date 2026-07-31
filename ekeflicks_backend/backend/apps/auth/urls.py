from django.urls import include, path
from rest_framework.routers import DefaultRouter
from rest_framework_simplejwt.views import TokenRefreshView
from .views import (
    AccountClosureRequestViewSet,
    EmailChangeSupportRequestViewSet,
    LoginView,
    LogoutView,
    MeView,
    PasswordResetConfirmView,
    PasswordResetRequestView,
    PersonalInfoView,
    RegisterView,
    ResendEmailVerificationView,
    VerifyEmailView,
)

router = DefaultRouter()
router.register('account-closure-requests', AccountClosureRequestViewSet, basename='account-closure-request')
router.register('email-change-support-requests', EmailChangeSupportRequestViewSet, basename='email-change-support-request')

urlpatterns = [
    path('login/', LoginView.as_view(), name='login'),
    path('register/', RegisterView.as_view(), name='register'),
    path('refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh_compat'),
    path('me/', MeView.as_view(), name='me'),
    path('personal-info/', PersonalInfoView.as_view(), name='personal-info'),
    path('verify-email/', VerifyEmailView.as_view(), name='verify-email'),
    path('resend-email-verification/', ResendEmailVerificationView.as_view(), name='resend-email-verification'),
    path('password-reset/request/', PasswordResetRequestView.as_view(), name='password-reset-request'),
    path('password-reset/confirm/', PasswordResetConfirmView.as_view(), name='password-reset-confirm'),
    path('logout/', LogoutView.as_view(), name='logout'),
    path('', include(router.urls)),
]
