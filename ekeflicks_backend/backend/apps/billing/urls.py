from django.urls import include, path
from rest_framework.routers import DefaultRouter

from apps.billing.views import (
    PaymentViewSet,
    PaymentWebhookView,
    ProducerPayoutRequestViewSet,
    SubscriptionPlanViewSet,
    SubscriptionViewSet,
)

router = DefaultRouter()
router.register('subscription-plans', SubscriptionPlanViewSet, basename='subscription-plan')
router.register('subscriptions', SubscriptionViewSet, basename='subscription')
router.register('payments', PaymentViewSet, basename='payment')
router.register('producer-payout-requests', ProducerPayoutRequestViewSet, basename='producer-payout-request')

urlpatterns = [
    path('billing/webhooks/<str:provider>/', PaymentWebhookView.as_view(), name='billing-webhook'),
    path('', include(router.urls)),
]
