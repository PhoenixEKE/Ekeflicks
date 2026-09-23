from django.conf import settings
from django.contrib.auth import get_user_model
from django.test import override_settings
from django.utils import timezone

from rest_framework.test import APITestCase

from core.models.content import Content
from core.models.producers import (
    ProducerAccount,
    ProducerAgreement,
)


User = get_user_model()


@override_settings(
    PRODUCER_AGREEMENT_ACCEPTED_VERSIONS=['test-v1']
)
class ProducerAnalyticsAPITests(APITestCase):
    endpoint = '/api/v1/producer-analytics/'

    def create_active_producer(
        self,
        *,
        email,
        company_name,
    ):
        user = User.objects.create_user(
            email=email,
            password='test-password',
            is_producer=True,
            is_verified=True,
        )

        account = ProducerAccount.objects.create(
            user=user,
            company_name=company_name,
            status=ProducerAccount.STATUS_ACTIVE,
            activated_at=timezone.now(),
        )

        ProducerAgreement.objects.create(
            producer_account=account,
            contract_version='test-v1',
            status=ProducerAgreement.STATUS_SIGNED,
            signed_at=timezone.now(),
        )

        return user

    def test_anonymous_user_is_rejected(self):
        response = self.client.get(
            self.endpoint
        )

        self.assertIn(
            response.status_code,
            (401, 403),
        )

    def test_active_producer_receives_only_own_content_ids(self):
        producer = self.create_active_producer(
            email='producer-a@example.com',
            company_name='Producer A',
        )

        other = self.create_active_producer(
            email='producer-b@example.com',
            company_name='Producer B',
        )

        own_movie = Content.objects.create(
            title='Own Movie',
            type='movie',
            producer=producer,
        )

        own_series = Content.objects.create(
            title='Own Series',
            type='series',
            producer=producer,
        )

        foreign_content = Content.objects.create(
            title='Foreign Movie',
            type='movie',
            producer=other,
        )

        self.client.force_authenticate(
            user=producer
        )

        response = self.client.get(
            self.endpoint
        )

        self.assertEqual(
            response.status_code,
            200,
        )

        self.assertEqual(
            response.data['scope'],
            'producer',
        )

        self.assertEqual(
            response.data['producer_id'],
            str(producer.id),
        )

        self.assertEqual(
            response.data['content_count'],
            2,
        )

        returned = set(
            response.data['content_ids']
        )

        self.assertEqual(
            returned,
            {
                str(own_movie.id),
                str(own_series.id),
            },
        )

        self.assertNotIn(
            str(foreign_content.id),
            returned,
        )

    def test_client_producer_parameter_cannot_expand_scope(self):
        producer = self.create_active_producer(
            email='producer-a-scope@example.com',
            company_name='Producer A Scope',
        )

        other = self.create_active_producer(
            email='producer-b-scope@example.com',
            company_name='Producer B Scope',
        )

        own_content = Content.objects.create(
            title='Own Content',
            type='movie',
            producer=producer,
        )

        foreign_content = Content.objects.create(
            title='Foreign Content',
            type='movie',
            producer=other,
        )

        self.client.force_authenticate(
            user=producer
        )

        response = self.client.get(
            self.endpoint,
            {
                'producer': str(other.id),
                'producer_id': str(other.id),
            },
        )

        self.assertEqual(
            response.status_code,
            200,
        )

        self.assertEqual(
            response.data['content_ids'],
            [str(own_content.id)],
        )

        self.assertNotIn(
            str(foreign_content.id),
            response.data['content_ids'],
        )

    def test_active_producer_without_content_has_empty_scope(self):
        producer = self.create_active_producer(
            email='empty-producer@example.com',
            company_name='Empty Producer',
        )

        self.client.force_authenticate(
            user=producer
        )

        response = self.client.get(
            self.endpoint
        )

        self.assertEqual(
            response.status_code,
            200,
        )

        self.assertEqual(
            response.data['content_count'],
            0,
        )

        self.assertEqual(
            response.data['content_ids'],
            [],
        )

    def test_inactive_producer_is_forbidden(self):
        user = User.objects.create_user(
            email='inactive-producer@example.com',
            password='test-password',
            is_producer=True,
            is_verified=True,
        )

        ProducerAccount.objects.create(
            user=user,
            company_name='Inactive Producer',
            status=ProducerAccount.STATUS_SUSPENDED,
        )

        self.client.force_authenticate(
            user=user
        )

        response = self.client.get(
            self.endpoint
        )

        self.assertEqual(
            response.status_code,
            403,
        )

    def test_staff_is_not_implicitly_global_on_producer_endpoint(self):
        staff = User.objects.create_user(
            email='analytics-staff@example.com',
            password='test-password',
            is_staff=True,
        )

        producer = self.create_active_producer(
            email='staff-test-producer@example.com',
            company_name='Staff Test Producer',
        )

        Content.objects.create(
            title='Producer Private Content',
            type='movie',
            producer=producer,
        )

        self.client.force_authenticate(
            user=staff
        )

        response = self.client.get(
            self.endpoint
        )

        self.assertEqual(
            response.status_code,
            403,
        )
