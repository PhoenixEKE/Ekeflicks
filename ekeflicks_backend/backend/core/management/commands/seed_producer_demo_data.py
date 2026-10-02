"""Seed clearly marked producer portal demo content and analytics."""

import uuid
from decimal import Decimal
from datetime import timedelta

from django.conf import settings
from django.core.management.base import BaseCommand, CommandError
from django.db import transaction
from django.utils import timezone

from apps.analytics.services import (
    ANALYTICS_EVENT_COLUMNS,
    clickhouse_client,
    normalize_analytics_event,
)
from apps.catalog.translations import source_hash
from core.models import Content, Notification, NotificationType, ProducerDemoEarning, ProducerRevenueSetting, User


SEED_KEY = 'producer_portal_demo_v1'
CONTENTS = (
    ('[DÉMO] Nuit sur Abidjan', 'movie', 96),
    ('[DÉMO] Les voix du quartier', 'series', 42),
    ('[DÉMO] La dernière projection', 'movie', 88),
)
ENGLISH_CONTENT = {
    '[DÉMO] Nuit sur Abidjan': ('[DEMO] Night over Abidjan', 'Private demo title for testing the Producer portal.', 'Fictional testing data. This draft must not be published in the catalog.'),
    '[DÉMO] Les voix du quartier': ('[DEMO] Voices of the Neighborhood', 'Private demo title for testing the Producer portal.', 'Fictional testing data. This draft must not be published in the catalog.'),
    '[DÉMO] La dernière projection': ('[DEMO] The Last Screening', 'Private demo title for testing the Producer portal.', 'Fictional testing data. This draft must not be published in the catalog.'),
}
EVENT_NAMESPACE = uuid.UUID('f98057a3-5d81-4d17-96d9-a3e742f41a21')


