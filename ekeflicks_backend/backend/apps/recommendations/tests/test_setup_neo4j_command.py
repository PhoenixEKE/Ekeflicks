from io import StringIO
from unittest.mock import patch

from django.core.management import call_command
from django.core.management.base import CommandError
from django.test import TestCase


class SetupNeo4jCommandTests(TestCase):
    @patch(
        'apps.recommendations.management.commands.setup_neo4j.verify_neo4j_connection',
        return_value=False,
    )
    def test_command_fails_when_neo4j_is_disabled(self, _verify):
        with self.assertRaisesMessage(CommandError, 'Neo4j est desactive'):
            call_command('setup_neo4j')

    @patch('apps.recommendations.management.commands.setup_neo4j.ensure_graph_schema')
    @patch(
        'apps.recommendations.management.commands.setup_neo4j.sync_catalog_to_graph',
        return_value={'enabled': True, 'contents': 3, 'genres': 5},
    )
    @patch(
        'apps.recommendations.management.commands.setup_neo4j.verify_neo4j_connection',
        return_value=True,
    )
    def test_command_initializes_schema_and_catalog(
        self,
        _verify,
        sync_catalog,
        ensure_schema,
    ):
        output = StringIO()

        call_command('setup_neo4j', stdout=output)

        ensure_schema.assert_called_once_with()
        sync_catalog.assert_called_once_with()
        self.assertIn('3 contenus', output.getvalue())
        self.assertIn('Neo4j est pret.', output.getvalue())
