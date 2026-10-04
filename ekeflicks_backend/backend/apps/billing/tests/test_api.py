import hashlib
import hmac
import json
import re
from types import SimpleNamespace
from unittest.mock import patch

from django.test import override_settings
from django.core import mail
from django.urls import reverse
from django.utils import timezone
from datetime import timedelta
from rest_framework import status
from rest_framework.test import APITestCase

from core.models import (
    Content,
    Payment,
    PaymentWebhookEvent,
    ProducerContentView,
    ProducerFinanceAccess,
    ProducerAdvertisingRevenue,
    ProducerRevenueSetting,
    SubscriptionPlan,
    SubscriptionPlanOffer,
    User,
    ViewingSession,
)
from core.models import Profile
from apps.billing.payout_services import producer_balance


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
        self.assertEqual(response.data['price_at_purchase'], '19.99')
        self.assertEqual(response.data['currency_at_purchase'], 'EUR')
        self.assertEqual(response.data['duration_days_at_purchase'], 30)
        self.assertTrue(any('Abonnement cree' in message.subject for message in mail.outbox))
        subscription_email = next(message for message in mail.outbox if 'Abonnement cree' in message.subject)
        self.assertIn('logo_dark.png', subscription_email.alternatives[0][0])

    def test_auto_renew_requires_explicit_customer_consent(self):
        self.client.force_authenticate(user=self.user)

        response = self.client.post(
            reverse('subscription-list'),
            {
                'plan_id': str(self.plan.id),
                'auto_renew': True,
            },
            format='json',
        )

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertEqual(
            response.data['auto_renew_consent'][0],
            'Confirmez explicitement la mise en place du prélèvement récurrent.',
        )
        self.assertFalse(
            self.user.subscriptions.filter(auto_renew=True).exists()
        )

    def test_monthly_subscription_stores_explicit_renewal_consent(self):
        self.client.force_authenticate(user=self.user)

        response = self.client.post(
            reverse('subscription-list'),
            {
                'plan_id': str(self.plan.id),
                'auto_renew': True,
                'auto_renew_consent': True,
            },
            format='json',
        )

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertTrue(response.data['auto_renew'])
        self.assertTrue(response.data['auto_renew_consent_at'])
        self.assertFalse(response.data['cancel_at_period_end'])

    @override_settings(STRIPE_SECRET_KEY='sk_test_recurring')
    @patch('apps.billing.serializers.stripe.checkout.Session.create')
    def test_explicit_monthly_consent_creates_recurring_stripe_checkout(
        self,
        create_session,
    ):
        create_session.return_value = SimpleNamespace(
            id='cs_recurring_test',
            url='https://checkout.stripe.test/session',
        )
        self.client.force_authenticate(user=self.user)
        subscription_response = self.client.post(
            reverse('subscription-list'),
            {
                'plan_id': str(self.plan.id),
                'auto_renew_consent': True,
            },
            format='json',
        )

        payment_response = self.client.post(
            reverse('payment-list'),
            {
                'subscription_id': subscription_response.data['id'],
                'provider': 'stripe',
            },
            format='json',
        )

        self.assertEqual(payment_response.status_code, status.HTTP_201_CREATED)
        call = create_session.call_args.kwargs
        self.assertEqual(call['mode'], 'subscription')
        self.assertEqual(
            call['line_items'][0]['price_data']['recurring'],
            {'interval': 'month'},
        )
        self.assertEqual(
            call['subscription_data']['metadata']['auto_renew_consent'],
            'true',
        )

    def test_free_30_day_subscription_is_activated_without_payment(self):
        free_plan = SubscriptionPlan.objects.create(
            name='Free Test 30 Days',
            slug='free-test-30-days',
            price='0.00',
            duration_days=30,
        )
        self.client.force_authenticate(user=self.user)

        response = self.client.post(
            reverse('subscription-list'),
            {'plan_id': str(free_plan.id)},
            format='json',
        )

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data['status'], 'active')
        self.assertFalse(response.data['auto_renew'])
        self.assertFalse(Payment.objects.filter(subscription_id=response.data['id']).exists())

    def test_best_price_returns_cheapest_active_plan(self):
        basic_plan = SubscriptionPlan.objects.create(
            name='Basic Test',
            slug='basic-test',
            price='5.00',
            currency='EUR',
            duration_days=30,
        )

        SubscriptionPlanOffer.objects.create(
            plan=basic_plan,
            zone=SubscriptionPlanOffer.ZONE_GLOBAL,
            price='5.00',
            currency='EUR',
            duration_days=30,
            is_active=True,
        )

        response = self.client.get(
            reverse('subscription-plan-best-price')
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_200_OK,
        )
        self.assertEqual(
            response.data['best_price'],
            '5.00',
        )
        self.assertEqual(
            response.data['currency'],
            'EUR',
        )

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
                'provider': 'cinetpay',
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
            duration_watched=4500,
        )
        self.assertEqual(ProducerContentView.objects.filter(producer=producer).count(), 1)
        ProducerFinanceAccess.objects.create(
            producer=producer,
            pin_hash='test-only',
            unlocked_until=timezone.now() + timedelta(minutes=15),
        )
        ProducerRevenueSetting.objects.update_or_create(
            pk=1,
            defaults={'minimum_payout_eur': '0'},
        )
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

    @override_settings(EMAIL_BACKEND='django.core.mail.backends.locmem.EmailBackend')
    def test_finance_pin_setup_and_email_confirmation(self):
        producer = User.objects.create_user(
            email='finance-pin@example.com',
            password='StrongPass123',
            is_producer=True,
            is_verified=True,
        )
        self.client.force_authenticate(user=producer)
        endpoint = '/api/v1/producer-payout-requests/finance-access/'

        started = self.client.post(
            endpoint,
            {'operation': 'setup', 'pin': '2468'},
            format='json',
        )
        self.assertEqual(started.status_code, status.HTTP_200_OK)
        code = re.search(r'\b(\d{6})\b', mail.outbox[-1].body).group(1)
        confirmed = self.client.post(
            endpoint,
            {'operation': 'confirm_setup', 'code': code},
            format='json',
        )
        self.assertEqual(confirmed.status_code, status.HTTP_200_OK)
        access = ProducerFinanceAccess.objects.get(producer=producer)
        self.assertTrue(access.pin_hash)
        self.assertFalse(access.pending_pin_hash)
        self.assertGreater(access.unlocked_until, timezone.now())

        self.client.force_authenticate(user=producer)
        self.client.post(endpoint, {'operation': 'forgot'}, format='json')
        reset_code = re.search(r'\b(\d{6})\b', mail.outbox[-1].body).group(1)
        reset = self.client.post(
            endpoint,
            {'operation': 'reset', 'code': reset_code, 'pin': '9753'},
            format='json',
        )
        self.assertEqual(reset.status_code, status.HTTP_200_OK)

    def test_advertising_revenue_is_snapshotted_and_totalled_by_content(self):
        producer = User.objects.create_user(
            email='advertising-producer@example.com',
            password='StrongPass123',
            is_producer=True,
        )
        content = Content.objects.create(
            title='Ad-supported film',
            type='movie',
            producer=producer,
        )
        ProducerRevenueSetting.objects.update_or_create(
            pk=1,
            defaults={
                'advertising_share_percent': '60',
                'minimum_payout_eur': '0',
            },
        )
        earning = ProducerAdvertisingRevenue.objects.create(
            producer=producer,
            content=content,
            period=timezone.localdate(),
            external_reference='campaign-2026-09',
            net_revenue_eur='50.00',
        )
        self.assertEqual(earning.share_percent, 60)
        self.assertEqual(earning.producer_share_eur, 30)
        balance = producer_balance(producer)
        self.assertEqual(balance['amount_eur'], 30)
        self.assertEqual(balance['content_earnings'][0]['title'], content.title)
        self.assertEqual(balance['content_earnings'][0]['advertising_revenue_eur'], 30)

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
