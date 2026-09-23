from unittest.mock import patch

from django.urls import reverse
from rest_framework.test import APITestCase

from apps.analytics.services import (
    build_like_analytics_event,
)
from core.models import Content, Genre, Like, User


class LikeAnalyticsBuilderTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            email='like-builder@example.com',
            password='TestPassword123!',
        )
        self.profile = self.user.profiles.first()

        self.producer = User.objects.create_user(
            email='like-producer@example.com',
            password='TestPassword123!',
        )

        self.content = Content.objects.create(
            title='Like Analytics Content',
            type='movie',
            producer=self.producer,
        )

        self.genre_b = Genre.objects.create(
            name='Thriller',
            slug='thriller-like-analytics',
        )
        self.genre_a = Genre.objects.create(
            name='Action',
            slug='action-like-analytics',
        )

        self.content.genres.add(
            self.genre_b,
            self.genre_a,
        )

        self.like = Like.objects.create(
            profile=self.profile,
            content=self.content,
        )

    def test_content_like_snapshot(self):
        event = build_like_analytics_event(
            'content_like',
            self.like,
        )

        self.assertEqual(
            event['event_name'],
            'content_like',
        )
        self.assertEqual(
            event['user_id'],
            str(self.user.id),
        )
        self.assertEqual(
            event['profile_id'],
            str(self.profile.id),
        )
        self.assertEqual(
            event['content_id'],
            str(self.content.id),
        )
        self.assertEqual(
            event['producer_id'],
            str(self.producer.id),
        )
        self.assertEqual(
            event['content_type'],
            'movie',
        )
        self.assertEqual(
            event['genres'],
            ['Action', 'Thriller'],
        )
        self.assertIsNone(
            event['session_id'],
        )
        self.assertIsNone(
            event['viewing_session_id'],
        )
        self.assertEqual(
            event['properties']['like_id'],
            str(self.like.pk),
        )

    def test_content_unlike_snapshot(self):
        event = build_like_analytics_event(
            'content_unlike',
            self.like,
        )

        self.assertEqual(
            event['event_name'],
            'content_unlike',
        )
        self.assertEqual(
            event['content_id'],
            str(self.content.id),
        )

    def test_rejects_unsupported_event(self):
        with self.assertRaises(ValueError):
            build_like_analytics_event(
                'favorite',
                self.like,
            )


class LikeAnalyticsAPITests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            email='like-api-analytics@example.com',
            password='TestPassword123!',
        )
        self.other_user = User.objects.create_user(
            email='like-api-other@example.com',
            password='TestPassword123!',
        )

        self.profile = self.user.profiles.first()
        self.other_profile = self.other_user.profiles.first()

        self.content = Content.objects.create(
            title='Like API Analytics Content',
            type='movie',
        )

        self.client.force_authenticate(self.user)

    @patch(
        'apps.playback.views.'
        'write_analytics_event_task.delay'
    )
    def test_real_create_emits_exactly_one_like_event(
        self,
        delay,
    ):
        with self.captureOnCommitCallbacks(
            execute=True,
        ):
            response = self.client.post(
                reverse('like-list'),
                {
                    'profile_id': self.profile.id,
                    'content_id': self.content.id,
                },
                format='json',
            )

        self.assertEqual(
            response.status_code,
            201,
        )
        self.assertEqual(
            Like.objects.filter(
                profile=self.profile,
                content=self.content,
            ).count(),
            1,
        )

        delay.assert_called_once()

        event = delay.call_args.args[0]

        self.assertEqual(
            event['event_name'],
            'content_like',
        )
        self.assertEqual(
            event['profile_id'],
            str(self.profile.id),
        )
        self.assertEqual(
            event['content_id'],
            str(self.content.id),
        )

    @patch(
        'apps.playback.views.'
        'write_analytics_event_task.delay'
    )
    def test_duplicate_post_emits_no_second_event(
        self,
        delay,
    ):
        Like.objects.create(
            profile=self.profile,
            content=self.content,
        )

        with self.captureOnCommitCallbacks(
            execute=True,
        ):
            response = self.client.post(
                reverse('like-list'),
                {
                    'profile_id': self.profile.id,
                    'content_id': self.content.id,
                },
                format='json',
            )

        self.assertEqual(
            response.status_code,
            201,
        )
        self.assertEqual(
            Like.objects.filter(
                profile=self.profile,
                content=self.content,
            ).count(),
            1,
        )

        delay.assert_not_called()

    @patch(
        'apps.playback.views.'
        'write_analytics_event_task.delay'
    )
    def test_real_delete_emits_exactly_one_unlike_event(
        self,
        delay,
    ):
        like = Like.objects.create(
            profile=self.profile,
            content=self.content,
        )

        with self.captureOnCommitCallbacks(
            execute=True,
        ):
            response = self.client.delete(
                reverse(
                    'like-detail',
                    kwargs={'pk': like.pk},
                ),
            )

        self.assertEqual(
            response.status_code,
            204,
        )
        self.assertFalse(
            Like.objects.filter(
                pk=like.pk,
            ).exists()
        )

        delay.assert_called_once()

        event = delay.call_args.args[0]

        self.assertEqual(
            event['event_name'],
            'content_unlike',
        )
        self.assertEqual(
            event['profile_id'],
            str(self.profile.id),
        )
        self.assertEqual(
            event['content_id'],
            str(self.content.id),
        )

    @patch(
        'apps.playback.views.'
        'write_analytics_event_task.delay'
    )
    def test_cannot_like_with_another_users_profile(
        self,
        delay,
    ):
        with self.captureOnCommitCallbacks(
            execute=True,
        ):
            response = self.client.post(
                reverse('like-list'),
                {
                    'profile_id':
                        self.other_profile.id,
                    'content_id':
                        self.content.id,
                },
                format='json',
            )

        self.assertEqual(
            response.status_code,
            400,
        )
        delay.assert_not_called()

    @patch(
        'apps.playback.views.'
        'write_analytics_event_task.delay'
    )
    def test_cannot_unlike_another_users_like(
        self,
        delay,
    ):
        like = Like.objects.create(
            profile=self.other_profile,
            content=self.content,
        )

        with self.captureOnCommitCallbacks(
            execute=True,
        ):
            response = self.client.delete(
                reverse(
                    'like-detail',
                    kwargs={'pk': like.pk},
                ),
            )

        self.assertEqual(
            response.status_code,
            404,
        )
        self.assertTrue(
            Like.objects.filter(
                pk=like.pk,
            ).exists()
        )
        delay.assert_not_called()
