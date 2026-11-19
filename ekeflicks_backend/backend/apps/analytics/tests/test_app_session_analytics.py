from datetime import datetime, timezone
from unittest.mock import MagicMock, patch

from django.test import SimpleTestCase

from apps.analytics.services import app_session_analytics


class AppSessionAnalyticsTests(SimpleTestCase):
    def _result(self, row):
        result = MagicMock()
        result.result_rows = [row]
        return result

    @patch("apps.analytics.services.clickhouse_client")
    def test_returns_expected_kpis(self, client_factory):
        client = MagicMock()
        client.query.return_value = self._result(
            (5, 3, 4, 1, 120.5, 5 / 3)
        )
        client_factory.return_value = client

        data = app_session_analytics()

        self.assertEqual(data["sessions"], 5)
        self.assertEqual(data["unique_profiles"], 3)
        self.assertEqual(data["closed_sessions"], 4)
        self.assertEqual(data["open_sessions"], 1)
        self.assertEqual(
            data["avg_session_duration_seconds"],
            120.5,
        )
        self.assertAlmostEqual(
            data["sessions_per_profile"],
            5 / 3,
        )

    @patch("apps.analytics.services.clickhouse_client")
    def test_empty_result_is_zeroed(self, client_factory):
        result = MagicMock()
        result.result_rows = []
        client = MagicMock()
        client.query.return_value = result
        client_factory.return_value = client

        data = app_session_analytics()

        self.assertEqual(
            data,
            {
                "sessions": 0,
                "unique_profiles": 0,
                "closed_sessions": 0,
                "open_sessions": 0,
                "avg_session_duration_seconds": 0.0,
                "sessions_per_profile": 0.0,
            },
        )

    @patch("apps.analytics.services.clickhouse_client")
    def test_real_events_only_contract(self, client_factory):
        client = MagicMock()
        client.query.return_value = self._result(
            (0, 0, 0, 0, 0.0, 0.0)
        )
        client_factory.return_value = client

        app_session_analytics()

        query = client.query.call_args.args[0]

        self.assertIn("is_internal = 0", query)
        self.assertIn("is_test = 0", query)
        self.assertIn("profile_id IS NOT NULL", query)
        self.assertIn("session_id IS NOT NULL", query)

    @patch("apps.analytics.services.clickhouse_client")
    def test_only_app_session_events_participate(
        self,
        client_factory,
    ):
        client = MagicMock()
        client.query.return_value = self._result(
            (0, 0, 0, 0, 0.0, 0.0)
        )
        client_factory.return_value = client

        app_session_analytics()

        query = client.query.call_args.args[0]

        self.assertIn("app_session_start", query)
        self.assertIn("app_session_end", query)

    @patch("apps.analytics.services.clickhouse_client")
    def test_session_identity_is_session_id(
        self,
        client_factory,
    ):
        client = MagicMock()
        client.query.return_value = self._result(
            (0, 0, 0, 0, 0.0, 0.0)
        )
        client_factory.return_value = client

        app_session_analytics()

        query = client.query.call_args.args[0]

        self.assertIn("GROUP BY session_id", query)
        self.assertNotIn("GROUP BY viewing_session_id", query)

    @patch("apps.analytics.services.clickhouse_client")
    def test_first_start_and_last_end_contract(
        self,
        client_factory,
    ):
        client = MagicMock()
        client.query.return_value = self._result(
            (0, 0, 0, 0, 0.0, 0.0)
        )
        client_factory.return_value = client

        app_session_analytics()

        query = client.query.call_args.args[0]

        self.assertIn("minIf(", query)
        self.assertIn("maxIf(", query)
        self.assertIn(
            "event_name = 'app_session_start'",
            query,
        )
        self.assertIn(
            "event_name = 'app_session_end'",
            query,
        )

    @patch("apps.analytics.services.clickhouse_client")
    def test_duration_is_derived_from_occurred_at(
        self,
        client_factory,
    ):
        client = MagicMock()
        client.query.return_value = self._result(
            (0, 0, 0, 0, 0.0, 0.0)
        )
        client_factory.return_value = client

        app_session_analytics()

        query = client.query.call_args.args[0]

        self.assertIn("dateDiff(", query)
        self.assertIn("started_at", query)
        self.assertIn("ended_at", query)

        # Client supplied properties.duration_seconds must not
        # participate in KPI calculation.
        self.assertNotIn("properties", query)

    @patch("apps.analytics.services.clickhouse_client")
    def test_open_sessions_excluded_from_average(
        self,
        client_factory,
    ):
        client = MagicMock()
        client.query.return_value = self._result(
            (0, 0, 0, 0, 0.0, 0.0)
        )
        client_factory.return_value = client

        app_session_analytics()

        query = client.query.call_args.args[0]

        self.assertIn("avgIf(", query)
        self.assertIn("is_closed", query)

    @patch("apps.analytics.services.clickhouse_client")
    def test_profile_aggregate_alias_does_not_shadow_source_column(
        self,
        client_factory,
    ):
        client = MagicMock()
        client.query.return_value = self._result(
            (0, 0, 0, 0, 0.0, 0.0)
        )
        client_factory.return_value = client

        app_session_analytics()

        query = client.query.call_args.args[0]

        self.assertIn(
            "AS session_profile_id",
            query,
        )

        self.assertIn(
            "session_profile_id AS profile_id",
            query,
        )

        self.assertNotIn(
            "argMin(profile_id, occurred_at) AS profile_id",
            query,
        )

    @patch("apps.analytics.services.clickhouse_client")
    def test_invalid_time_window_is_rejected(
        self,
        client_factory,
    ):
        point = datetime(
            2026,
            9,
            11,
            tzinfo=timezone.utc,
        )

        with self.assertRaisesRegex(
            ValueError,
            "start_at must be before end_at",
        ):
            app_session_analytics(
                start_at=point,
                end_at=point,
            )

        client_factory.assert_not_called()


    @patch("apps.analytics.services.clickhouse_client")
    def test_time_filters_are_parameterized(
        self,
        client_factory,
    ):
        client = MagicMock()
        client.query.return_value = self._result(
            (0, 0, 0, 0, 0.0, 0.0)
        )
        client_factory.return_value = client

        start = datetime(
            2026,
            9,
            1,
            tzinfo=timezone.utc,
        )
        end = datetime(
            2026,
            9,
            11,
            tzinfo=timezone.utc,
        )

        app_session_analytics(
            start_at=start,
            end_at=end,
        )

        call = client.query.call_args
        query = call.args[0]
        parameters = call.kwargs["parameters"]

        self.assertIn(
            "occurred_at >= {start_at:",
            query,
        )
        self.assertIn(
            "occurred_at < {end_at:",
            query,
        )

        self.assertEqual(parameters["start_at"], start)
        self.assertEqual(parameters["end_at"], end)
