from datetime import datetime, timezone
from types import SimpleNamespace
from unittest.mock import Mock

from django.test import SimpleTestCase

from apps.analytics.services import (
    LIKE_ENGAGEMENT_DIMENSIONS,
    like_engagement_dimension_analytics,
)


class LikeEngagementDimensionAnalyticsTests(
    SimpleTestCase
):
    def setUp(self):
        self.start_at = datetime(
            2026,
            9,
            1,
            tzinfo=timezone.utc,
        )

        self.end_at = datetime(
            2026,
            9,
            2,
            tzinfo=timezone.utc,
        )

    def client_with_rows(self, rows):
        client = Mock()

        client.query.return_value = (
            SimpleNamespace(
                result_rows=rows,
            )
        )

        return client

    def test_supported_dimensions_are_locked(self):
        self.assertEqual(
            LIKE_ENGAGEMENT_DIMENSIONS,
            (
                'content',
                'producer',
                'content_type',
                'genre',
                'country_code',
                'profile_type',
            ),
        )

        self.assertNotIn(
            'platform',
            LIKE_ENGAGEMENT_DIMENSIONS,
        )

        self.assertNotIn(
            'device_type',
            LIKE_ENGAGEMENT_DIMENSIONS,
        )

    def test_result_contract(self):
        client = self.client_with_rows(
            [
                (
                    'movie',
                    10,
                    3,
                    6,
                    20,
                ),
            ]
        )

        rows = (
            like_engagement_dimension_analytics(
                self.start_at,
                self.end_at,
                dimension='content_type',
                client=client,
            )
        )

        self.assertEqual(
            rows,
            [
                {
                    'dimension':
                        'content_type',

                    'dimension_value':
                        'movie',

                    'likes':
                        10,

                    'unlikes':
                        3,

                    'net_likes':
                        7,

                    'unique_likers':
                        6,

                    'unique_viewers':
                        20,

                    'engagement_rate_percent':
                        30.0,
                },
            ],
        )

    def test_zero_viewers_has_zero_rate(self):
        client = self.client_with_rows(
            [
                (
                    'CI',
                    4,
                    1,
                    3,
                    0,
                ),
            ]
        )

        row = (
            like_engagement_dimension_analytics(
                self.start_at,
                self.end_at,
                dimension='country_code',
                client=client,
            )[0]
        )

        self.assertEqual(
            row['engagement_rate_percent'],
            0.0,
        )

    def test_rate_can_exceed_100(self):
        client = self.client_with_rows(
            [
                (
                    'main',
                    8,
                    0,
                    4,
                    2,
                ),
            ]
        )

        row = (
            like_engagement_dimension_analytics(
                self.start_at,
                self.end_at,
                dimension='profile_type',
                client=client,
            )[0]
        )

        self.assertEqual(
            row['engagement_rate_percent'],
            200.0,
        )

    def test_negative_net_likes(self):
        client = self.client_with_rows(
            [
                (
                    'movie',
                    2,
                    5,
                    2,
                    10,
                ),
            ]
        )

        row = (
            like_engagement_dimension_analytics(
                self.start_at,
                self.end_at,
                dimension='content_type',
                client=client,
            )[0]
        )

        self.assertEqual(
            row['net_likes'],
            -3,
        )

    def test_invalid_dimension_rejected(self):
        for dimension in (
            'platform',
            'device_type',
            'favorite',
            '',
        ):
            with self.subTest(
                dimension=dimension
            ):
                with self.assertRaises(
                    ValueError
                ):
                    (
                        like_engagement_dimension_analytics(
                            self.start_at,
                            self.end_at,
                            dimension=dimension,
                            client=Mock(),
                        )
                    )

    def test_invalid_window_rejected(self):
        with self.assertRaises(ValueError):
            like_engagement_dimension_analytics(
                self.end_at,
                self.start_at,
                dimension='content',
                client=Mock(),
            )

    def test_limit_validation(self):
        for limit in (
            0,
            1001,
            'bad',
        ):
            with self.subTest(limit=limit):
                with self.assertRaises(
                    ValueError
                ):
                    (
                        like_engagement_dimension_analytics(
                            self.start_at,
                            self.end_at,
                            dimension='content',
                            limit=limit,
                            client=Mock(),
                        )
                    )

    def test_half_open_window_contract(self):
        client = self.client_with_rows([])

        like_engagement_dimension_analytics(
            self.start_at,
            self.end_at,
            dimension='content',
            client=client,
        )

        query = (
            client.query.call_args
            .args[0]
        )

        self.assertIn(
            'occurred_at >=',
            query,
        )

        self.assertIn(
            'occurred_at <',
            query,
        )

    def test_real_only_contract(self):
        client = self.client_with_rows([])

        like_engagement_dimension_analytics(
            self.start_at,
            self.end_at,
            dimension='content',
            client=client,
        )

        query = (
            client.query.call_args
            .args[0]
        )

        self.assertGreaterEqual(
            query.count(
                'is_internal = 0'
            ),
            2,
        )

        self.assertGreaterEqual(
            query.count(
                'is_test = 0'
            ),
            2,
        )

    def test_like_activity_contract(self):
        client = self.client_with_rows([])

        like_engagement_dimension_analytics(
            self.start_at,
            self.end_at,
            dimension='content',
            client=client,
        )

        query = (
            client.query.call_args
            .args[0]
        )

        self.assertIn(
            "'content_like'",
            query,
        )

        self.assertIn(
            "'content_unlike'",
            query,
        )

        self.assertIn(
            'uniqExactIf',
            query,
        )

        self.assertNotIn(
            "'favorite'",
            query.lower(),
        )

    def test_d4_qualification_contract(self):
        client = self.client_with_rows([])

        like_engagement_dimension_analytics(
            self.start_at,
            self.end_at,
            dimension='content',
            client=client,
        )

        query = (
            client.query.call_args
            .args[0]
        )

        self.assertIn(
            'sum(watch_seconds)',
            query,
        )

        self.assertIn(
            'max(duration_seconds)',
            query,
        )

        self.assertIn(
            'least(',
            query,
        )

        self.assertIn(
            '30.0',
            query,
        )

        self.assertIn(
            '* 0.10',
            query,
        )

        self.assertIn(
            'viewing_session_id',
            query,
        )

    def test_genre_array_join_on_both_populations(
        self
    ):
        client = self.client_with_rows([])

        like_engagement_dimension_analytics(
            self.start_at,
            self.end_at,
            dimension='genre',
            client=client,
        )

        query = (
            client.query.call_args
            .args[0]
        )

        self.assertEqual(
            query.count(
                'ARRAY JOIN genres AS genre'
            ),
            2,
        )

        self.assertGreaterEqual(
            query.count(
                "genre != ''"
            ),
            2,
        )

    def test_content_dimension_contract(self):
        client = self.client_with_rows([])

        like_engagement_dimension_analytics(
            self.start_at,
            self.end_at,
            dimension='content',
            client=client,
        )

        query = (
            client.query.call_args
            .args[0]
        )

        self.assertIn(
            'toString(content_id)',
            query,
        )

        self.assertGreaterEqual(
            query.count(
                'content_id IS NOT NULL'
            ),
            2,
        )

    def test_producer_dimension_contract(self):
        client = self.client_with_rows([])

        like_engagement_dimension_analytics(
            self.start_at,
            self.end_at,
            dimension='producer',
            client=client,
        )

        query = (
            client.query.call_args
            .args[0]
        )

        self.assertIn(
            'toString(producer_id)',
            query,
        )

        self.assertGreaterEqual(
            query.count(
                'producer_id IS NOT NULL'
            ),
            2,
        )

    def test_content_type_only_movie_series(self):
        client = self.client_with_rows([])

        like_engagement_dimension_analytics(
            self.start_at,
            self.end_at,
            dimension='content_type',
            client=client,
        )

        query = (
            client.query.call_args
            .args[0]
        )

        self.assertGreaterEqual(
            query.count(
                "content_type IN ('movie', 'series')"
            ),
            2,
        )

    def test_country_and_profile_type_exclude_empty(
        self
    ):
        for dimension, token in (
            (
                'country_code',
                "country_code != ''",
            ),
            (
                'profile_type',
                "profile_type != ''",
            ),
        ):
            with self.subTest(
                dimension=dimension
            ):
                client = (
                    self.client_with_rows([])
                )

                (
                    like_engagement_dimension_analytics(
                        self.start_at,
                        self.end_at,
                        dimension=dimension,
                        client=client,
                    )
                )

                query = (
                    client.query.call_args
                    .args[0]
                )

                self.assertGreaterEqual(
                    query.count(token),
                    2,
                )

    def test_dimension_union_keeps_like_only_and_view_only_keys(
        self
    ):
        client = self.client_with_rows([])

        like_engagement_dimension_analytics(
            self.start_at,
            self.end_at,
            dimension='content',
            client=client,
        )

        query = (
            client.query.call_args
            .args[0]
        )

        self.assertIn(
            'dimension_keys',
            query,
        )

        self.assertIn(
            'UNION DISTINCT',
            query,
        )

        self.assertIn(
            'LEFT JOIN like_activity',
            query,
        )

        self.assertIn(
            'LEFT JOIN qualified_viewers',
            query,
        )

    def test_current_likes_not_part_of_dimension_engine(
        self
    ):
        client = self.client_with_rows(
            [
                (
                    'movie',
                    1,
                    0,
                    1,
                    1,
                ),
            ]
        )

        row = (
            like_engagement_dimension_analytics(
                self.start_at,
                self.end_at,
                dimension='content_type',
                client=client,
            )[0]
        )

        self.assertNotIn(
            'current_likes',
            row,
        )
