from datetime import (
    datetime,
    timezone,
)
from unittest.mock import Mock

from django.test import SimpleTestCase

from apps.analytics.services import (
    APP_SESSION_ANALYTICS_DIMENSIONS,
    app_session_dimension_analytics,
)


class AppSessionDimensionAnalyticsTests(
    SimpleTestCase
):
    def setUp(self):
        self.start_at = datetime(
            2026,
            9,
            10,
            tzinfo=timezone.utc,
        )

        self.end_at = datetime(
            2026,
            9,
            11,
            tzinfo=timezone.utc,
        )

    def _client(self, rows=None):
        result = Mock()
        result.result_rows = (
            rows or []
        )

        client = Mock()
        client.query.return_value = result

        return client

    def test_supported_dimensions(self):
        self.assertEqual(
            APP_SESSION_ANALYTICS_DIMENSIONS,
            (
                'platform',
                'device_type',
                'profile_type',
                'country_code',
            ),
        )

    def test_returns_dimension_kpis(self):
        client = self._client(
            [
                (
                    'android',
                    5,
                    3,
                    4,
                    1,
                    90.0,
                    5 / 3,
                ),
            ]
        )

        rows = (
            app_session_dimension_analytics(
                start_at=self.start_at,
                end_at=self.end_at,
                dimension='platform',
                client=client,
            )
        )

        self.assertEqual(
            rows[0]['dimension_value'],
            'android',
        )

        self.assertEqual(
            rows[0]['sessions'],
            5,
        )

        self.assertEqual(
            rows[0]['unique_profiles'],
            3,
        )

        self.assertEqual(
            rows[0]['closed_sessions'],
            4,
        )

        self.assertEqual(
            rows[0]['open_sessions'],
            1,
        )

        self.assertEqual(
            rows[0][
                'avg_session_duration_seconds'
            ],
            90.0,
        )

    def test_empty_rows_are_empty(self):
        client = self._client()

        rows = (
            app_session_dimension_analytics(
                start_at=self.start_at,
                end_at=self.end_at,
                dimension='platform',
                client=client,
            )
        )

        self.assertEqual(
            rows,
            [],
        )

    def test_invalid_dimension_rejected(self):
        with self.assertRaises(
            ValueError
        ):
            app_session_dimension_analytics(
                start_at=self.start_at,
                end_at=self.end_at,
                dimension='producer',
                client=self._client(),
            )

    def test_invalid_window_rejected(self):
        with self.assertRaises(
            ValueError
        ):
            app_session_dimension_analytics(
                start_at=self.end_at,
                end_at=self.start_at,
                dimension='platform',
                client=self._client(),
            )

    def test_real_session_filter_contract(self):
        client = self._client()

        app_session_dimension_analytics(
            start_at=self.start_at,
            end_at=self.end_at,
            dimension='platform',
            client=client,
        )

        sql = (
            client.query
            .call_args
            .args[0]
        )

        self.assertIn(
            "event_name IN (",
            sql,
        )

        self.assertIn(
            "'app_session_start'",
            sql,
        )

        self.assertIn(
            "'app_session_end'",
            sql,
        )

        self.assertIn(
            'is_internal = 0',
            sql,
        )

        self.assertIn(
            'is_test = 0',
            sql,
        )

        self.assertIn(
            'profile_id IS NOT NULL',
            sql,
        )

        self.assertIn(
            'session_id IS NOT NULL',
            sql,
        )

    def test_dimension_comes_only_from_start(
        self,
    ):
        client = self._client()

        app_session_dimension_analytics(
            start_at=self.start_at,
            end_at=self.end_at,
            dimension='device_type',
            client=client,
        )

        sql = (
            client.query
            .call_args
            .args[0]
        )

        self.assertIn(
            'argMinIf(',
            sql,
        )

        self.assertIn(
            'device_type',
            sql,
        )

        self.assertIn(
            "event_name =\n"
            "                        "
            "'app_session_start'",
            sql,
        )

    def test_duplicate_start_tie_breaks_by_event_id(
        self,
    ):
        client = self._client()

        app_session_dimension_analytics(
            start_at=self.start_at,
            end_at=self.end_at,
            dimension='platform',
            client=client,
        )

        sql = (
            client.query
            .call_args
            .args[0]
        )

        self.assertIn(
            'tuple(',
            sql,
        )

        self.assertIn(
            'event_id',
            sql,
        )

    def test_duration_does_not_use_properties(
        self,
    ):
        client = self._client()

        app_session_dimension_analytics(
            start_at=self.start_at,
            end_at=self.end_at,
            dimension='country_code',
            client=client,
        )

        sql = (
            client.query
            .call_args
            .args[0]
        )

        self.assertIn(
            "dateDiff(",
            sql,
        )

        self.assertNotIn(
            'properties',
            sql,
        )

    def test_query_is_parameterized(self):
        client = self._client()

        app_session_dimension_analytics(
            start_at=self.start_at,
            end_at=self.end_at,
            dimension='profile_type',
            client=client,
        )

        call = client.query.call_args

        self.assertIn(
            '{start_at:DateTime64(3)}',
            call.args[0],
        )

        self.assertIn(
            '{end_at:DateTime64(3)}',
            call.args[0],
        )

        self.assertEqual(
            call.kwargs['parameters'][
                'start_at'
            ],
            self.start_at,
        )
