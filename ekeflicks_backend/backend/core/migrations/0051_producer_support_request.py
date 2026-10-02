import uuid
import django.db.models.deletion
from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [('core', '0050_producer_finance_pin_lockout')]

    operations = [
        migrations.CreateModel(
            name='ProducerSupportRequest',
            fields=[
                ('id', models.UUIDField(primary_key=True, default=uuid.uuid4, serialize=False, editable=False)),
                ('created_at', models.DateTimeField(auto_now_add=True, db_index=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('subject', models.CharField(max_length=180)),
                ('message', models.TextField()),
                ('status', models.CharField(choices=[('pending', 'Pending'), ('in_progress', 'In progress'), ('resolved', 'Resolved'), ('closed', 'Closed')], default='pending', max_length=20)),
                ('staff_reply', models.TextField(blank=True)),
                ('user', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='producer_support_requests', to='core.user')),
            ],
            options={
                'db_table': 'producer_support_requests',
                'ordering': ['-created_at'],
            },
        ),
    ]
