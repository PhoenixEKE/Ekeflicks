from decimal import Decimal

from django.core.exceptions import ValidationError
from django.test import TestCase
from rest_framework import serializers

from apps.billing.payout_services import create_payout_request, producer_balance
from core.models import Content, ProducerDemoEarning, ProducerRevenueSetting, User


class ProducerDemoEarningsTests(TestCase):
    def setUp(self):
        self.producer = User.objects.create_user(
            email='producer-demo-finance@example.com',
            password='StrongPass123!',
            is_producer=True,
        )
        self.content = Content.objects.create(
            producer=self.producer,
            title='[DÉMO] Nuit sur Abidjan',
            type='movie',
            producer_submission_status='draft',
        )
        self.demo = ProducerDemoEarning.objects.create(
            producer=self.producer,
            content=self.content,
            seed_key='producer_portal_demo_v1',
            period='2026-10-02',
            eligible_views=6000,
            view_revenue_eur=Decimal('9.000000000'),
            advertising_net_revenue_eur=Decimal('40.00'),
            advertising_share_percent=Decimal('60'),
        )

    def test_demo_earnings_are_visible_only_when_demo_preview_is_requested(self):
        hidden = producer_balance(self.producer)
        self.assertFalse(hidden['demo_mode'])
        self.assertEqual(hidden['amount_eur'], Decimal('0'))

        preview = producer_balance(self.producer, include_demo=True)
        self.assertTrue(preview['demo_mode'])
        self.assertEqual(preview['demo_eligible_views'], 6000)
        self.assertEqual(preview['demo_amount_eur'], Decimal('33.0000'))
        self.assertEqual(preview['content_earnings'][0]['total_eur'], Decimal('33.000000000'))

    def test_demo_earnings_never_fund_a_real_payout_request(self):
        ProducerRevenueSetting.objects.update_or_create(
            pk=1,
            defaults={'minimum_payout_eur': Decimal('1')},
        )
        with self.assertRaises(serializers.ValidationError):
            create_payout_request(self.producer)

    def test_demo_earning_rejects_another_producers_content(self):
        other = User.objects.create_user(
            email='other-demo-finance@example.com',
            password='StrongPass123!',
            is_producer=True,
        )
        foreign_content = Content.objects.create(
            producer=other,
            title='Foreign content',
            type='movie',
        )
        with self.assertRaises(ValidationError):
            ProducerDemoEarning.objects.create(
                producer=self.producer,
                content=foreign_content,
                seed_key='producer_portal_demo_v1',
                period='2026-10-02',
                eligible_views=1000,
                view_revenue_eur=Decimal('1.500000000'),
            )
