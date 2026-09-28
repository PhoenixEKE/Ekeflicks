from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [('core', '0048_producer_advertising_revenue_and_rules')]
    operations = [
        migrations.AddField(
            model_name='produceragreement',
            name='contract_language',
            field=models.CharField(choices=[('fr', 'Français'), ('en', 'English')], default='fr', max_length=2),
        ),
    ]
