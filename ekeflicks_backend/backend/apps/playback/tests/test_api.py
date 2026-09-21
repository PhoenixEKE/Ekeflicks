from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from core.models import Content, Favorite, Like, Profile, User, WatchHistory


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


class LikeAPITests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            email='like-user@example.com',
            password='TestPassword123!',
        )
        self.other_user = User.objects.create_user(
            email='like-other@example.com',
            password='TestPassword123!',
        )

        self.profile = self.user.profiles.first()
        self.other_profile = self.other_user.profiles.first()

        self.content = Content.objects.create(
            title='Like Test Content',
            type='movie',
        )

        self.client.force_authenticate(self.user)

    def test_like_can_be_created_for_own_profile(self):
        response = self.client.post(
            reverse('like-list'),
            {
                'profile_id': self.profile.id,
                'content_id': self.content.id,
            },
            format='json',
        )

        self.assertEqual(response.status_code, 201)
        self.assertEqual(
            Like.objects.filter(
                profile=self.profile,
                content=self.content,
            ).count(),
            1,
        )

    def test_like_rejects_profile_owned_by_another_user(self):
        response = self.client.post(
            reverse('like-list'),
            {
                'profile_id': self.other_profile.id,
                'content_id': self.content.id,
            },
            format='json',
        )

        self.assertEqual(response.status_code, 400)
        self.assertFalse(
            Like.objects.filter(
                profile=self.other_profile,
                content=self.content,
            ).exists()
        )

    def test_duplicate_like_does_not_create_duplicate(self):
        Like.objects.create(
            profile=self.profile,
            content=self.content,
        )

        response = self.client.post(
            reverse('like-list'),
            {
                'profile_id': self.profile.id,
                'content_id': self.content.id,
            },
            format='json',
        )

        self.assertEqual(response.status_code, 201)
        self.assertEqual(
            Like.objects.filter(
                profile=self.profile,
                content=self.content,
            ).count(),
            1,
        )

    def test_like_can_be_deleted(self):
        like = Like.objects.create(
            profile=self.profile,
            content=self.content,
        )

        response = self.client.delete(
            reverse('like-detail', kwargs={'pk': like.pk}),
        )

        self.assertEqual(response.status_code, 204)
        self.assertFalse(
            Like.objects.filter(pk=like.pk).exists()
        )

    def test_user_cannot_delete_another_users_like(self):
        like = Like.objects.create(
            profile=self.other_profile,
            content=self.content,
        )

        response = self.client.delete(
            reverse('like-detail', kwargs={'pk': like.pk}),
        )

        self.assertEqual(response.status_code, 404)
        self.assertTrue(
            Like.objects.filter(pk=like.pk).exists()
        )
