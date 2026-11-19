from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('core', '0025_alter_adminmfadevice_secret_and_more'),
    ]

    operations = [
        migrations.RemoveIndex(
            model_name='paymentwebhookevent',
            name='payment_web_provide_5a81c4_idx',
        ),
        migrations.AddConstraint(
            model_name='paymentwebhookevent',
            constraint=models.UniqueConstraint(
                condition=~models.Q(event_id=''),
                fields=('provider', 'event_id'),
                name='uniq_payment_webhook_provider_event_id',
            ),
        ),
    ]
