from django.core.management.base import BaseCommand, CommandError

from apps.recommendations.engine import (
    ensure_graph_schema,
    sync_catalog_to_graph,
    sync_profile_to_graph,
    verify_neo4j_connection,
)
from core.models import Profile


class Command(BaseCommand):
    help = 'Verifie Neo4j, cree le schema et synchronise le catalogue.'

    def add_arguments(self, parser):
        parser.add_argument(
            '--with-profiles',
            action='store_true',
            help='Synchronise aussi tous les profils et leurs interactions.',
        )

    def handle(self, *args, **options):
        try:
            if not verify_neo4j_connection():
                raise CommandError(
                    'Neo4j est desactive. Configurez NEO4J_ENABLED=True, '
                    'RECOMMENDATION_ENGINE=neo4j et les identifiants Neo4j.'
                )

            ensure_graph_schema()
            result = sync_catalog_to_graph()
            self.stdout.write(
                f"Catalogue synchronise : {result['contents']} contenus, "
                f"{result['genres']} relations de genre."
            )

            profile_count = 0
            relationship_count = 0
            if options['with_profiles']:
                for profile in Profile.objects.filter(is_active=True).iterator():
                    profile_result = sync_profile_to_graph(profile, sync_catalog=False)
                    profile_count += 1
                    relationship_count += profile_result['relationships']
                self.stdout.write(
                    f'Profils synchronises : {profile_count} profils, '
                    f'{relationship_count} interactions.'
                )
        except CommandError:
            raise
        except Exception as exc:
            raise CommandError(f'Initialisation de Neo4j impossible : {exc}') from exc

        self.stdout.write(self.style.SUCCESS('Neo4j est pret.'))
from django.core.management.base import BaseCommand, CommandError

from apps.recommendations.engine import (
    ensure_graph_schema,
    sync_catalog_to_graph,
    sync_profile_to_graph,
    verify_neo4j_connection,
)
from core.models import Profile


class Command(BaseCommand):
    help = 'Verifie Neo4j, cree le schema et synchronise le catalogue.'

    def add_arguments(self, parser):
        parser.add_argument(
            '--with-profiles',
            action='store_true',
            help='Synchronise aussi tous les profils et leurs interactions.',
        )

    def handle(self, *args, **options):
        try:
            if not verify_neo4j_connection():
                raise CommandError(
                    'Neo4j est desactive. Configurez NEO4J_ENABLED=True, '
                    'RECOMMENDATION_ENGINE=neo4j et les identifiants Neo4j.'
                )

            ensure_graph_schema()
            result = sync_catalog_to_graph()
            self.stdout.write(
                f"Catalogue synchronise : {result['contents']} contenus, "
                f"{result['genres']} relations de genre."
            )

            profile_count = 0
            relationship_count = 0
            if options['with_profiles']:
                for profile in Profile.objects.filter(is_active=True).iterator():
                    profile_result = sync_profile_to_graph(profile, sync_catalog=False)
                    profile_count += 1
                    relationship_count += profile_result['relationships']
                self.stdout.write(
                    f'Profils synchronises : {profile_count} profils, '
                    f'{relationship_count} interactions.'
                )
        except CommandError:
            raise
        except Exception as exc:
            raise CommandError(f'Initialisation de Neo4j impossible : {exc}') from exc

        self.stdout.write(self.style.SUCCESS('Neo4j est pret.'))
