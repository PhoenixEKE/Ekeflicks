from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [
        ('salons', '0008_salon_host_leave_policy_salon_join_code_and_more'),
    ]

    operations = [
        migrations.AddField(
            model_name='salon',
            name='scheduled_at',
            field=models.DateTimeField(blank=True, null=True),
        ),
    ]
