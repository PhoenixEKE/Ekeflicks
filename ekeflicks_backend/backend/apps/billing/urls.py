from django.urls import include, path
from rest_framework.routers import DefaultRouter

from apps.billing.views import (
    PaymentViewSet,
    PaymentWebhookView,
    ProducerPayoutRequestViewSet,
    SubscriptionPlanViewSet,
    SubscriptionPlanAdminViewSet,
    SubscriptionPlanOfferAdminViewSet,
    SubscriptionViewSet,
)

router = DefaultRouter()

router.register(
    'subscription-plans',
    SubscriptionPlanViewSet,
    basename='subscription-plan',
)

router.register(
    'admin/subscription-offers',
    SubscriptionPlanOfferAdminViewSet,
    basename='admin-subscription-offer',
)

router.register(
    'admin/subscription-plans',
    SubscriptionPlanAdminViewSet,
    basename='admin-subscription-plan',
)

router.register(
    'subscriptions',
    SubscriptionViewSet,
    basename='subscription',
)

router.register(
    'payments',
    PaymentViewSet,
    basename='payment',
)

router.register(
    'producer-payout-requests',
    ProducerPayoutRequestViewSet,
    basename='producer-payout-request',
)

urlpatterns = [
    path(
        'billing/webhooks/<str:provider>/',
        PaymentWebhookView.as_view(),
        name='billing-webhook',
    ),
    # Compatibility route used by older web clients.
    path(
        'subscriptions/subscriptions/best_price_auto/',
        SubscriptionPlanViewSet.as_view({'get': 'best_price'}),
        name='legacy-best-price',
    ),
    path('', include(router.urls)),
]
