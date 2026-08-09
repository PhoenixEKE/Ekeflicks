from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [('core', '0016_expand_profile_pin_hash')]

    operations = [
        migrations.AddField(model_name='profile', name='adult_profiles_locked', field=models.BooleanField(default=False)),
        migrations.AddField(model_name='profile', name='child_history_enabled', field=models.BooleanField(default=True)),
        migrations.AddField(model_name='profile', name='safe_search_enabled', field=models.BooleanField(default=True)),
    ]
