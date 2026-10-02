from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [
        ('core', '0053_producer_demo_earnings_and_contract_rules'),
    ]

    operations = [
        migrations.AddField(
            model_name='videoasset',
            name='drm_metadata',
            field=models.JSONField(blank=True, default=dict),
        ),
    ]
