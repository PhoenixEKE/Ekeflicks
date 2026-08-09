from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [('core', '0018_parental_pin_reset_token')]

    operations = [
        migrations.AddField(
            model_name='profile',
            name='allowed_min_age',
            field=models.PositiveSmallIntegerField(default=0),
        ),
        migrations.AddField(
            model_name='profile',
            name='allowed_max_age',
            field=models.PositiveSmallIntegerField(default=13),
        ),
        migrations.AlterField(
            model_name='parentalpinresettoken',
            name='created_at',
            field=models.DateTimeField(auto_now_add=True, db_index=True),
        ),
    ]
