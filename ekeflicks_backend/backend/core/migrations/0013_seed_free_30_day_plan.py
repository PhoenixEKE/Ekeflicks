from datetime import timedelta

from django.contrib.auth.hashers import make_password
from django.db import migrations
from django.utils import timezone


PLAN_SLUG = 'free-30-days'
TEST_EMAIL = 'test@ekeflicks.com'
TEST_PASSWORD = 'Test1234!'


def ensure_default_test_account(apps):
    User = apps.get_model('core', 'User')
    Subscription = apps.get_model('core', 'Subscription')
    SubscriptionPlan = apps.get_model('core', 'SubscriptionPlan')

    basic_plan, _ = SubscriptionPlan.objects.get_or_create(
        slug='basic',
        defaults={
            'name': 'Basic',
            'description': 'Offre de base EkeFlicks',
            'price': '5.00',
            'currency': 'EUR',
            'duration_days': 30,
            'max_profiles': 1,
            'max_devices': 1,
            'max_quality': 'HD',
            'ads_included': False,
            'download_enabled': False,
            'features': ['Streaming HD', '1 profil', '1 appareil'],
            'display_order': 1,
            'is_active': True,
        },
    )
    user, _ = User.objects.update_or_create(
        email=TEST_EMAIL,
        defaults={
            'password': make_password(TEST_PASSWORD),
            'firstname': 'Compte',
            'lastname': 'Test',
            'is_active': True,
            'is_verified': True,
        },
    )
    now = timezone.now()
    if not Subscription.objects.filter(
        user=user,
        plan=basic_plan,
        status='active',
        expires_at__gt=now,
    ).exists():
        Subscription.objects.create(
            user=user,
            plan=basic_plan,
            status='active',
            expires_at=now + timedelta(days=basic_plan.duration_days),
            auto_renew=True,
        )


def ensure_default_test_profile(apps):
    User = apps.get_model('core', 'User')
    Profile = apps.get_model('core', 'Profile')
    ProfileType = apps.get_model('core', 'ProfileType')

    user = User.objects.filter(email=TEST_EMAIL).first()
    if user is None:
        return

    main_profile_type, _ = ProfileType.objects.get_or_create(
        name='main',
        defaults={
            'description': 'Profil principal - accès complet',
            'can_create_lists': True,
            'can_rate_content': True,
        },
    )
    profile, _ = Profile.objects.get_or_create(
        user=user,
        name='Compte',
        defaults={
            'type': main_profile_type,
            'avatar_url': 'https://cdn.ekeflicks.com/avatars/default-adult.png',
            'is_active': True,
        },
    )
    fields_to_update = []
    if profile.type_id != main_profile_type.id:
        profile.type = main_profile_type
        fields_to_update.append('type')
    if not profile.is_active:
        profile.is_active = True
        fields_to_update.append('is_active')
    if fields_to_update:
        profile.save(update_fields=fields_to_update)


def seed_free_plan(apps, schema_editor):
    ensure_default_test_account(apps)
    ensure_default_test_profile(apps)
    SubscriptionPlan = apps.get_model('core', 'SubscriptionPlan')
    SubscriptionPlan.objects.get_or_create(
        slug=PLAN_SLUG,
        defaults={
            'name': 'Gratuit 30 jours',
            'description': "Accès gratuit à EkeFlicks pendant 30 jours",
            'price': '0.00',
            'currency': 'EUR',
            'duration_days': 30,
            'max_profiles': 1,
            'max_devices': 1,
            'max_quality': 'HD',
            'ads_included': False,
            'download_enabled': False,
            'features': ['30 jours gratuits', 'Streaming HD', '1 profil', '1 appareil'],
            'display_order': 0,
            'is_active': True,
        },
    )


def remove_free_plan(apps, schema_editor):
    User = apps.get_model('core', 'User')
    Subscription = apps.get_model('core', 'Subscription')
    SubscriptionPlan = apps.get_model('core', 'SubscriptionPlan')
    User.objects.filter(email=TEST_EMAIL).delete()
    plan = SubscriptionPlan.objects.filter(slug=PLAN_SLUG).first()
    if plan is not None and not Subscription.objects.filter(plan=plan).exists():
        plan.delete()


class Migration(migrations.Migration):
    dependencies = [
        ('core', '0010_allow_phone_only_users'),
    ]

    operations = [
        migrations.RunPython(seed_free_plan, remove_free_plan),
    ]
