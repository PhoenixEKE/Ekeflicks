import uuid

import django.db.models.deletion
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
        ('core', '0007_analytics_payouts_account_closure'),
    ]

    operations = [
        migrations.AlterField(
            model_name='playbacklicense',
            name='drm_provider',
            field=models.CharField(
                choices=[
                    ('none', 'None'),
                    ('aes_128', 'HLS AES-128'),
                    ('widevine', 'Widevine'),
                    ('fairplay', 'FairPlay'),
                    ('playready', 'PlayReady'),
                    ('axinom', 'Axinom Multi-DRM'),
                ],
                default='none',
                max_length=20,
            ),
        ),
        migrations.AlterField(
            model_name='videoasset',
            name='drm_provider',
            field=models.CharField(
                choices=[
                    ('none', 'None'),
                    ('aes_128', 'HLS AES-128'),
                    ('widevine', 'Widevine'),
                    ('fairplay', 'FairPlay'),
                    ('playready', 'PlayReady'),
                    ('axinom', 'Axinom Multi-DRM'),
                ],
                default='none',
                max_length=20,
            ),
        ),
        migrations.CreateModel(
            name='EmailVerificationToken',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('created_at', models.DateTimeField(auto_now_add=True, db_index=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('token', models.UUIDField(default=uuid.uuid4, editable=False, unique=True)),
                ('expires_at', models.DateTimeField()),
                ('used_at', models.DateTimeField(blank=True, null=True)),
                ('user', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='email_verification_tokens', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'db_table': 'email_verification_tokens',
            },
        ),
        migrations.CreateModel(
            name='PasswordResetToken',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('created_at', models.DateTimeField(auto_now_add=True, db_index=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('token', models.UUIDField(default=uuid.uuid4, editable=False, unique=True)),
                ('expires_at', models.DateTimeField()),
                ('used_at', models.DateTimeField(blank=True, null=True)),
                ('user', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='password_reset_tokens', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'db_table': 'password_reset_tokens',
            },
        ),
        migrations.CreateModel(
            name='EmailChangeSupportRequest',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('created_at', models.DateTimeField(auto_now_add=True, db_index=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('requested_email', models.EmailField(max_length=254)),
                ('reason', models.TextField(blank=True)),
                ('status', models.CharField(choices=[('pending', 'Pending'), ('resolved', 'Resolved'), ('rejected', 'Rejected'), ('cancelled', 'Cancelled')], default='pending', max_length=20)),
                ('admin_reason', models.TextField(blank=True)),
                ('reviewed_at', models.DateTimeField(blank=True, null=True)),
                ('reviewed_by', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='reviewed_email_change_requests', to=settings.AUTH_USER_MODEL)),
                ('user', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='email_change_requests', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'db_table': 'email_change_support_requests',
            },
        ),
        migrations.AddIndex(
            model_name='emailverificationtoken',
            index=models.Index(fields=['token'], name='email_verif_token_0e9348_idx'),
        ),
        migrations.AddIndex(
            model_name='emailverificationtoken',
            index=models.Index(fields=['user', 'used_at'], name='email_verif_user_id_57a116_idx'),
        ),
        migrations.AddIndex(
            model_name='emailverificationtoken',
            index=models.Index(fields=['expires_at'], name='email_verif_expires_3598e1_idx'),
        ),
        migrations.AddIndex(
            model_name='passwordresettoken',
            index=models.Index(fields=['token'], name='password_re_token_f356f7_idx'),
        ),
        migrations.AddIndex(
            model_name='passwordresettoken',
            index=models.Index(fields=['user', 'used_at'], name='password_re_user_id_626f7d_idx'),
        ),
        migrations.AddIndex(
            model_name='passwordresettoken',
            index=models.Index(fields=['expires_at'], name='password_re_expires_b1b850_idx'),
        ),
        migrations.AddIndex(
            model_name='emailchangesupportrequest',
            index=models.Index(fields=['user', 'status'], name='email_chang_user_id_d31022_idx'),
        ),
        migrations.AddIndex(
            model_name='emailchangesupportrequest',
            index=models.Index(fields=['requested_email'], name='email_chang_request_63874b_idx'),
        ),
    ]
