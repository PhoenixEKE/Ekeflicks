from django.urls import reverse

from rest_framework.test import APITestCase

from datetime import timedelta
from django.utils import timezone

from core.models import Content
from core.models.recommendations import Top10Entry, Top10Snapshot


class FrequentlyAskedQuestionsAPITests(APITestCase):
    def test_public_producer_faq_is_bilingual(self):
        response = self.client.get(reverse('faq-list'), {'audience': 'producer', 'language': 'en'})

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data['language'], 'en')
        self.assertTrue(response.data['results'])
        self.assertTrue(all(row['question'] and row['answer'] for row in response.data['results']))

    def test_admin_faq_is_not_public(self):
        response = self.client.get(reverse('faq-list'), {'audience': 'admin'})

        self.assertEqual(response.status_code, 403)

    def test_eke_answers_only_from_published_producer_faq(self):
        response = self.client.post(
            reverse('producer-eke-chat'),
            {'message': 'Comment demander un changement d’adresse e-mail ?', 'language': 'fr'},
            format='json',
        )

        self.assertEqual(response.status_code, 200)
        self.assertTrue(response.data['grounded'])
        self.assertEqual(response.data['assistant'], 'eke-producer-v1')
        self.assertTrue(response.data['matches'])
        self.assertTrue(all(row['answer'] for row in response.data['matches']))

    def test_eke_uses_selected_interface_language_from_accept_language(self):
        response = self.client.post(
            reverse('producer-eke-chat'),
            {'message': 'How do I choose a male or female voice for Eke?'},
            format='json',
            HTTP_ACCEPT_LANGUAGE='en-GB,en;q=0.9',
        )

        self.assertEqual(response.status_code, 200)
        self.assertIn('Voice selector', response.data['reply'])
        self.assertNotIn('choisissez Homme ou Femme', response.data['reply'])

    def test_eke_prefers_the_producer_language_sent_by_the_interface(self):
        response = self.client.post(
            reverse('producer-eke-chat'),
            {
                'message': 'How do I choose a male or female voice for Eke?',
                'language': 'en',
            },
            format='json',
            HTTP_ACCEPT_LANGUAGE='fr-FR,fr;q=0.9',
        )

        self.assertEqual(response.status_code, 200)
        self.assertIn('Voice selector', response.data['reply'])
        self.assertEqual(response.data['assistant'], 'eke-producer-v1')

    def test_eke_answers_top10_from_latest_published_snapshot(self):
        end = timezone.now()
        snapshot = Top10Snapshot.objects.create(
            window_start=end - timedelta(days=7),
            window_end=end,
            scope=Top10Snapshot.SCOPE_GLOBAL,
            algorithm_version=Top10Snapshot.ALGORITHM_V1,
            is_published=True,
        )
        content = Content.objects.create(
            title='Film public classé premier',
            type='movie',
            producer_submission_status='approved',
        )
        Top10Entry.objects.create(
            snapshot=snapshot,
            content=content,
            position=1,
            qualified_views=120,
            watch_seconds=900,
            unique_viewers=90,
            completed_views=45,
            qualification_rate_percent='60.00',
            movement='new',
        )

        response = self.client.post(
            reverse('producer-eke-chat'),
            {'message': 'Quel est le film en première position du Top 10 ?', 'language': 'fr'},
            format='json',
        )

        self.assertEqual(response.status_code, 200)
        self.assertIn(content.title, response.data['reply'])
        self.assertNotIn('120', response.data['reply'])
