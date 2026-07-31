from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from core.models import Content, Favorite, Profile, User, WatchHistory


class PlaybackApiTests(APITestCase):
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
        self.other_profile = Profile.objects.get(user=self.other_user)
        self.content = Content.objects.create(title='Private Flow', type='movie')

    def test_favorite_rejects_profile_owned_by_another_user(self):
        self.client.force_authenticate(user=self.user)

        response = self.client.post(
            reverse('favorite-list'),
            {
                'profile_id': str(self.other_profile.id),
                'content_id': str(self.content.id),
            },
            format='json',
        )

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertFalse(Favorite.objects.exists())

    def test_favorite_can_be_created_for_own_profile(self):
        self.client.force_authenticate(user=self.user)

        response = self.client.post(
            reverse('favorite-list'),
            {
                'profile_id': str(self.profile.id),
                'content_id': str(self.content.id),
            },
            format='json',
        )

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(Favorite.objects.count(), 1)

    def test_watch_history_updates_existing_progress(self):
        self.client.force_authenticate(user=self.user)
        url = reverse('watch-history-list')

        first_response = self.client.post(
            url,
            {
                'profile_id': str(self.profile.id),
                'content_id': str(self.content.id),
                'progress': 20,
                'last_position': 120,
            },
            format='json',
        )
        second_response = self.client.post(
            url,
            {
                'profile_id': str(self.profile.id),
                'content_id': str(self.content.id),
                'progress': 80,
                'last_position': 480,
                'completed': True,
            },
            format='json',
        )

        self.assertEqual(first_response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(second_response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(WatchHistory.objects.count(), 1)
        history = WatchHistory.objects.get()
        self.assertEqual(history.progress, 80)
        self.assertTrue(history.completed)

    def test_continue_watching_returns_unfinished_items(self):
        completed_content = Content.objects.create(title='Finished Flow', type='movie')
        WatchHistory.objects.create(
            profile=self.profile,
            content=self.content,
            progress=35,
            last_position=210,
            completed=False,
        )
        WatchHistory.objects.create(
            profile=self.profile,
            content=completed_content,
            progress=100,
            completed=True,
        )
        self.client.force_authenticate(user=self.user)

        response = self.client.get(reverse('watch-history-continue-watching'))

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]['content']['id'], str(self.content.id))
        self.assertEqual(response.data[0]['progress'], 35)
