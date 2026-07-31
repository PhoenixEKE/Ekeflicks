from django.db.models.signals import post_save
from django.dispatch import receiver
from apps.analytics.services import record_producer_viewing_session
from apps.notifications.services import notify_user
from core.models.analytics import ViewingSession
from core.models.subscriptions import Subscription
from core.models.users import User
from core.models.profiles import Profile, ProfileType

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
        default_name = instance.firstname or instance.email.split('@')[0]
        default_avatar = 'https://cdn.ekeflicks.com/avatars/default-adult.png'
        Profile.objects.create(
            user=instance,
            type=profile_type,
            name=default_name,
            avatar_url=default_avatar,
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
