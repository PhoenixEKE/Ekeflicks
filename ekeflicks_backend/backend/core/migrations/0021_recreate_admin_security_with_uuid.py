import uuid

from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion


def generate_mfa_secret():
    return uuid.uuid4().hex + uuid.uuid4().hex[:8]


class Migration(migrations.Migration):
    """Repair the admin tables initially created with incompatible bigint IDs.

    TimeStampedModel uses UUID primary keys. Migration 0020 accidentally declared
    BigAutoField keys, making the ORM unable to insert either model. The feature was
    therefore unusable; recreating these new tables cannot discard valid records.
    """

    dependencies = [('core', '0020_admin_security')]

    operations = [
        migrations.DeleteModel(name='AdminAuditLog'),
        migrations.DeleteModel(name='AdminMFADevice'),
        migrations.CreateModel(
            name='AdminMFADevice',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('created_at', models.DateTimeField(auto_now_add=True, db_index=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('secret', models.CharField(default=generate_mfa_secret, max_length=64)),
                ('confirmed_at', models.DateTimeField(blank=True, null=True)),
                ('last_counter', models.BigIntegerField(default=-1)),
                ('user', models.OneToOneField(on_delete=django.db.models.deletion.CASCADE, related_name='admin_mfa_device', to=settings.AUTH_USER_MODEL)),
            ],
            options={'db_table': 'admin_mfa_devices'},
        ),
        migrations.CreateModel(
            name='AdminAuditLog',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('created_at', models.DateTimeField(auto_now_add=True, db_index=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('action', models.CharField(max_length=120)),
                ('target_type', models.CharField(max_length=80)),
                ('target_id', models.CharField(blank=True, max_length=80)),
                ('metadata', models.JSONField(blank=True, default=dict)),
                ('ip_address', models.GenericIPAddressField(blank=True, null=True)),
                ('actor', models.ForeignKey(on_delete=django.db.models.deletion.PROTECT, related_name='admin_audit_logs', to=settings.AUTH_USER_MODEL)),
            ],
            options={'db_table': 'admin_audit_logs', 'ordering': ('-created_at',)},
        ),
    ]
