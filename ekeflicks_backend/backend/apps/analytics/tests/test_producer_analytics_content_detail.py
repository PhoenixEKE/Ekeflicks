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


class ProducerAnalyticsContentDetailTests(
    APITestCase
):
    def setUp(self):
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
                'producer-d8-b4@example.com'
            )
        )

        self.other_producer = (
            self._active_producer(
                'producer-d8-b4-other@example.com'
            )
        )

        self.own_content = (
            Content.objects.create(
                title='Owned B4 Content',
                type='movie',
                producer=self.producer,
            )
        )

        self.foreign_content = (
            Content.objects.create(
                title='Foreign B4 Content',
                type='series',
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
                activated_at=
                    timezone.now(),
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
            accepted_at=
                timezone.now(),
            signed_at=
                timezone.now(),
        )

        return user

    def _url(
        self,
        content_id,
    ):
        return reverse(
            'producer-analytics-content-detail',
            kwargs={
                'content_id':
                    str(content_id),
            },
        )

    def _window(self):
        return {
            'start_at':
                self.start.isoformat(),

            'end_at':
                self.end.isoformat(),
        }

    @patch(
        'apps.analytics.services.'
        'producer_content_video_analytics'
    )
    def test_owned_content_queries_only_that_content(
        self,
        analytics_mock,
    ):
        analytics_mock.return_value = []

        self.client.force_authenticate(
            self.producer
        )

        response = self.client.get(
            self._url(
                self.own_content.id
            ),
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

        self.assertEqual(
            [
                str(value)
                for value
                in kwargs[
                    'allowed_content_ids'
                ]
            ],
            [
                str(
                    self.own_content.id
                )
            ],
        )

        self.assertEqual(
            kwargs[
                'limit'
            ],
            1,
        )

    @patch(
        'apps.analytics.services.'
        'producer_content_video_analytics'
    )
    def test_foreign_content_is_404_before_clickhouse(
        self,
        analytics_mock,
    ):
        self.client.force_authenticate(
            self.producer
        )

        response = self.client.get(
            self._url(
                self.foreign_content.id
            ),
            self._window(),
        )

        self.assertEqual(
            response.status_code,
            404,
        )

        analytics_mock.assert_not_called()

    @patch(
        'apps.analytics.services.'
        'producer_content_video_analytics'
    )
    def test_unknown_content_is_404_before_clickhouse(
        self,
        analytics_mock,
    ):
        import uuid

        self.client.force_authenticate(
            self.producer
        )

        response = self.client.get(
            self._url(
                uuid.uuid4()
            ),
            self._window(),
        )

        self.assertEqual(
            response.status_code,
            404,
        )

        analytics_mock.assert_not_called()

    @patch(
        'apps.analytics.services.'
        'producer_content_video_analytics'
    )
    def test_malformed_content_id_is_404_before_clickhouse(
        self,
        analytics_mock,
    ):
        self.client.force_authenticate(
            self.producer
        )

        response = self.client.get(
            self._url(
                'not-a-uuid'
            ),
            self._window(),
        )

        self.assertEqual(
            response.status_code,
            404,
        )

        analytics_mock.assert_not_called()

    @patch(
        'apps.analytics.services.'
        'producer_content_video_analytics'
    )
    def test_owned_content_without_analytics_returns_zero_metrics(
        self,
        analytics_mock,
    ):
        analytics_mock.return_value = []

        self.client.force_authenticate(
            self.producer
        )

        response = self.client.get(
            self._url(
                self.own_content.id
            ),
            self._window(),
        )

        self.assertEqual(
            response.status_code,
            200,
        )

        self.assertEqual(
            response.data[
                'content'
            ][
                'content_id'
            ],
            str(
                self.own_content.id
            ),
        )

        self.assertEqual(
            response.data[
                'metrics'
            ],
            {
                'events': 0,
                'play_starts': 0,
                'qualified_views': 0,
                'unique_viewers': 0,
                'watch_seconds': 0,
                'completed_views': 0,
                'qualification_rate_percent':
                    0.0,
                'completion_percent_avg':
                    0.0,
            },
        )

    @patch(
        'apps.analytics.services.'
        'producer_content_video_analytics'
    )
    def test_owned_content_returns_d4_metrics(
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
                    20,

                'play_starts':
                    8,

                'qualified_views':
                    6,

                'unique_viewers':
                    5,

                'watch_seconds':
                    1500,

                'completed_views':
                    4,

                'qualification_rate_percent':
                    75.0,

                'completion_percent_avg':
                    82.5,
            }
        ]

        self.client.force_authenticate(
            self.producer
        )

        response = self.client.get(
            self._url(
                self.own_content.id
            ),
            self._window(),
        )

        self.assertEqual(
            response.status_code,
            200,
        )

        self.assertEqual(
            response.data[
                'content'
            ][
                'title'
            ],
            self.own_content.title,
        )

        self.assertEqual(
            response.data[
                'content'
            ][
                'type'
            ],
            self.own_content.type,
        )

        metrics = (
            response.data[
                'metrics'
            ]
        )

        self.assertEqual(
            metrics[
                'qualified_views'
            ],
            6,
        )

        self.assertEqual(
            metrics[
                'watch_seconds'
            ],
            1500,
        )

        self.assertEqual(
            metrics[
                'completed_views'
            ],
            4,
        )

    @patch(
        'apps.analytics.services.'
        'producer_content_video_analytics'
    )
    def test_mismatching_clickhouse_row_is_not_exposed(
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
                    999,

                'play_starts':
                    999,

                'qualified_views':
                    999,

                'unique_viewers':
                    999,

                'watch_seconds':
                    999999,

                'completed_views':
                    999,

                'qualification_rate_percent':
                    100.0,

                'completion_percent_avg':
                    100.0,
            }
        ]

        self.client.force_authenticate(
            self.producer
        )

        response = self.client.get(
            self._url(
                self.own_content.id
            ),
            self._window(),
        )

        self.assertEqual(
            response.status_code,
            200,
        )

        self.assertEqual(
            response.data[
                'metrics'
            ][
                'qualified_views'
            ],
            0,
        )

        self.assertEqual(
            response.data[
                'metrics'
            ][
                'watch_seconds'
            ],
            0,
        )

    @patch(
        'apps.analytics.services.'
        'producer_content_video_analytics'
    )
    def test_producer_override_rejected_before_clickhouse(
        self,
        analytics_mock,
    ):
        self.client.force_authenticate(
            self.producer
        )

        response = self.client.get(
            self._url(
                self.own_content.id
            ),
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

        analytics_mock.assert_not_called()

    @patch(
        'apps.analytics.services.'
        'producer_content_video_analytics'
    )
    def test_invalid_window_rejected_before_clickhouse(
        self,
        analytics_mock,
    ):
        self.client.force_authenticate(
            self.producer
        )

        response = self.client.get(
            self._url(
                self.own_content.id
            ),
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

        analytics_mock.assert_not_called()

    @patch(
        'apps.analytics.services.'
        'producer_content_video_analytics'
    )
    def test_staff_is_self_scoped_on_content_detail(
        self,
        analytics_mock,
    ):
        analytics_mock.return_value = []

        staff = User.objects.create_user(
            email='staff-d8-b4@example.com',
            password='StrongPass123!',
            is_staff=True,
        )

        staff_content = (
            Content.objects.create(
                title='Staff B4 Content',
                type='movie',
                producer=staff,
            )
        )

        self.client.force_authenticate(
            staff
        )

        own_response = self.client.get(
            self._url(
                staff_content.id
            ),
            self._window(),
        )

        self.assertEqual(
            own_response.status_code,
            200,
        )

        analytics_mock.assert_called_once()

        analytics_mock.reset_mock()

        foreign_response = self.client.get(
            self._url(
                self.own_content.id
            ),
            self._window(),
        )

        self.assertEqual(
            foreign_response.status_code,
            404,
        )

        analytics_mock.assert_not_called()
