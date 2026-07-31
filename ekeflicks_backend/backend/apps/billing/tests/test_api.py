import hashlib
import hmac
import json

from django.test import override_settings
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from core.models import (
    Content,
    Payment,
    PaymentWebhookEvent,
    ProducerContentView,
    SubscriptionPlan,
    User,
    ViewingSession,
)
from core.models import Profile


class BillingApiTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            email='owner@example.com',
            password='StrongPass123',
            firstname='Owner',
        )
        self.plan = SubscriptionPlan.objects.create(
            name='Premium',
            slug='premium',
            price='19.99',
            duration_days=30,
            max_quality='4K',
        )

    def test_subscription_created_by_user_starts_pending(self):
        self.client.force_authenticate(user=self.user)

        response = self.client.post(
            reverse('subscription-list'),
            {'plan_id': str(self.plan.id)},
            format='json',
        )

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data['status'], 'pending')
        self.assertEqual(response.data['plan']['id'], str(self.plan.id))

    def test_payment_uses_subscription_plan_amount(self):
        self.client.force_authenticate(user=self.user)
        subscription_response = self.client.post(
            reverse('subscription-list'),
            {'plan_id': str(self.plan.id)},
            format='json',
        )

        response = self.client.post(
            reverse('payment-list'),
            {
                'subscription_id': subscription_response.data['id'],
                'amount': '1.00',
                'currency': 'USD',
                'status': 'success',
                'provider': 'stripe',
            },
            format='json',
        )

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        payment = Payment.objects.get()
        self.assertEqual(str(payment.amount), '19.99')
        self.assertEqual(payment.currency, 'EUR')
        self.assertEqual(payment.status, 'pending')

    @override_settings(PAYSTACK_SECRET_KEY='test_secret')
    def test_paystack_webhook_activates_subscription(self):
        self.client.force_authenticate(user=self.user)
        subscription_response = self.client.post(
            reverse('subscription-list'),
            {'plan_id': str(self.plan.id)},
            format='json',
        )
        payment_response = self.client.post(
            reverse('payment-list'),
            {
                'subscription_id': subscription_response.data['id'],
                'provider': 'paystack',
            },
            format='json',
        )
        reference = payment_response.data['provider_reference']

        payload = {
            'event': 'charge.success',
            'data': {
                'id': 12345,
                'reference': reference,
                'status': 'success',
            },
        }
        body = json.dumps(payload, separators=(',', ':')).encode()
        signature = hmac.new(b'test_secret', body, hashlib.sha512).hexdigest()

        response = self.client.post(
            reverse('billing-webhook', args=['paystack']),
            data=body,
            content_type='application/json',
            HTTP_X_PAYSTACK_SIGNATURE=signature,
        )

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        payment = Payment.objects.select_related('subscription').get(provider_reference=reference)
        self.assertEqual(payment.status, 'success')
        self.assertEqual(payment.subscription.status, 'active')
        self.assertEqual(PaymentWebhookEvent.objects.count(), 1)

    def test_producer_can_request_payout_and_admin_can_approve(self):
        producer = User.objects.create_user(
            email='payout-producer@example.com',
            password='StrongPass123',
            is_producer=True,
        )
        viewer = User.objects.create_user(email='payout-viewer@example.com', password='StrongPass123')
        staff = User.objects.create_user(
            email='payout-admin@example.com',
            password='StrongPass123',
            is_staff=True,
        )
        content = Content.objects.create(
            title='Paid View',
            type='movie',
            duration=100,
            producer=producer,
        )
        ViewingSession.objects.create(
            profile=Profile.objects.get(user=viewer),
            content=content,
            duration_watched=3000,
        )
        self.assertEqual(ProducerContentView.objects.filter(producer=producer).count(), 1)
        self.client.force_authenticate(user=producer)

        balance_response = self.client.get(reverse('producer-payout-request-balance'))
        payout_response = self.client.post(
            reverse('producer-payout-request-list'),
            {
                'payout_method': 'wave',
                'payout_account': '+2250102030405',
                'producer_note': 'Paiement du mois',
            },
            format='json',
        )

        self.assertEqual(balance_response.status_code, status.HTTP_200_OK)
        self.assertEqual(balance_response.data['eligible_views'], 1)
        self.assertEqual(payout_response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(payout_response.data['status'], 'pending')

        self.client.force_authenticate(user=staff)
        approve_response = self.client.post(
            reverse('producer-payout-request-approve', args=[payout_response.data['id']]),
            {'reason': 'OK'},
            format='json',
        )

        self.assertEqual(approve_response.status_code, status.HTTP_200_OK)
        self.assertEqual(approve_response.data['status'], 'approved')

    def test_admin_can_disable_global_producer_remuneration(self):
        staff = User.objects.create_user(
            email='remuneration-admin@example.com',
            password='StrongPass123',
            is_staff=True,
        )
        self.client.force_authenticate(user=staff)

        response = self.client.post(
            reverse('producer-payout-request-set-global-remuneration'),
            {'enabled': False},
            format='json',
        )

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertFalse(response.data['remuneration_enabled'])
