import uuid
from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):
    dependencies = [
        ('core', '0046_bilingual_translations'),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]
    operations = [
        migrations.CreateModel(
            name='ProducerFinanceAccess',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('created_at', models.DateTimeField(auto_now_add=True, db_index=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('pin_hash', models.CharField(blank=True, max_length=128)),
                ('pending_pin_hash', models.CharField(blank=True, max_length=128)),
                ('challenge_hash', models.CharField(blank=True, max_length=128)),
                ('challenge_purpose', models.CharField(blank=True, max_length=16)),
                ('challenge_expires_at', models.DateTimeField(blank=True, null=True)),
                ('challenge_attempts', models.PositiveSmallIntegerField(default=0)),
                ('unlocked_until', models.DateTimeField(blank=True, null=True)),
                ('producer', models.OneToOneField(on_delete=django.db.models.deletion.CASCADE, related_name='finance_access', to=settings.AUTH_USER_MODEL)),
            ],
            options={'db_table': 'producer_finance_access'},
        ),
    ]
