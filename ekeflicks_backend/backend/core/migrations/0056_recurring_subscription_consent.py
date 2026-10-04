from django.db import migrations, models


def disable_legacy_auto_renew(apps, schema_editor):
    Subscription = apps.get_model('core', 'Subscription')
    Subscription.objects.filter(auto_renew=True).update(auto_renew=False)


class Migration(migrations.Migration):
    dependencies = [
        ('core', '0055_contract_compensation_snapshots'),
    ]

    operations = [
        migrations.RunPython(
            disable_legacy_auto_renew,
            migrations.RunPython.noop,
        ),
        migrations.AlterField(
            model_name='subscription',
            name='auto_renew',
            field=models.BooleanField(default=False),
        ),
        migrations.AddField(
            model_name='subscription',
            name='auto_renew_consent_at',
            field=models.DateTimeField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name='subscription',
            name='stripe_subscription_id',
            field=models.CharField(blank=True, max_length=255, null=True, unique=True),
        ),
        migrations.AddField(
            model_name='subscription',
            name='stripe_customer_id',
            field=models.CharField(blank=True, default='', max_length=255),
        ),
        migrations.AddField(
            model_name='subscription',
            name='cancel_at_period_end',
            field=models.BooleanField(default=False),
        ),
    ]
