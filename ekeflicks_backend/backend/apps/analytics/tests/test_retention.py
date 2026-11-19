from datetime import (
    date,
    datetime,
    timezone,
)
from unittest.mock import Mock

from django.test import SimpleTestCase

from apps.analytics.services import (
    AUDIENCE_RETENTION_DAYS,
    audience_retention,
    audience_retention_summary,
)


class AudienceRetentionTests(
    SimpleTestCase
):
    def _result(
        self,
        rows,
    ):
        result = Mock()
        result.result_rows = rows
        return result

    def test_retention_days_contract(
        self,
    ):
        self.assertEqual(
            AUDIENCE_RETENTION_DAYS,
            (
                1,
                3,
                7,
                14,
                30,
            ),
        )

    def test_mature_cohort_returns_exact_day_metrics(
        self,
    ):
        client = Mock()

        client.query.return_value = (
            self._result(
                [
                    (
                        date(
                            2026,
                            8,
                            1,
                        ),
                        10,
                        6,
                        5,
                        4,
                        3,
                        2,
                    ),
                ]
            )
        )

        rows = audience_retention(
            cohort_start=datetime(
                2026,
                8,
                1,
                tzinfo=timezone.utc,
            ),
            cohort_end=datetime(
                2026,
                8,
                2,
                tzinfo=timezone.utc,
            ),
            as_of=datetime(
                2026,
                9,
                10,
                12,
                0,
                tzinfo=timezone.utc,
            ),
            client=client,
        )

        row = rows[0]

        self.assertEqual(
            row['cohort_size'],
            10,
        )

        self.assertEqual(
            row['d1'],
            6,
        )

        self.assertEqual(
            row['d1_percent'],
            60.0,
        )

        self.assertTrue(
            row['d1_mature']
        )

        self.assertEqual(
            row['d30'],
            2,
        )

        self.assertEqual(
            row['d30_percent'],
            20.0,
        )

        self.assertTrue(
            row['d30_mature']
        )

    def test_recent_cohort_marks_future_retention_immature(
        self,
    ):
        client = Mock()

        client.query.return_value = (
            self._result(
                [
                    (
                        date(
                            2026,
                            9,
                            9,
                        ),
                        10,
                        4,
                        3,
                        2,
                        1,
                        0,
                    ),
                ]
            )
        )

        rows = audience_retention(
            cohort_start=datetime(
                2026,
                9,
                9,
                tzinfo=timezone.utc,
            ),
            cohort_end=datetime(
                2026,
                9,
                10,
                tzinfo=timezone.utc,
            ),
            as_of=datetime(
                2026,
                9,
                10,
                15,
                0,
                tzinfo=timezone.utc,
            ),
            client=client,
        )

        row = rows[0]

        for day in (
            AUDIENCE_RETENTION_DAYS
        ):
            self.assertFalse(
                row[
                    f'd{day}_mature'
                ]
            )

            self.assertIsNone(
                row[
                    f'd{day}'
                ]
            )

            self.assertIsNone(
                row[
                    f'd{day}_percent'
                ]
            )

    def test_target_day_becomes_mature_after_day_closes(
        self,
    ):
        client = Mock()

        client.query.return_value = (
            self._result(
                [
                    (
                        date(
                            2026,
                            9,
                            9,
                        ),
                        10,
                        4,
                        0,
                        0,
                        0,
                        0,
                    ),
                ]
            )
        )

        rows = audience_retention(
            cohort_start=datetime(
                2026,
                9,
                9,
                tzinfo=timezone.utc,
            ),
            cohort_end=datetime(
                2026,
                9,
                10,
                tzinfo=timezone.utc,
            ),
            as_of=datetime(
                2026,
                9,
                11,
                0,
                0,
                tzinfo=timezone.utc,
            ),
            client=client,
        )

        row = rows[0]

        self.assertTrue(
            row['d1_mature']
        )

        self.assertEqual(
            row['d1'],
            4,
        )

        self.assertEqual(
            row['d1_percent'],
            40.0,
        )

        self.assertFalse(
            row['d3_mature']
        )

        self.assertIsNone(
            row['d3']
        )

    def test_query_uses_first_real_activity(
        self,
    ):
        client = Mock()

        client.query.return_value = (
            self._result([])
        )

        as_of = datetime(
            2026,
            9,
            10,
            12,
            0,
            tzinfo=timezone.utc,
        )

        audience_retention(
            cohort_start=datetime(
                2026,
                9,
                1,
                tzinfo=timezone.utc,
            ),
            cohort_end=datetime(
                2026,
                9,
                10,
                tzinfo=timezone.utc,
            ),
            as_of=as_of,
            client=client,
        )

        query = (
            client
            .query
            .call_args
            .args[0]
        )

        parameters = (
            client
            .query
            .call_args
            .kwargs[
                'parameters'
            ]
        )

        self.assertIn(
            'min(',
            query,
        )

        self.assertIn(
            'toDate(occurred_at)',
            query,
        )

        self.assertIn(
            'AS cohort_date',
            query,
        )

        self.assertIn(
            'profile_id IS NOT NULL',
            query,
        )

        self.assertIn(
            'is_internal = 0',
            query,
        )

        self.assertIn(
            'is_test = 0',
            query,
        )

        self.assertGreaterEqual(
            query.count(
                '{as_of:DateTime64(3)}'
            ),
            2,
        )

        self.assertEqual(
            parameters[
                'as_of'
            ],
            as_of,
        )

    def test_query_uses_exact_retention_days(
        self,
    ):
        client = Mock()

        client.query.return_value = (
            self._result([])
        )

        audience_retention(
            cohort_start=datetime(
                2026,
                8,
                1,
                tzinfo=timezone.utc,
            ),
            cohort_end=datetime(
                2026,
                8,
                2,
                tzinfo=timezone.utc,
            ),
            as_of=datetime(
                2026,
                9,
                10,
                tzinfo=timezone.utc,
            ),
            client=client,
        )

        query = (
            client
            .query
            .call_args
            .args[0]
        )

        for day in (
            1,
            3,
            7,
            14,
            30,
        ):
            self.assertIn(
                (
                    'addDays('
                ),
                query,
            )

            self.assertIn(
                str(day),
                query,
            )

    def test_invalid_cohort_range_is_rejected(
        self,
    ):
        with self.assertRaises(
            ValueError
        ):
            audience_retention(
                cohort_start=datetime(
                    2026,
                    9,
                    10,
                    tzinfo=timezone.utc,
                ),
                cohort_end=datetime(
                    2026,
                    9,
                    10,
                    tzinfo=timezone.utc,
                ),
                as_of=datetime(
                    2026,
                    9,
                    11,
                    tzinfo=timezone.utc,
                ),
                client=Mock(),
            )

    def test_summary_is_weighted_over_mature_cohorts_only(
        self,
    ):
        rows = [
            {
                'cohort_size': 100,

                'd1': 50,
                'd1_mature': True,

                'd3': 30,
                'd3_mature': True,

                'd7': 20,
                'd7_mature': True,

                'd14': 10,
                'd14_mature': True,

                'd30': 5,
                'd30_mature': True,
            },
            {
                'cohort_size': 20,

                'd1': 20,
                'd1_mature': True,

                'd3': 10,
                'd3_mature': True,

                'd7': None,
                'd7_mature': False,

                'd14': None,
                'd14_mature': False,

                'd30': None,
                'd30_mature': False,
            },
        ]

        result = (
            audience_retention_summary(
                rows
            )
        )

        self.assertEqual(
            result[
                'cohort_size'
            ],
            120,
        )

        self.assertEqual(
            result['d1'],
            70,
        )

        self.assertEqual(
            result[
                'd1_eligible_profiles'
            ],
            120,
        )

        self.assertEqual(
            result[
                'd1_mature_cohorts'
            ],
            2,
        )

        self.assertEqual(
            result[
                'd1_percent'
            ],
            58.33,
        )

        self.assertEqual(
            result['d7'],
            20,
        )

        self.assertEqual(
            result[
                'd7_eligible_profiles'
            ],
            100,
        )

        self.assertEqual(
            result[
                'd7_mature_cohorts'
            ],
            1,
        )

        self.assertEqual(
            result[
                'd7_percent'
            ],
            20.0,
        )

        self.assertEqual(
            result['d30'],
            5,
        )

        self.assertEqual(
            result[
                'd30_eligible_profiles'
            ],
            100,
        )

        self.assertEqual(
            result[
                'd30_percent'
            ],
            5.0,
        )

    def test_summary_with_no_mature_cohort_is_not_zero_percent(
        self,
    ):
        rows = [
            {
                'cohort_size': 10,
                'd1': None,
                'd1_mature': False,
                'd3': None,
                'd3_mature': False,
                'd7': None,
                'd7_mature': False,
                'd14': None,
                'd14_mature': False,
                'd30': None,
                'd30_mature': False,
            },
        ]

        result = (
            audience_retention_summary(
                rows
            )
        )

        for day in (
            AUDIENCE_RETENTION_DAYS
        ):
            self.assertEqual(
                result[
                    f'd{day}'
                ],
                0,
            )

            self.assertEqual(
                result[
                    f'd{day}_eligible_profiles'
                ],
                0,
            )

            self.assertEqual(
                result[
                    f'd{day}_mature_cohorts'
                ],
                0,
            )

            self.assertIsNone(
                result[
                    f'd{day}_percent'
                ]
            )

    def test_empty_retention_summary(
        self,
    ):
        result = (
            audience_retention_summary(
                []
            )
        )

        self.assertEqual(
            result[
                'cohort_size'
            ],
            0,
        )

        for day in (
            AUDIENCE_RETENTION_DAYS
        ):
            self.assertEqual(
                result[
                    f'd{day}'
                ],
                0,
            )

            self.assertEqual(
                result[
                    f'd{day}_eligible_profiles'
                ],
                0,
            )

            self.assertEqual(
                result[
                    f'd{day}_mature_cohorts'
                ],
                0,
            )

            self.assertIsNone(
                result[
                    f'd{day}_percent'
                ]
            )
