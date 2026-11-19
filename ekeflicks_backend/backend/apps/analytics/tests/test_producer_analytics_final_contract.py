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


class ProducerAnalyticsFinalContractTests(
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

        self.producer = self._active_producer(
            'producer-d8-b7@example.com'
        )

        self.other_producer = self._active_producer(
            'producer-d8-b7-other@example.com'
        )

        self.own_movie = Content.objects.create(
            title='B7 Own Movie',
            type='movie',
            producer=self.producer,
        )

        self.own_series = Content.objects.create(
            title='B7 Own Series',
            type='series',
            producer=self.producer,
        )

        self.foreign_content = Content.objects.create(
            title='B7 Foreign Content',
            type='movie',
            producer=self.other_producer,
        )

        self.list_url = reverse(
            'producer-analytics-list'
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

        account = ProducerAccount.objects.create(
            user=user,
            company_name=f'Company {email}',
            status=ProducerAccount.STATUS_ACTIVE,
            activated_at=timezone.now(),
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
            status=ProducerAgreement.STATUS_SIGNED,
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

    def _detail_url(
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

    def _engagement(
        self,
    ):
        return {
            'start_at':
                self.start.isoformat(),

            'end_at':
                self.end.isoformat(),

            'likes': 5,
            'unlikes': 1,
            'net_likes': 4,
            'unique_likers': 4,
            'unique_viewers': 10,
            'engagement_rate_percent':
                40.0,
            'current_likes': 3,
        }

    @patch(
        'apps.analytics.services.'
        'producer_engagement_analytics'
    )
    @patch(
        'apps.analytics.services.'
        'producer_content_video_analytics'
    )
    def test_overview_final_response_contract(
        self,
        video_mock,
        engagement_mock,
    ):
        video_mock.return_value = [
            {
                'dimension':
                    'content',

                'value':
                    str(
                        self.own_movie.id
                    ),

                'events': 12,
                'play_starts': 5,
                'qualified_views': 4,
                'unique_viewers': 3,
                'watch_seconds': 900,
                'completed_views': 2,

                'qualification_rate_percent':
                    80.0,

                'completion_percent_avg':
                    72.5,
            }
        ]

        engagement_mock.return_value = (
            self._engagement()
        )

        self.client.force_authenticate(
            self.producer
        )

        response = self.client.get(
            self.list_url,
            self._window(),
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
            str(
                self.producer.id
            ),
        )

        self.assertEqual(
            response.data['content_count'],
            2,
        )

        self.assertEqual(
            response.data['result_count'],
            1,
        )

        self.assertIn(
            'results',
            response.data,
        )

        self.assertIn(
            'engagement',
            response.data,
        )

        item = response.data[
            'results'
        ][0]

        self.assertEqual(
            item['content_id'],
            str(
                self.own_movie.id
            ),
        )

        self.assertEqual(
            item['title'],
            self.own_movie.title,
        )

        self.assertEqual(
            item['type'],
            self.own_movie.type,
        )

        self.assertNotIn(
            'dimension',
            item,
        )

        self.assertNotIn(
            'value',
            item,
        )

        self.assertEqual(
            response.data[
                'engagement'
            ][
                'net_likes'
            ],
            4,
        )

    @patch(
        'apps.analytics.services.'
        'producer_engagement_analytics'
    )
    @patch(
        'apps.analytics.services.'
        'producer_content_video_analytics'
    )
    def test_detail_final_response_contract(
        self,
        video_mock,
        engagement_mock,
    ):
        video_mock.return_value = [
            {
                'dimension':
                    'content',

                'value':
                    str(
                        self.own_series.id
                    ),

                'events': 20,
                'play_starts': 8,
                'qualified_views': 6,
                'unique_viewers': 5,
                'watch_seconds': 1500,
                'completed_views': 4,

                'qualification_rate_percent':
                    75.0,

                'completion_percent_avg':
                    82.5,
            }
        ]

        engagement_mock.return_value = (
            self._engagement()
        )

        self.client.force_authenticate(
            self.producer
        )

        response = self.client.get(
            self._detail_url(
                self.own_series.id
            ),
            self._window(),
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
            response.data[
                'content'
            ][
                'content_id'
            ],
            str(
                self.own_series.id
            ),
        )

        self.assertEqual(
            response.data[
                'metrics'
            ][
                'qualified_views'
            ],
            6,
        )

        self.assertEqual(
            response.data[
                'engagement'
            ][
                'current_likes'
            ],
            3,
        )

        video_kwargs = (
            video_mock
            .call_args
            .kwargs
        )

        engagement_kwargs = (
            engagement_mock
            .call_args
            .kwargs
        )

        self.assertEqual(
            [
                str(value)
                for value
                in video_kwargs[
                    'allowed_content_ids'
                ]
            ],
            [
                str(
                    self.own_series.id
                )
            ],
        )

        self.assertEqual(
            [
                str(value)
                for value
                in engagement_kwargs[
                    'allowed_content_ids'
                ]
            ],
            [
                str(
                    self.own_series.id
                )
            ],
        )

    @patch(
        'apps.analytics.services.'
        'producer_engagement_analytics'
    )
    @patch(
        'apps.analytics.services.'
        'producer_content_video_analytics'
    )
    def test_foreign_detail_never_reaches_analytics(
        self,
        video_mock,
        engagement_mock,
    ):
        self.client.force_authenticate(
            self.producer
        )

        response = self.client.get(
            self._detail_url(
                self.foreign_content.id
            ),
            self._window(),
        )

        self.assertEqual(
            response.status_code,
            404,
        )

        video_mock.assert_not_called()
        engagement_mock.assert_not_called()

    @patch(
        'apps.analytics.services.'
        'producer_engagement_analytics'
    )
    @patch(
        'apps.analytics.services.'
        'producer_content_video_analytics'
    )
    def test_overview_scope_contains_only_owned_ids(
        self,
        video_mock,
        engagement_mock,
    ):
        video_mock.return_value = []
        engagement_mock.return_value = (
            self._engagement()
        )

        self.client.force_authenticate(
            self.producer
        )

        response = self.client.get(
            self.list_url,
            self._window(),
        )

        self.assertEqual(
            response.status_code,
            200,
        )

        video_ids = {
            str(value)
            for value
            in video_mock
            .call_args
            .kwargs[
                'allowed_content_ids'
            ]
        }

        engagement_ids = {
            str(value)
            for value
            in engagement_mock
            .call_args
            .kwargs[
                'allowed_content_ids'
            ]
        }

        expected = {
            str(
                self.own_movie.id
            ),
            str(
                self.own_series.id
            ),
        }

        self.assertEqual(
            video_ids,
            expected,
        )

        self.assertEqual(
            engagement_ids,
            expected,
        )

        self.assertNotIn(
            str(
                self.foreign_content.id
            ),
            video_ids,
        )

        self.assertNotIn(
            str(
                self.foreign_content.id
            ),
            engagement_ids,
        )

    @patch(
        'apps.analytics.services.'
        'producer_engagement_analytics'
    )
    @patch(
        'apps.analytics.services.'
        'producer_content_video_analytics'
    )
    def test_empty_scope_final_contract(
        self,
        video_mock,
        engagement_mock,
    ):
        empty = self._active_producer(
            'producer-d8-b7-empty@example.com'
        )

        engagement_mock.return_value = {
            'start_at':
                self.start.isoformat(),

            'end_at':
                self.end.isoformat(),

            'likes': 0,
            'unlikes': 0,
            'net_likes': 0,
            'unique_likers': 0,
            'unique_viewers': 0,

            'engagement_rate_percent':
                0.0,

            'current_likes': 0,
        }

        self.client.force_authenticate(
            empty
        )

        response = self.client.get(
            self.list_url,
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

        self.assertEqual(
            response.data[
                'engagement'
            ][
                'likes'
            ],
            0,
        )

        video_mock.assert_not_called()

        engagement_mock.assert_called_once()

        self.assertEqual(
            engagement_mock
            .call_args
            .kwargs[
                'allowed_content_ids'
            ],
            [],
        )

    @patch(
        'apps.analytics.services.'
        'producer_engagement_analytics'
    )
    @patch(
        'apps.analytics.services.'
        'producer_content_video_analytics'
    )
    def test_override_rejected_before_both_engines(
        self,
        video_mock,
        engagement_mock,
    ):
        self.client.force_authenticate(
            self.producer
        )

        params = self._window()

        params[
            'producer'
        ] = str(
            self.other_producer.id
        )

        response = self.client.get(
            self.list_url,
            params,
        )

        self.assertEqual(
            response.status_code,
            400,
        )

        video_mock.assert_not_called()
        engagement_mock.assert_not_called()
