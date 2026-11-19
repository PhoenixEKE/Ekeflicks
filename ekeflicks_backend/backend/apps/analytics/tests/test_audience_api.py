from datetime import (
    datetime,
    timezone,
)
from unittest.mock import patch

from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from core.models import User


class AudienceAnalyticsApiTests(
    APITestCase
):
    def setUp(self):
        self.admin = User.objects.create_user(
            email=(
                'audience-admin@example.com'
            ),
            password='StrongPass123',
            is_staff=True,
        )

        self.user = User.objects.create_user(
            email=(
                'audience-user@example.com'
            ),
            password='StrongPass123',
        )

        self.start_at = (
            '2026-09-01T00:00:00Z'
        )

        self.end_at = (
            '2026-09-10T12:00:00Z'
        )

    def _auth_admin(self):
        self.client.force_authenticate(
            user=self.admin
        )

    def test_routes_reverse(
        self,
    ):
        self.assertEqual(
            reverse(
                'audience-list'
            ),
            '/api/v1/audience/',
        )

        self.assertEqual(
            reverse(
                'audience-snapshot'
            ),
            (
                '/api/v1/'
                'audience/snapshot/'
            ),
        )

        self.assertEqual(
            reverse(
                'audience-dimensions'
            ),
            (
                '/api/v1/'
                'audience/dimensions/'
            ),
        )

        self.assertEqual(
            reverse(
                'audience-retention'
            ),
            (
                '/api/v1/'
                'audience/retention/'
            ),
        )

        self.assertEqual(
            reverse(
                'audience-peak-hours'
            ),
            (
                '/api/v1/'
                'audience/peak-hours/'
            ),
        )

        self.assertEqual(
            reverse(
                'audience-peak-hours-by-country'
            ),
            (
                '/api/v1/'
                'audience/'
                'peak-hours-by-country/'
            ),
        )

    def test_anonymous_is_rejected(
        self,
    ):
        response = self.client.get(
            reverse(
                'audience-list'
            )
        )

        self.assertIn(
            response.status_code,
            (
                status.HTTP_401_UNAUTHORIZED,
                status.HTTP_403_FORBIDDEN,
            ),
        )

    def test_non_staff_is_forbidden(
        self,
    ):
        self.client.force_authenticate(
            user=self.user
        )

        response = self.client.get(
            reverse(
                'audience-list'
            )
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_403_FORBIDDEN,
        )

    def test_admin_can_read_contract(
        self,
    ):
        self._auth_admin()

        response = self.client.get(
            reverse(
                'audience-list'
            )
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_200_OK,
        )

        self.assertEqual(
            response.data['scope'],
            'global',
        )

        self.assertEqual(
            response.data[
                'permissions'
            ],
            'admin',
        )

        self.assertTrue(
            response.data[
                'metrics'
            ][
                'retention'
            ][
                'maturity_aware'
            ]
        )

        self.assertTrue(
            response.data[
                'metrics'
            ][
                'peak_hours'
            ][
                'dst_safe'
            ]
        )

    @patch(
        'apps.analytics.views.'
        'audience_snapshot'
    )
    def test_snapshot_endpoint(
        self,
        snapshot,
    ):
        snapshot.return_value = {
            'as_of': (
                '2026-09-10T12:00:00+00:00'
            ),
            'timezone': 'UTC',
            'dau': 10,
            'wau': 50,
            'mau': 100,
            'stickiness_percent': 10.0,
            'windows': {},
        }

        self._auth_admin()

        response = self.client.get(
            reverse(
                'audience-snapshot'
            ),
            {
                'as_of': (
                    '2026-09-10T12:00:00Z'
                )
            },
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_200_OK,
        )

        self.assertEqual(
            response.data['dau'],
            10,
        )

        snapshot.assert_called_once()

        called_as_of = (
            snapshot
            .call_args
            .kwargs[
                'as_of'
            ]
        )

        self.assertEqual(
            called_as_of,
            datetime(
                2026,
                9,
                10,
                12,
                0,
                tzinfo=timezone.utc,
            ),
        )

    @patch(
        'apps.analytics.views.'
        'audience_by_dimension'
    )
    def test_dimensions_endpoint(
        self,
        by_dimension,
    ):
        by_dimension.return_value = [
            {
                'country_code': 'CI',
                'active_profiles': 12,
            }
        ]

        self._auth_admin()

        response = self.client.get(
            reverse(
                'audience-dimensions'
            ),
            {
                'start_at': (
                    self.start_at
                ),
                'end_at': (
                    self.end_at
                ),
                'dimension': (
                    'country_code'
                ),
            },
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_200_OK,
        )

        self.assertEqual(
            response.data[
                'dimension'
            ],
            'country_code',
        )

        self.assertEqual(
            response.data[
                'results'
            ][0][
                'country_code'
            ],
            'CI',
        )

        self.assertEqual(
            by_dimension
            .call_args
            .kwargs[
                'dimension'
            ],
            'country_code',
        )

    def test_dimensions_reject_unknown_dimension(
        self,
    ):
        self._auth_admin()

        response = self.client.get(
            reverse(
                'audience-dimensions'
            ),
            {
                'start_at': (
                    self.start_at
                ),
                'end_at': (
                    self.end_at
                ),
                'dimension': 'email',
            },
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_400_BAD_REQUEST,
        )

    def test_range_rejects_end_before_start(
        self,
    ):
        self._auth_admin()

        response = self.client.get(
            reverse(
                'audience-dimensions'
            ),
            {
                'start_at': (
                    self.end_at
                ),
                'end_at': (
                    self.start_at
                ),
                'dimension': (
                    'country_code'
                ),
            },
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_400_BAD_REQUEST,
        )

    @patch(
        'apps.analytics.views.'
        'audience_retention_summary'
    )
    @patch(
        'apps.analytics.views.'
        'audience_retention'
    )
    def test_retention_endpoint(
        self,
        retention,
        summary,
    ):
        retention.return_value = [
            {
                'cohort_date': (
                    '2026-08-01'
                ),
                'cohort_size': 10,
                'd30': 2,
                'd30_percent': 20.0,
                'd30_mature': True,
            }
        ]

        summary.return_value = {
            'cohort_size': 10,
            'd30': 2,
            'd30_eligible_profiles': 10,
            'd30_mature_cohorts': 1,
            'd30_percent': 20.0,
        }

        self._auth_admin()

        response = self.client.get(
            reverse(
                'audience-retention'
            ),
            {
                'cohort_start': (
                    '2026-08-01T00:00:00Z'
                ),
                'cohort_end': (
                    '2026-08-02T00:00:00Z'
                ),
                'as_of': (
                    '2026-09-10T12:00:00Z'
                ),
            },
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_200_OK,
        )

        self.assertEqual(
            response.data[
                'summary'
            ][
                'd30_percent'
            ],
            20.0,
        )

        self.assertTrue(
            response.data[
                'rows'
            ][0][
                'd30_mature'
            ]
        )

        retention.assert_called_once()

        summary.assert_called_once_with(
            retention.return_value
        )

    @patch(
        'apps.analytics.views.'
        'audience_peak_hours'
    )
    def test_peak_hours_endpoint(
        self,
        peak_hours,
    ):
        peak_hours.return_value = [
            {
                'hour': 20,
                'active_profiles': 25,
                'events': 100,
            }
        ]

        self._auth_admin()

        response = self.client.get(
            reverse(
                'audience-peak-hours'
            ),
            {
                'start_at': (
                    self.start_at
                ),
                'end_at': (
                    self.end_at
                ),
                'country_code': 'ci',
                'limit': 5,
            },
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_200_OK,
        )

        self.assertEqual(
            response.data[
                'country_code'
            ],
            'CI',
        )

        self.assertEqual(
            response.data[
                'results'
            ][0][
                'hour'
            ],
            20,
        )

        self.assertEqual(
            peak_hours
            .call_args
            .kwargs[
                'country_code'
            ],
            'CI',
        )

    @patch(
        'apps.analytics.views.'
        'audience_peak_hours_by_country'
    )
    def test_peak_hours_by_country_endpoint(
        self,
        peak_hours,
    ):
        peak_hours.return_value = [
            {
                'country_code': 'CI',
                'peak_hours': [
                    {
                        'hour': 18,
                        'active_profiles': 10,
                        'events': 30,
                    }
                ],
            }
        ]

        self._auth_admin()

        response = self.client.get(
            reverse(
                'audience-peak-hours-by-country'
            ),
            {
                'start_at': (
                    self.start_at
                ),
                'end_at': (
                    self.end_at
                ),
                'limit_per_country': 2,
            },
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_200_OK,
        )

        self.assertEqual(
            response.data[
                'limit_per_country'
            ],
            2,
        )

        self.assertEqual(
            response.data[
                'results'
            ][0][
                'country_code'
            ],
            'CI',
        )

    def test_peak_limit_is_bounded(
        self,
    ):
        self._auth_admin()

        response = self.client.get(
            reverse(
                'audience-peak-hours'
            ),
            {
                'start_at': (
                    self.start_at
                ),
                'end_at': (
                    self.end_at
                ),
                'limit': 25,
            },
        )

        self.assertEqual(
            response.status_code,
            status.HTTP_400_BAD_REQUEST,
        )
