from django.urls import reverse

from rest_framework.test import APITestCase

from core.models import User


class ProducerPrivacyPreferencesTests(APITestCase):
    def setUp(self):
        self.url = reverse('producer-privacy-preferences')
        self.producer = User.objects.create_user(
            email='privacy-producer@example.com',
            password='StrongPass123!',
            is_producer=True,
        )

    def test_preferences_default_to_off(self):
        self.client.force_authenticate(self.producer)

        response = self.client.get(self.url)

        self.assertEqual(response.status_code, 200)
        self.assertFalse(response.data['microphone_enabled'])
        self.assertFalse(response.data['camera_enabled'])
        self.assertFalse(response.data['automatic_geolocation'])

    def test_producer_can_update_only_allowed_preferences(self):
        self.client.force_authenticate(self.producer)

        response = self.client.patch(
            self.url,
            {'microphone_enabled': True, 'camera_enabled': True, 'eke_voice_gender': 'male'},
            format='json',
        )

        self.assertEqual(response.status_code, 200)
        self.assertTrue(response.data['microphone_enabled'])
        self.assertTrue(response.data['camera_enabled'])
        self.assertEqual(response.data['eke_voice_gender'], 'male')

    def test_customer_cannot_read_producer_preferences(self):
        customer = User.objects.create_user(email='privacy-customer@example.com', password='StrongPass123!')
        self.client.force_authenticate(customer)

        response = self.client.get(self.url)

        self.assertEqual(response.status_code, 403)

    def test_invalid_voice_choice_is_rejected(self):
        self.client.force_authenticate(self.producer)

        response = self.client.patch(self.url, {'eke_voice_gender': 'robot'}, format='json')

        self.assertEqual(response.status_code, 400)
