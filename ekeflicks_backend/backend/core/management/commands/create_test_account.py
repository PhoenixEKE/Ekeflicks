from datetime import timedelta

from django.conf import settings
from django.core.management.base import BaseCommand, CommandError
from django.db import transaction
from django.utils import timezone

from core.models import Profile, ProfileType, Subscription, SubscriptionPlan, User


class Command(BaseCommand):
    help = "Crée ou met à jour le compte de test avec un abonnement Basic actif."

    def add_arguments(self, parser):
        parser.add_argument('--email', default='test@ekeflicks.com')
        parser.add_argument('--password', default='Test1234!')
        parser.add_argument(
            '--allow-production',
            action='store_true',
            help="Autorise explicitement l'exécution lorsque DEBUG=False.",
        )

    @transaction.atomic
    def handle(self, *args, **options):
        if not settings.DEBUG and not options['allow_production']:
            raise CommandError(
                "Création du compte de test refusée lorsque DEBUG=False. "
                "Utilisez --allow-production pour confirmer explicitement."
            )

        email = options['email'].strip().lower()
        password = options['password']
        if not email or not password:
            raise CommandError("L'adresse e-mail et le mot de passe sont obligatoires.")

        plan, plan_created = SubscriptionPlan.objects.get_or_create(
            slug='basic',
            defaults={
                'name': 'Basic',
                'description': "Offre de base EkeFlicks",
                'price': '5.00',
                'currency': 'EUR',
                'duration_days': 30,
                'max_profiles': 1,
                'max_devices': 1,
                'max_quality': 'HD',
                'ads_included': False,
                'download_enabled': False,
                'features': ['Streaming HD', '1 profil', '1 appareil'],
                'display_order': 0,
                'is_active': True,
            },
        )

        user, user_created = User.objects.get_or_create(
            email=email,
            defaults={
                'firstname': 'Compte',
                'lastname': 'Test',
                'is_active': True,
                'is_verified': True,
            },
        )
        user.set_password(password)
        user.is_active = True
        user.is_verified = True
        user.save(update_fields=['password', 'is_active', 'is_verified', 'updated_at'])

        main_profile_type, _ = ProfileType.objects.get_or_create(
            name='main',
            defaults={
                'description': 'Profil principal - accès complet',
                'can_create_lists': True,
                'can_rate_content': True,
            },
        )
        profile_name = user.firstname or email.split('@', maxsplit=1)[0]
        profile, profile_created = Profile.objects.get_or_create(
            user=user,
            name=profile_name,
            defaults={
                'type': main_profile_type,
                'avatar_url': 'https://cdn.ekeflicks.com/avatars/default-adult.png',
                'is_active': True,
            },
        )
        if not profile.is_active or profile.type_id != main_profile_type.id:
            profile.is_active = True
            profile.type = main_profile_type
            profile.save(update_fields=['is_active', 'type', 'updated_at'])

        now = timezone.now()
        subscription = (
            Subscription.objects.filter(user=user, plan=plan, status='active', expires_at__gt=now)
            .order_by('-expires_at')
            .first()
        )
        subscription_created = subscription is None
        if subscription_created:
            subscription = Subscription.objects.create(
                user=user,
                plan=plan,
                status='active',
                expires_at=now + timedelta(days=plan.duration_days),
                auto_renew=True,
            )

        actions = [
            'plan créé' if plan_created else 'plan existant',
            'compte créé' if user_created else 'compte mis à jour',
            'profil créé' if profile_created else 'profil existant',
            'abonnement créé' if subscription_created else 'abonnement actif conservé',
        ]
        self.stdout.write(self.style.SUCCESS(f"Compte de test prêt ({', '.join(actions)}) : {email}"))
