from django.test import override_settings
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from core.models import Content, Genre, Profile, Recommendation, User, WatchHistory


class RecommendationEngineApiTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            email='reco@example.com',
            password='StrongPass123',
            firstname='Reco',
        )
        self.profile = Profile.objects.get(user=self.user)
        self.genre = Genre.objects.create(name='Sci-Fi', slug='sci-fi')
        self.watched = Content.objects.create(
            title='Watched Space',
            type='movie',
            popularity_score=60,
            trending_score=40,
        )
        self.candidate = Content.objects.create(
            title='Recommended Space',
            type='movie',
            popularity_score=80,
            trending_score=50,
            rating_avg=4.5,
        )
        self.watched.genres.add(self.genre)
        self.candidate.genres.add(self.genre)
        WatchHistory.objects.create(
            profile=self.profile,
            content=self.watched,
            progress=100,
            completed=True,
        )

    @override_settings(NEO4J_ENABLED=False, RECOMMENDATION_ENGINE='django')
    def test_engine_status_reports_django_fallback(self):
        self.client.force_authenticate(user=self.user)

        response = self.client.get(reverse('recommendation-engine-status'))

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['active_engine'], 'django')
        self.assertFalse(response.data['neo4j_enabled'])

    @override_settings(NEO4J_ENABLED=False, RECOMMENDATION_ENGINE='django')
    def test_generate_recommendations_uses_django_fallback(self):
        self.client.force_authenticate(user=self.user)

        response = self.client.post(
            reverse('recommendation-generate'),
            {'profile_id': str(self.profile.id), 'limit': 5},
            format='json',
        )

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['engine'], 'django')
        self.assertEqual(response.data['count'], 1)
        self.assertEqual(Recommendation.objects.count(), 1)
        self.assertEqual(
            response.data['recommendations'][0]['content']['id'],
            str(self.candidate.id),
        )

    @override_settings(NEO4J_ENABLED=False, RECOMMENDATION_ENGINE='django')
    def test_sync_graph_is_safe_when_neo4j_disabled(self):
        self.client.force_authenticate(user=self.user)

        response = self.client.post(
            reverse('recommendation-sync-graph'),
            {'profile_id': str(self.profile.id)},
            format='json',
        )

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertFalse(response.data['enabled'])
        self.assertEqual(response.data['profile_id'], str(self.profile.id))
