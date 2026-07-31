from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from core.models import Profile, User


class ProfileApiTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            email='owner@example.com',
            password='StrongPass123',
            firstname='Owner',
        )
        self.other_user = User.objects.create_user(
            email='other@example.com',
            password='StrongPass123',
            firstname='Other',
        )
        self.profile = Profile.objects.get(user=self.user)

    def test_profiles_require_authentication(self):
        response = self.client.get(reverse('profile-list'))

        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_profiles_are_limited_to_current_user(self):
        self.client.force_authenticate(user=self.user)

        response = self.client.get(reverse('profile-list'))

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        payload = response.data['results'] if 'results' in response.data else response.data
        self.assertEqual(len(payload), 1)
        self.assertEqual(payload[0]['id'], str(self.profile.id))
