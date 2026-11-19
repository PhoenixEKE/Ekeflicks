import uuid
from unittest.mock import Mock, patch

from django.test import SimpleTestCase, override_settings

from apps.analytics.services import (
    build_analytics_event,
    normalize_analytics_event,
    write_analytics_event,
)


class AnalyticsEventNormalizationTests(SimpleTestCase):
    def test_build_event_generates_stable_uuid(self):
        event = build_analytics_event(
            'search',
            interface_language='fr',
        )

        uuid.UUID(event['event_id'])

        normalized = normalize_analytics_event(event)

        self.assertEqual(
            str(normalized['event_id']),
            event['event_id'],
        )
        self.assertEqual(
            normalized['event_name'],
            'search',
        )

    def test_rejects_invalid_content_type(self):
        with self.assertRaises(ValueError):
            normalize_analytics_event({
                'event_name': 'content_clicked',
                'content_type': 'documentary',
            })

    def test_normalizes_bilingual_dimensions(self):
        normalized = normalize_analytics_event({
            'event_name': 'ai_query',
            'interface_language': 'FR',
            'query_language': 'EN',
            'country_code': 'ci',
            'properties': {
                'mode': 'family',
            },
        })

        self.assertEqual(
            normalized['interface_language'],
            'fr',
        )
        self.assertEqual(
            normalized['query_language'],
            'en',
        )
        self.assertEqual(
            normalized['country_code'],
            'CI',
        )


class AnalyticsEventWriterTests(SimpleTestCase):
    @override_settings(
        CACHES={
            'default': {
                'BACKEND': (
                    'django.core.cache.backends.locmem.'
                    'LocMemCache'
                ),
            },
        },
    )
    @patch(
        'apps.analytics.services.clickhouse_client'
    )
    def test_writer_inserts_once(self, client_factory):
        client = Mock()
        client_factory.return_value = client

        exists_result = Mock()
        exists_result.result_rows = [[0]]
        client.query.return_value = exists_result

        event_id = str(uuid.uuid4())

        result = write_analytics_event({
            'event_id': event_id,
            'event_name': 'foundation_test',
            'content_type': 'movie',
            'is_test': True,
        })

        self.assertTrue(result['inserted'])
        self.assertEqual(
            result['status'],
            'inserted',
        )
        client.insert.assert_called_once()

    @override_settings(
        CACHES={
            'default': {
                'BACKEND': (
                    'django.core.cache.backends.locmem.'
                    'LocMemCache'
                ),
            },
        },
    )
    @patch(
        'apps.analytics.services.clickhouse_client'
    )
    def test_duplicate_event_is_not_inserted(
        self,
        client_factory,
    ):
        client = Mock()
        client_factory.return_value = client

        exists_result = Mock()
        exists_result.result_rows = [[1]]
        client.query.return_value = exists_result

        event_id = str(uuid.uuid4())

        result = write_analytics_event({
            'event_id': event_id,
            'event_name': 'foundation_test',
        })

        self.assertFalse(result['inserted'])
        self.assertEqual(
            result['status'],
            'duplicate',
        )
        client.insert.assert_not_called()
