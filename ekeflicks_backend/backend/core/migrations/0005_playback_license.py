import uuid

from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('core', '0004_video_asset_moderation'),
    ]

    operations = [
        migrations.CreateModel(
            name='PlaybackLicense',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('created_at', models.DateTimeField(auto_now_add=True, db_index=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('device_id', models.CharField(max_length=255)),
                ('device_type', models.CharField(blank=True, max_length=50)),
                ('license_token', models.UUIDField(default=uuid.uuid4, editable=False, unique=True)),
                ('license_mode', models.CharField(choices=[('stream', 'Stream'), ('offline', 'Offline')], default='stream', max_length=20)),
                ('drm_provider', models.CharField(choices=[('none', 'None'), ('aes_128', 'HLS AES-128'), ('widevine', 'Widevine'), ('fairplay', 'FairPlay'), ('playready', 'PlayReady')], default='none', max_length=20)),
                ('key_id', models.CharField(blank=True, max_length=255)),
                ('status', models.CharField(choices=[('active', 'Active'), ('expired', 'Expired'), ('revoked', 'Revoked')], default='active', max_length=20)),
                ('expires_at', models.DateTimeField()),
                ('last_verified_at', models.DateTimeField(blank=True, null=True)),
                ('metadata', models.JSONField(blank=True, default=dict)),
                ('asset', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='playback_licenses', to='core.videoasset')),
                ('content', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='core.content')),
                ('episode', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.CASCADE, to='core.episode')),
                ('profile', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='playback_licenses', to='core.profile')),
                ('subscription', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='playback_licenses', to='core.subscription')),
            ],
            options={
                'db_table': 'playback_licenses',
            },
        ),
        migrations.AddIndex(
            model_name='playbacklicense',
            index=models.Index(fields=['profile', 'status'], name='playback_li_profile_8ddc9c_idx'),
        ),
        migrations.AddIndex(
            model_name='playbacklicense',
            index=models.Index(fields=['asset', 'status'], name='playback_li_asset_i_4d6e7f_idx'),
        ),
        migrations.AddIndex(
            model_name='playbacklicense',
            index=models.Index(fields=['device_id', 'status'], name='playback_li_device__2bbfe9_idx'),
        ),
        migrations.AddIndex(
            model_name='playbacklicense',
            index=models.Index(fields=['license_token'], name='playback_li_license_1c462d_idx'),
        ),
        migrations.AddIndex(
            model_name='playbacklicense',
            index=models.Index(fields=['expires_at'], name='playback_li_expires_b7ef44_idx'),
        ),
    ]