class Command(BaseCommand):
    help = 'Ajoute des contenus, statistiques ClickHouse et notifications de démonstration pour un producteur.'

    def add_arguments(self, parser):
        parser.add_argument('--email', default='abylandry@ekeflicks.com')
        parser.add_argument('--clear', action='store_true', help='Supprime les données marquées par cette commande.')
        parser.add_argument(
            '--allow-production', action='store_true',
            help='Confirme explicitement l’écriture dans une base avec DEBUG=False.',
        )

    def handle(self, *args, **options):
        if not settings.DEBUG and not options['allow_production']:
            raise CommandError('Refusé avec DEBUG=False. Relancez avec --allow-production après vérification du compte et du VPS.')

        email = options['email'].strip().lower()
        try:
            producer = User.objects.get(email__iexact=email, is_producer=True)
        except User.DoesNotExist as exc:
            raise CommandError(f'Aucun compte Producteur trouvé pour {email}. Aucun compte n’a été créé ou activé.') from exc

        if options['clear']:
            self._clear(producer)
            return

        account = getattr(producer, 'producer_account', None)
        if not (
            producer.is_active
            and producer.is_verified
            and producer.is_producer
            and account is not None
            and account.status == 'active'
        ):
            raise CommandError('Le compte doit être producteur, actif et vérifié avant d’activer les données de démonstration.')

        preferences = producer.preferences if isinstance(producer.preferences, dict) else {}
        demo_settings = preferences.get('producer_demo_data')
        if demo_settings and (
            not isinstance(demo_settings, dict)
            or demo_settings.get('seed') != SEED_KEY
        ):
            raise CommandError('Un autre jeu de données de démonstration est déjà configuré pour ce compte.')

        client = clickhouse_client()
        if client is None:
            raise CommandError('ClickHouse est indisponible; aucun jeu de données n’a été écrit.')

        created_content = 0
        with transaction.atomic():
            content_rows = []
            for title, content_type, duration in CONTENTS:
                description = 'Contenu de démonstration privé pour tester le portail Producteur.'
                synopsis = 'Données fictives de test. Ce contenu ne doit pas être publié au catalogue.'
                source = {'title': title, 'description': description, 'synopsis': synopsis}
                english_title, english_description, english_synopsis = ENGLISH_CONTENT[title]
                translations = {
                    'fr': {'source_hash': source_hash(source), 'value': source},
                    'en': {
                        'source_hash': source_hash(source),
                        'value': {'title': english_title, 'description': english_description, 'synopsis': english_synopsis},
                    },
                }
                content, created = Content.objects.get_or_create(
                    producer=producer,
                    title=title,
                    defaults={
                        'original_title': title.replace('[DÉMO] ', ''),
                        'type': content_type,
                        'duration': duration,
                        'release_year': timezone.now().year,
                        'description': description,
                        'synopsis': synopsis,
                        'translations': translations,
                        'producer_submission_status': 'draft',
                        'producer_notes': f'demo:{SEED_KEY}',
                    },
                )
                if created:
                    created_content += 1
                elif content.producer_notes != f'demo:{SEED_KEY}' or content.producer_submission_status != 'draft':
                    raise CommandError(f'Le titre {title} existe déjà hors de ce jeu démo; arrêt sans le modifier.')
                content_rows.append(content)

            self._seed_demo_earnings(producer, content_rows)
            self._enable_demo_mode(producer, preferences)
            self._seed_notifications(producer)
            event_count = self._write_events(client, producer, content_rows)

        self.stdout.write(self.style.SUCCESS(
            f'Données de démonstration prêtes pour {email}: '
            f'{len(content_rows)} contenus ([DÉMO]), {event_count} événements analytiques nouveaux marqués is_test=1, '
            f'notifications identifiées [DÉMO] ({created_content} nouveau(x) contenu(s)).'
        ))
        self.stdout.write('Solde et revenus [DÉMO] visibles dans Finance uniquement; exclus des demandes de paiement et du calcul réel.')

    @staticmethod
    def _seed_demo_earnings(producer, contents):
        setting, _ = ProducerRevenueSetting.objects.get_or_create(pk=1)
        demo_rows = (
            (6000, Decimal('40.00')),
            (4200, Decimal('30.00')),
            (3600, Decimal('30.00')),
        )
        for content, (eligible_views, ad_net_eur) in zip(contents, demo_rows):
            view_revenue = (
                Decimal(setting.rate_per_1000_views_eur)
                * Decimal(eligible_views)
                / Decimal('1000')
            ).quantize(Decimal('0.000000001'))
            ProducerDemoEarning.objects.update_or_create(
                producer=producer,
                content=content,
                seed_key=SEED_KEY,
                defaults={
                    'period': timezone.localdate(),
                    'eligible_views': eligible_views,
                    'view_revenue_eur': view_revenue,
                    'advertising_net_revenue_eur': ad_net_eur,
                    'advertising_share_percent': setting.advertising_share_percent,
                },
            )

    @staticmethod
    def _enable_demo_mode(producer, preferences):
        updated = dict(preferences)
        updated['producer_demo_data'] = {'seed': SEED_KEY, 'analytics_enabled': True}
        producer.preferences = updated
        producer.save(update_fields=['preferences', 'updated_at'])

    @staticmethod
    def _seed_notifications(producer):
        notification_type, _ = NotificationType.objects.get_or_create(
            name='producer_demo',
            defaults={'template': 'Producer portal demonstration notification', 'is_push_enabled': False, 'is_email_enabled': False},
        )
        notices = (
            ('[DÉMO] Contenus de test ajoutés', 'Trois brouillons de démonstration sont disponibles dans Mes films et Mes séries.'),
            ('[DÉMO] Analytics activées', 'Des événements synthétiques sont affichés dans Analytics et Eke. Ils ne modifient pas la rémunération.'),
        )
        for index, (title, message) in enumerate(notices, 1):
            Notification.objects.get_or_create(
                user=producer,
                type=notification_type,
                data__demo_seed=SEED_KEY,
                data__demo_index=index,
                defaults={
                    'title': title,
                    'message': message,
                    'data': {'demo_seed': SEED_KEY, 'demo_index': index},
                    'is_read': False,
                    'is_sent': False,
                },
            )

    @staticmethod
    def _event_id(content_id, session_number, event_name):
        return str(uuid.uuid5(EVENT_NAMESPACE, f'{SEED_KEY}:{content_id}:{session_number}:{event_name}'))

    def _write_events(self, client, producer, contents):
        now = timezone.now()
        normalized_rows = []
        for content_index, content in enumerate(contents):
            duration = int(content.duration or 60) * 60
            for session_number in range(1, 19):
                occurred_at = now - timedelta(days=(session_number * 3 + content_index) % 29, hours=session_number % 13)
                viewing_session_id = uuid.uuid5(EVENT_NAMESPACE, f'{SEED_KEY}:{content.id}:{session_number}:session')
                profile_id = uuid.uuid5(EVENT_NAMESPACE, f'{SEED_KEY}:viewer:{session_number % 13}')
                watch_seconds = min(duration, 35 + ((session_number * 17 + content_index * 11) % 245))
                complete = session_number % 4 != 0
                events = [
                    ('video_start', 0, 0.0),
                    ('video_progress', watch_seconds, round(watch_seconds * 100 / duration, 2)),
                ]
                if complete:
                    events.append(('video_complete', 0, 100.0))
                for event_name, watch_delta, completion in events:
                    normalized_rows.append(normalize_analytics_event({
                        'event_id': self._event_id(content.id, session_number, event_name),
                        'event_name': event_name,
                        'occurred_at': occurred_at.isoformat(),
                        'profile_id': str(profile_id),
                        'content_id': str(content.id),
                        'producer_id': str(producer.id),
                        'content_type': content.type,
                        'platform': 'web',
                        'device_type': 'desktop',
                        'viewing_session_id': str(viewing_session_id),
                        'session_id': str(viewing_session_id),
                        'watch_seconds': watch_delta,
                        'position_seconds': watch_seconds,
                        'duration_seconds': duration,
                        'completion_percent': completion,
                        'interface_language': 'fr',
                        'properties': {'demo_seed': SEED_KEY},
                        'is_internal': False,
                        'is_test': True,
                    }))

            for like_number in range(1, 8 + content_index):
                profile_id = uuid.uuid5(EVENT_NAMESPACE, f'{SEED_KEY}:liker:{content.id}:{like_number}')
                normalized_rows.append(normalize_analytics_event({
                    'event_id': str(uuid.uuid5(EVENT_NAMESPACE, f'{SEED_KEY}:{content.id}:like:{like_number}')),
                    'event_name': 'content_like',
                    'occurred_at': (now - timedelta(days=like_number)).isoformat(),
                    'profile_id': str(profile_id),
                    'content_id': str(content.id),
                    'producer_id': str(producer.id),
                    'content_type': content.type,
                    'platform': 'web',
                    'device_type': 'desktop',
                    'properties': {'demo_seed': SEED_KEY},
                    'is_internal': False,
                    'is_test': True,
                }))

        event_ids = [str(row['event_id']) for row in normalized_rows]
        existing_result = client.query(
            'SELECT toString(event_id) FROM analytics_events WHERE event_id IN arrayMap(x -> toUUID(x), {event_ids:Array(String)})',
            parameters={'event_ids': event_ids},
        )
        existing = {row[0] for row in existing_result.result_rows}
        new_rows = [row for row in normalized_rows if str(row['event_id']) not in existing]
        if new_rows:
            client.insert(
                'analytics_events',
                [[row[column] for column in ANALYTICS_EVENT_COLUMNS] for row in new_rows],
                column_names=ANALYTICS_EVENT_COLUMNS,
            )
        return len(new_rows)

    def _clear(self, producer):
        ProducerDemoEarning.objects.filter(producer=producer, seed_key=SEED_KEY).delete()
        content_ids = list(Content.objects.filter(producer=producer, producer_notes=f'demo:{SEED_KEY}').values_list('id', flat=True))
        if content_ids:
            client = clickhouse_client()
            if client is None:
                raise CommandError('ClickHouse est indisponible; rien n’a été supprimé.')
            client.command(
                'ALTER TABLE analytics_events DELETE WHERE is_test = 1 AND content_id IN arrayMap(x -> toUUID(x), {content_ids:Array(String)}) SETTINGS mutations_sync = 1',
                parameters={'content_ids': [str(value) for value in content_ids]},
            )

        Notification.objects.filter(user=producer, data__demo_seed=SEED_KEY).delete()
        Content.objects.filter(producer=producer, id__in=content_ids).delete()

        preferences = producer.preferences if isinstance(producer.preferences, dict) else {}
        demo = preferences.get('producer_demo_data')
        if isinstance(demo, dict) and demo.get('seed') == SEED_KEY:
            updated = dict(preferences)
            updated.pop('producer_demo_data', None)
            producer.preferences = updated
            producer.save(update_fields=['preferences', 'updated_at'])

        self.stdout.write(self.style.SUCCESS(f'Données de démonstration supprimées pour {producer.email}.'))
