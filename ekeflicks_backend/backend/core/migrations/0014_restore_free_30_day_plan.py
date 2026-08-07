from django.db import migrations


PLAN_SLUG = 'free-30-days'


def restore_free_plan(apps, schema_editor):
    """Make the onboarding offer available, including on existing databases."""
    SubscriptionPlan = apps.get_model('core', 'SubscriptionPlan')
    SubscriptionPlan.objects.update_or_create(
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


class Migration(migrations.Migration):
    dependencies = [
        ('core', '0013_seed_free_30_day_plan'),
    ]

    operations = [
        migrations.RunPython(restore_free_plan, migrations.RunPython.noop),
    ]
