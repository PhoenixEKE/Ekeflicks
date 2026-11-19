from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [('core', '0049_producer_agreement_language')]
    operations = [
        migrations.AddField(
            model_name='producerfinanceaccess',
            name='pin_attempts',
            field=models.PositiveSmallIntegerField(default=0),
        ),
        migrations.AddField(
            model_name='producerfinanceaccess',
            name='pin_locked_until',
            field=models.DateTimeField(blank=True, null=True),
        ),
    ]
