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


class ProducerEngagementAPITests(
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
                'producer-d8-b6@example.com'
            )
        )

        self.other_producer = (
            self._active_producer(
                'producer-d8-b6-other@example.com'
            )
        )

        self.own_content = (
            Content.objects.create(
                title='Owned B6 Content',
                type='movie',
                producer=self.producer,
            )
        )

        self.foreign_content = (
            Content.objects.create(
                title='Foreign B6 Content',
                type='series',
                producer=self.other_producer,
            )
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

        account = (
            ProducerAccount.objects.create(
                user=user,
                company_name=
                    f'Company {email}',
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

    def _engagement_result(self):
        return {
            'start_at':
                self.start.isoformat(),

            'end_at':
                self.end.isoformat(),

            'likes':
                12,

            'unlikes':
                2,

            'net_likes':
                10,

            'unique_likers':
                9,

            'unique_viewers':
                30,

            'engagement_rate_percent':
                30.0,

            'current_likes':
                8,
        }

    @patch(
        'apps.analytics.services.'
        'producer_content_video_analytics'
    )
    @patch(
        'apps.analytics.services.'
        'producer_engagement_analytics'
    )
    def test_overview_exposes_engagement_for_own_scope(
        self,
        engagement_mock,
        video_mock,
    ):
        engagement_mock.return_value = (
            self._engagement_result()
        )

        video_mock.return_value = []

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

        engagement_mock.assert_called_once()

        kwargs = (
            engagement_mock
            .call_args
            .kwargs
        )

        self.assertEqual(
            {
                str(value)
                for value
                in kwargs[
                    'allowed_content_ids'
                ]
            },
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
            {
                str(value)
                for value
                in kwargs[
                    'allowed_content_ids'
                ]
            },
        )

        self.assertEqual(
            response.data[
                'engagement'
            ][
                'net_likes'
            ],
            10,
        )

        self.assertEqual(
            response.data[
                'engagement'
            ][
                'current_likes'
            ],
            8,
        )

    @patch(
        'apps.analytics.services.'
        'producer_content_video_analytics'
    )
    @patch(
        'apps.analytics.services.'
        'producer_engagement_analytics'
    )
    def test_detail_exposes_engagement_for_owned_content_only(
        self,
        engagement_mock,
        video_mock,
    ):
        engagement_mock.return_value = (
            self._engagement_result()
        )

        video_mock.return_value = []

        self.client.force_authenticate(
            self.producer
        )

        response = self.client.get(
            self._detail_url(
                self.own_content.id
            ),
            self._window(),
        )

        self.assertEqual(
            response.status_code,
            200,
        )

        engagement_mock.assert_called_once()

        kwargs = (
            engagement_mock
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
            response.data[
                'engagement'
            ][
                'likes'
            ],
            12,
        )

        self.assertEqual(
            response.data[
                'engagement'
            ][
                'engagement_rate_percent'
            ],
            30.0,
        )

    @patch(
        'apps.analytics.services.'
        'producer_content_video_analytics'
    )
    @patch(
        'apps.analytics.services.'
        'producer_engagement_analytics'
    )
    def test_foreign_detail_is_404_before_any_analytics(
        self,
        engagement_mock,
        video_mock,
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
        'producer_content_video_analytics'
    )
    @patch(
        'apps.analytics.services.'
        'producer_engagement_analytics'
    )
    def test_unknown_detail_is_404_before_any_analytics(
        self,
        engagement_mock,
        video_mock,
    ):
        import uuid

        self.client.force_authenticate(
            self.producer
        )

        response = self.client.get(
            self._detail_url(
                uuid.uuid4()
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
        'producer_content_video_analytics'
    )
    @patch(
        'apps.analytics.services.'
        'producer_engagement_analytics'
    )
    def test_producer_override_rejected_before_any_analytics(
        self,
        engagement_mock,
        video_mock,
    ):
        self.client.force_authenticate(
            self.producer
        )

        params = self._window()
        params[
            'producer_id'
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

    @patch(
        'apps.analytics.services.'
        'producer_content_video_analytics'
    )
    @patch(
        'apps.analytics.services.'
        'producer_engagement_analytics'
    )
    def test_staff_remains_self_scoped(
        self,
        engagement_mock,
        video_mock,
    ):
        staff = User.objects.create_user(
            email='staff-d8-b6@example.com',
            password='StrongPass123!',
            is_staff=True,
        )

        staff_content = (
            Content.objects.create(
                title='Staff B6 Content',
                type='movie',
                producer=staff,
            )
        )

        engagement_mock.return_value = (
            self._engagement_result()
        )

        video_mock.return_value = []

        self.client.force_authenticate(
            staff
        )

        response = self.client.get(
            self.list_url,
            self._window(),
        )

        self.assertEqual(
            response.status_code,
            200,
        )

        kwargs = (
            engagement_mock
            .call_args
            .kwargs
        )

        self.assertEqual(
            {
                str(value)
                for value
                in kwargs[
                    'allowed_content_ids'
                ]
            },
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
            {
                str(value)
                for value
                in kwargs[
                    'allowed_content_ids'
                ]
            },
        )

    @patch(
        'apps.analytics.services.'
        'producer_content_video_analytics'
    )
    @patch(
        'apps.analytics.services.'
        'producer_engagement_analytics'
    )
    def test_empty_scope_returns_zero_engagement_and_no_video_query(
        self,
        engagement_mock,
        video_mock,
    ):
        empty_producer = (
            self._active_producer(
                'empty-d8-b6@example.com'
            )
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
            empty_producer
        )

        response = self.client.get(
            self.list_url,
            self._window(),
        )

        self.assertEqual(
            response.status_code,
            200,
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

        self.assertEqual(
            response.data[
                'engagement'
            ][
                'likes'
            ],
            0,
        )

        self.assertEqual(
            response.data[
                'engagement'
            ][
                'current_likes'
            ],
            0,
        )
