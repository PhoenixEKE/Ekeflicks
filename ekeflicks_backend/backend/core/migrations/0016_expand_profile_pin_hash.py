from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [('core', '0015_remove_broken_default_avatar_urls')]

    operations = [
        migrations.AlterField(
            model_name='profile',
            name='pin_code',
            field=models.CharField(blank=True, max_length=128),
        ),
    ]
