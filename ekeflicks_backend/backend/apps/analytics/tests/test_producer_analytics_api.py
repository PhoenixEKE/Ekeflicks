from django.conf import settings
from django.urls import reverse
from django.utils import timezone

from rest_framework.test import APITestCase

from core.models import Content, User
from core.models.producers import (
    ProducerAccount,
    ProducerAgreement,
)


class ProducerAnalyticsAPITests(
    APITestCase
):
    def setUp(self):
        self.url = reverse(
            'producer-analytics-list'
        )

        self.producer = (
            self._active_producer(
                'producer-d8-b1@example.com'
            )
        )

        self.other_producer = (
            self._active_producer(
                'producer-d8-b1-other@example.com'
            )
        )

        self.own_content = (
            Content.objects.create(
                title='Own producer content',
                type='movie',
                producer=self.producer,
            )
        )

        self.foreign_content = (
            Content.objects.create(
                title='Foreign producer content',
                type='movie',
                producer=self.other_producer,
            )
        )

    def _active_producer(
        self,
        email,
    ):
        user = User.objects.create_user(
            email=email,
            password='StrongPass123!',
            is_producer=True,
        )

        user.is_verified = True
        user.save(
            update_fields=[
                'is_verified',
            ]
        )

        account = (
            ProducerAccount.objects.create(
                user=user,
                company_name=(
                    f'Company {email}'
                ),
                status=(
                    ProducerAccount
                    .STATUS_ACTIVE
                ),
                activated_at=timezone.now(),
            )
        )

        ProducerAgreement.objects.create(
            producer_account=account,
            contract_version=(
                settings
                .PRODUCER_AGREEMENT_ACCEPTED_VERSIONS[0]
            ),
            contract_title=(
                'EKEFLICKS Producer Agreement'
            ),
            status=(
                ProducerAgreement
                .STATUS_SIGNED
            ),
            accepted_at=timezone.now(),
            signed_at=timezone.now(),
        )

        return user

    def test_anonymous_user_is_rejected(
        self,
    ):
        response = self.client.get(
            self.url
        )

        self.assertEqual(
            response.status_code,
            401,
        )

    def test_active_producer_receives_only_own_content_ids(
        self,
    ):
        self.client.force_authenticate(
            self.producer
        )

        response = self.client.get(
            self.url
        )

        self.assertEqual(
            response.status_code,
            200,
        )

        returned_ids = {
            str(value)
            for value
            in response.data.get(
                'content_ids',
                [],
            )
        }

        # B3 may no longer expose raw content_ids.
        # When absent, verify content_count instead.
        if returned_ids:
            self.assertIn(
                str(
                    self.own_content.id
                ),
                returned_ids,
            )

            self.assertNotIn(
                str(
                    self.foreign_content.id
                ),
                returned_ids,
            )
        else:
            self.assertEqual(
                response.data[
                    'content_count'
                ],
                1,
            )

    def test_active_producer_without_content_has_empty_scope(
        self,
    ):
        empty_producer = (
            self._active_producer(
                'empty-d8-b1@example.com'
            )
        )

        self.client.force_authenticate(
            empty_producer
        )

        response = self.client.get(
            self.url
        )

        self.assertEqual(
            response.status_code,
            200,
        )

        self.assertEqual(
            response.data[
                'content_count'
            ],
            0,
        )

        self.assertEqual(
            response.data.get(
                'results',
                [],
            ),
            [],
        )

    def test_client_producer_parameter_is_rejected(
        self,
    ):
        self.client.force_authenticate(
            self.producer
        )

        response = self.client.get(
            self.url,
            {
                'producer':
                    str(
                        self.other_producer.id
                    ),
            },
        )

        self.assertEqual(
            response.status_code,
            400,
        )

        self.assertIn(
            'producer',
            response.data,
        )

    def test_client_producer_id_parameter_is_rejected(
        self,
    ):
        self.client.force_authenticate(
            self.producer
        )

        response = self.client.get(
            self.url,
            {
                'producer_id':
                    str(
                        self.other_producer.id
                    ),
            },
        )

        self.assertEqual(
            response.status_code,
            400,
        )

        self.assertIn(
            'producer_id',
            response.data,
        )

    def test_inactive_producer_is_forbidden(
        self,
    ):
        inactive = (
            self._active_producer(
                'inactive-d8-b1@example.com'
            )
        )

        inactive.producer_account.status = (
            ProducerAccount
            .STATUS_ONBOARDING
        )

        inactive.producer_account.save(
            update_fields=[
                'status',
            ]
        )

        self.client.force_authenticate(
            inactive
        )

        response = self.client.get(
            self.url
        )

        self.assertEqual(
            response.status_code,
            403,
        )

    def test_staff_is_self_scoped_not_global(
        self,
    ):
        staff = User.objects.create_user(
            email='staff-d8-b1@example.com',
            password='StrongPass123!',
            is_staff=True,
        )

        staff_content = (
            Content.objects.create(
                title='Staff owned content',
                type='movie',
                producer=staff,
            )
        )

        Content.objects.create(
            title='Another producer content',
            type='movie',
            producer=self.producer,
        )

        self.client.force_authenticate(
            staff
        )

        response = self.client.get(
            self.url
        )

        self.assertEqual(
            response.status_code,
            200,
        )

        self.assertEqual(
            response.data[
                'content_count'
            ],
            1,
        )

        returned_ids = {
            str(value)
            for value
            in response.data.get(
                'content_ids',
                [],
            )
        }

        if returned_ids:
            self.assertEqual(
                returned_ids,
                {
                    str(
                        staff_content.id
                    )
                },
            )
