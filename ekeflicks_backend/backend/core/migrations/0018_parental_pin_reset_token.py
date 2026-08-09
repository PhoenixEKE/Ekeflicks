import uuid

import django.db.models.deletion
from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [('core', '0017_profile_parental_controls')]

    operations = [
        migrations.CreateModel(
            name='ParentalPinResetToken',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('token', models.UUIDField(default=uuid.uuid4, editable=False, unique=True)),
                ('expires_at', models.DateTimeField()),
                ('used_at', models.DateTimeField(blank=True, null=True)),
                ('profile', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='pin_reset_tokens', to='core.profile')),
            ],
            options={'db_table': 'parental_pin_reset_tokens'},
        ),
    ]
