from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from core.models import Content, ProducerContentView, ProducerCountryCurrency, Profile, User, ViewingSession


class AnalyticsApiTests(APITestCase):
    def test_viewing_session_at_30_percent_creates_producer_earning(self):
        producer = User.objects.create_user(
            email='producer-analytics@example.com',
            password='StrongPass123',
            is_producer=True,
            country_code='CI',
        )
        viewer = User.objects.create_user(
            email='viewer-analytics@example.com',
            password='StrongPass123',
            country_code='SN',
        )
        ProducerCountryCurrency.objects.update_or_create(
            country_code='CI',
            defaults={'currency': 'XOF', 'eur_to_currency_rate': '655.957'},
        )
        content = Content.objects.create(
            title='Revenue Movie',
            type='movie',
            duration=100,
            producer=producer,
        )
        profile = Profile.objects.get(user=viewer)

        ViewingSession.objects.create(
            profile=profile,
            content=content,
            duration_watched=1800,
        )

        earning = ProducerContentView.objects.get(content=content, producer=producer)
        self.assertEqual(str(earning.progress_percent), '30.00')
        self.assertEqual(str(earning.amount_eur), '0.001500')
        self.assertEqual(earning.currency, 'XOF')
        self.assertEqual(earning.viewer_country_code, 'SN')

    def test_admin_dashboard_returns_minute_and_country_stats(self):
        admin = User.objects.create_user(
            email='analytics-admin@example.com',
            password='StrongPass123',
            is_staff=True,
        )
        viewer = User.objects.create_user(
            email='analytics-viewer@example.com',
            password='StrongPass123',
            country_code='CI',
        )
        content = Content.objects.create(title='Stats Movie', type='movie', duration=90)
        profile = Profile.objects.get(user=viewer)
        ViewingSession.objects.create(profile=profile, content=content, duration_watched=300)
        self.client.force_authenticate(user=admin)

        dashboard_response = self.client.get(reverse('daily-stat-dashboard'))
        minute_response = self.client.get(reverse('daily-stat-views-by-minute'))
        country_response = self.client.get(reverse('daily-stat-views-by-country'))

        self.assertEqual(dashboard_response.status_code, status.HTTP_200_OK)
        self.assertEqual(dashboard_response.data['total_views'], 1)
        self.assertEqual(minute_response.status_code, status.HTTP_200_OK)
        self.assertEqual(minute_response.data['results'][0]['views'], 1)
        self.assertEqual(country_response.status_code, status.HTTP_200_OK)
        self.assertEqual(country_response.data['results'][0]['country'], 'CI')
