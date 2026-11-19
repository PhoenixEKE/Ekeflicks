from datetime import (
    datetime,
    timezone as dt_timezone,
)
from unittest.mock import patch

from django.conf import settings
from django.urls import reverse
from django.utils import timezone

from rest_framework.test import APITestCase

from core.models import Content, User
from core.models.producers import (
    ProducerAccount,
    ProducerAgreement,
)


class ProducerAnalyticsKPIAPITests(
    APITestCase
):
    def setUp(self):
        self.url = reverse(
            'producer-analytics-list'
        )

        self.start = datetime(
            2026,
            9,
            1,
            tzinfo=dt_timezone.utc,
        )

        self.end = datetime(
            2026,
            9,
            10,
            tzinfo=dt_timezone.utc,
        )

        self.producer = (
            self._active_producer(
                'producer-d8-b3@example.com'
            )
        )

        self.other_producer = (
            self._active_producer(
                'producer-d8-b3-other@example.com'
            )
        )

        self.own_content = (
            Content.objects.create(
                title='Producer KPI own movie',
                type='movie',
                producer=self.producer,
            )
        )

        self.foreign_content = (
            Content.objects.create(
                title='Producer KPI foreign movie',
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

    def _window(self):
        return {
            'start_at':
                self.start.isoformat(),

            'end_at':
                self.end.isoformat(),
        }

    def test_rejects_client_producer_id(
        self,
    ):
        self.client.force_authenticate(
            self.producer
        )

        response = self.client.get(
            self.url,
            {
                **self._window(),

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

    def test_rejects_client_producer(
        self,
    ):
        self.client.force_authenticate(
            self.producer
        )

        response = self.client.get(
            self.url,
            {
                **self._window(),

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

    @patch(
        'apps.analytics.services.'
        'producer_content_video_analytics'
    )
    def test_empty_scope_does_not_call_kpi_engine(
        self,
        analytics_mock,
    ):
        empty = self._active_producer(
            'empty-d8-b3@example.com'
        )

        self.client.force_authenticate(
            empty
        )

        response = self.client.get(
            self.url,
            self._window(),
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
            response.data[
                'results'
            ],
            [],
        )

        analytics_mock.assert_not_called()

    @patch(
        'apps.analytics.services.'
        'producer_content_video_analytics'
    )
    def test_engine_receives_only_postgresql_owned_ids(
        self,
        analytics_mock,
    ):
        analytics_mock.return_value = []

        self.client.force_authenticate(
            self.producer
        )

        response = self.client.get(
            self.url,
            self._window(),
        )

        self.assertEqual(
            response.status_code,
            200,
        )

        analytics_mock.assert_called_once()

        kwargs = (
            analytics_mock
            .call_args
            .kwargs
        )

        allowed = {
            str(value)
            for value
            in kwargs[
                'allowed_content_ids'
            ]
        }

        self.assertEqual(
            allowed,
            {
                str(
                    self.own_content.id
                )
            },
        )

        self.assertNotIn(
            str(
                self.foreign_content.id
            ),
            allowed,
        )

    @patch(
        'apps.analytics.services.'
        'producer_content_video_analytics'
    )
    def test_results_are_enriched_from_postgresql(
        self,
        analytics_mock,
    ):
        analytics_mock.return_value = [
            {
                'dimension':
                    'content',

                'value':
                    str(
                        self.own_content.id
                    ),

                'events':
                    12,

                'play_starts':
                    5,

                'qualified_views':
                    4,

                'unique_viewers':
                    3,

                'watch_seconds':
                    900,

                'completed_views':
                    2,

                'qualification_rate_percent':
                    80.0,

                'completion_percent_avg':
                    75.0,
            }
        ]

        self.client.force_authenticate(
            self.producer
        )

        response = self.client.get(
            self.url,
            self._window(),
        )

        self.assertEqual(
            response.status_code,
            200,
        )

        self.assertEqual(
            response.data[
                'result_count'
            ],
            1,
        )

        item = (
            response.data[
                'results'
            ][0]
        )

        self.assertEqual(
            item[
                'content_id'
            ],
            str(
                self.own_content.id
            ),
        )

        self.assertEqual(
            item[
                'title'
            ],
            self.own_content.title,
        )

        self.assertEqual(
            item[
                'type'
            ],
            self.own_content.type,
        )

        self.assertEqual(
            item[
                'qualified_views'
            ],
            4,
        )

        self.assertNotIn(
            'dimension',
            item,
        )

        self.assertNotIn(
            'value',
            item,
        )

    @patch(
        'apps.analytics.services.'
        'producer_content_video_analytics'
    )
    def test_foreign_row_is_dropped_defensively(
        self,
        analytics_mock,
    ):
        analytics_mock.return_value = [
            {
                'dimension':
                    'content',

                'value':
                    str(
                        self.foreign_content.id
                    ),

                'events':
                    99,

                'play_starts':
                    50,

                'qualified_views':
                    40,

                'unique_viewers':
                    30,

                'watch_seconds':
                    9999,

                'completed_views':
                    25,

                'qualification_rate_percent':
                    80.0,

                'completion_percent_avg':
                    90.0,
            }
        ]

        self.client.force_authenticate(
            self.producer
        )

        response = self.client.get(
            self.url,
            self._window(),
        )

        self.assertEqual(
            response.status_code,
            200,
        )

        self.assertEqual(
            response.data[
                'result_count'
            ],
            0,
        )

        self.assertEqual(
            response.data[
                'results'
            ],
            [],
        )

    def test_invalid_window_is_400(
        self,
    ):
        self.client.force_authenticate(
            self.producer
        )

        response = self.client.get(
            self.url,
            {
                'start_at':
                    self.end.isoformat(),

                'end_at':
                    self.start.isoformat(),
            },
        )

        self.assertEqual(
            response.status_code,
            400,
        )

    def test_invalid_limit_is_400(
        self,
    ):
        self.client.force_authenticate(
            self.producer
        )

        response = self.client.get(
            self.url,
            {
                **self._window(),

                'limit':
                    '1001',
            },
        )

        self.assertEqual(
            response.status_code,
            400,
        )

    @patch(
        'apps.analytics.services.'
        'producer_content_video_analytics'
    )
    def test_staff_endpoint_is_self_scoped(
        self,
        analytics_mock,
    ):
        analytics_mock.return_value = []

        staff = User.objects.create_user(
            email='staff-d8-b3@example.com',
            password='StrongPass123!',
            is_staff=True,
        )

        staff_content = (
            Content.objects.create(
                title='Staff owned KPI content',
                type='movie',
                producer=staff,
            )
        )

        self.client.force_authenticate(
            staff
        )

        response = self.client.get(
            self.url,
            self._window(),
        )

        self.assertEqual(
            response.status_code,
            200,
        )

        analytics_mock.assert_called_once()

        allowed = {
            str(value)
            for value in (
                analytics_mock
                .call_args
                .kwargs[
                    'allowed_content_ids'
                ]
            )
        }

        self.assertEqual(
            allowed,
            {
                str(
                    staff_content.id
                )
            },
        )

        self.assertNotIn(
            str(
                self.own_content.id
            ),
            allowed,
        )
