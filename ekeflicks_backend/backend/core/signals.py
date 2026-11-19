from django.db.models.signals import post_save
from django.db import transaction
from django.dispatch import receiver
from apps.analytics.services import record_producer_viewing_session
from apps.notifications.services import notify_user
from core.models.analytics import ViewingSession
from core.models.subscriptions import Subscription
from core.models.users import User
from core.models.profiles import Profile, ProfileType
from core.models.content import Content, Genre
from core.models.technical_specification import TechnicalSpecification
from core.models.producers import ProducerContractVersion
from apps.catalog.translations import content_source, source_hash


@receiver(post_save, sender=Content)
def schedule_content_translation(sender, instance, **kwargs):
    source = content_source(instance)
    revision = source_hash(source)
    translations = instance.translations or {}
    if all(
        isinstance(translations.get(language), dict)
        and translations[language].get('source_hash') == revision
        for language in ('en', 'fr')
    ):
        return
    from apps.catalog.tasks import translate_content_fields
    transaction.on_commit(
        lambda: translate_content_fields.delay(str(instance.pk))
    )


@receiver(post_save, sender=Genre)
def schedule_genre_translation(sender, instance, **kwargs):
    from apps.catalog.tasks import translate_reference_texts
    transaction.on_commit(
        lambda: translate_reference_texts.delay('genre', str(instance.pk))
    )


@receiver(post_save, sender=TechnicalSpecification)
def schedule_specification_translation(sender, instance, **kwargs):
    from apps.catalog.tasks import translate_reference_texts
    transaction.on_commit(
        lambda: translate_reference_texts.delay(
            'technical_specification', str(instance.pk)
        )
    )


@receiver(post_save, sender=ProducerContractVersion)
def schedule_contract_translation(sender, instance, **kwargs):
    # Published and archived contract text is immutable. Draft edits create
    # fresh translations and publication checks their source hash and review.
    if instance.status not in {
        ProducerContractVersion.STATUS_DRAFT,
        ProducerContractVersion.STATUS_PUBLISHED,
    }:
        return
    from apps.auth.tasks import translate_contract_version
    transaction.on_commit(
        lambda: translate_contract_version.delay(str(instance.pk))
    )


@receiver(post_save, sender=User)
def create_default_profile(sender, instance, created, **kwargs):
    if created:
        profile_type, _ = ProfileType.objects.get_or_create(
            name='main',
            defaults={
                'description': 'Profil principal - accès complet',
                'can_create_lists': True,
                'can_rate_content': True
            }
        )
        ProfileType.objects.get_or_create(
            name='child',
            defaults={
                'description': 'Profil enfant - contenu restreint par âge',
                'max_age_restriction': 12,
                'can_create_lists': False,
                'can_rate_content': True
            }
        )
        ProfileType.objects.get_or_create(
            name='guest',
            defaults={
                'description': 'Profil invité - accès limité',
                'can_create_lists': False,
                'can_rate_content': False
            }
        )
        default_name = instance.firstname or (instance.email.split('@')[0] if instance.email else instance.phone)
        Profile.objects.create(
            user=instance,
            type=profile_type,
            name=default_name,
            # The clients provide a bundled fallback avatar. Keeping this
            # empty avoids persisting a CDN URL that may not exist.
            avatar_url='',
            phone=instance.phone,
            country_code=instance.country_code,
            is_active=True
        )
        notify_user(instance, 'account_created')


@receiver(post_save, sender=Subscription)
def notify_subscription_created(sender, instance, created, **kwargs):
    if created:
        notify_user(
            instance.user,
            'subscription_created',
            data={'subscription_id': str(instance.id), 'plan_id': str(instance.plan_id)},
        )


@receiver(post_save, sender=ViewingSession)
def count_producer_view(sender, instance, **kwargs):
    record_producer_viewing_session(instance)
