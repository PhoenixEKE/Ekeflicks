import secrets
from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion


def mfa_secret():
    return secrets.token_hex(20)


class Migration(migrations.Migration):
    dependencies = [('core', '0019_profile_allowed_age_range')]
    operations = [
        migrations.CreateModel(
            name='AdminMFADevice',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('secret', models.CharField(default=mfa_secret, max_length=64)),
                ('confirmed_at', models.DateTimeField(blank=True, null=True)),
                ('last_counter', models.BigIntegerField(default=-1)),
                ('user', models.OneToOneField(on_delete=django.db.models.deletion.CASCADE, related_name='admin_mfa_device', to=settings.AUTH_USER_MODEL)),
            ],
            options={'db_table': 'admin_mfa_devices'},
        ),
        migrations.CreateModel(
            name='AdminAuditLog',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('created_at', models.DateTimeField(auto_now_add=True)),
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
