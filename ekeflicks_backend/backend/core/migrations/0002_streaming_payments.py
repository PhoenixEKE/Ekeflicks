import django.db.models.deletion
from django.db import migrations, models
import uuid


class Migration(migrations.Migration):

    dependencies = [
        ('core', '0001_initial'),
    ]

    operations = [
        migrations.AlterField(
            model_name='payment',
            name='provider',
            field=models.CharField(
                blank=True,
                choices=[
                    ('stripe', 'Stripe'),
                    ('paypal', 'PayPal'),
                    ('cinetpay', 'CinetPay'),
                    ('paystack', 'Paystack'),
                    ('flutterwave', 'Flutterwave'),
                    ('orange_money', 'Orange Money'),
                    ('mtn_money', 'MTN Money'),
                    ('moov_money', 'Moov Money'),
                    ('wave', 'Wave'),
                ],
                max_length=50,
            ),
        ),
        migrations.AddField(
            model_name='payment',
            name='checkout_url',
            field=models.URLField(blank=True, max_length=1000),
        ),
        migrations.AddField(
            model_name='payment',
            name='metadata',
            field=models.JSONField(default=dict),
        ),
        migrations.AddField(
            model_name='payment',
            name='provider_payload',
            field=models.JSONField(default=dict),
        ),
        migrations.AddField(
            model_name='payment',
            name='provider_reference',
            field=models.CharField(blank=True, max_length=255, null=True, unique=True),
        ),
        migrations.AddField(
            model_name='payment',
            name='verified_at',
            field=models.DateTimeField(blank=True, null=True),
        ),
        migrations.CreateModel(
            name='VideoAsset',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('created_at', models.DateTimeField(auto_now_add=True, db_index=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('title', models.CharField(blank=True, max_length=255)),
                ('source_file_url', models.URLField(blank=True, max_length=1000)),
                ('hls_master_url', models.URLField(blank=True, max_length=1000)),
                ('dash_manifest_url', models.URLField(blank=True, max_length=1000)),
                ('thumbnail_url', models.URLField(blank=True, max_length=1000)),
                ('duration_seconds', models.IntegerField(default=0)),
                ('status', models.CharField(choices=[('draft', 'Draft'), ('processing', 'Processing'), ('ready', 'Ready'), ('failed', 'Failed')], default='draft', max_length=20)),
                ('is_default', models.BooleanField(default=True)),
                ('is_downloadable', models.BooleanField(default=True)),
                ('drm_provider', models.CharField(choices=[('none', 'None'), ('aes_128', 'HLS AES-128'), ('widevine', 'Widevine'), ('fairplay', 'FairPlay'), ('playready', 'PlayReady')], default='none', max_length=20)),
                ('encryption_key_id', models.CharField(blank=True, max_length=255)),
                ('published_at', models.DateTimeField(blank=True, null=True)),
                ('content', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='video_assets', to='core.content')),
                ('episode', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.CASCADE, related_name='video_assets', to='core.episode')),
            ],
            options={
                'db_table': 'video_assets',
            },
        ),
        migrations.CreateModel(
            name='VideoRendition',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('created_at', models.DateTimeField(auto_now_add=True, db_index=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('quality', models.CharField(choices=[('240p', '240p'), ('360p', '360p'), ('480p', '480p'), ('720p', '720p'), ('1080p', '1080p'), ('1440p', '1440p'), ('2160p', '4K')], max_length=20)),
                ('width', models.IntegerField(default=0)),
                ('height', models.IntegerField(default=0)),
                ('bandwidth', models.IntegerField(default=0)),
                ('codec', models.CharField(blank=True, max_length=100)),
                ('frame_rate', models.DecimalField(blank=True, decimal_places=2, max_digits=5, null=True)),
                ('hls_playlist_url', models.URLField(blank=True, max_length=1000)),
                ('file_size_bytes', models.BigIntegerField(default=0)),
                ('display_order', models.IntegerField(default=0)),
                ('asset', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='renditions', to='core.videoasset')),
            ],
            options={
                'db_table': 'video_renditions',
                'ordering': ['display_order', 'height'],
            },
        ),
        migrations.CreateModel(
            name='SubtitleTrack',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('created_at', models.DateTimeField(auto_now_add=True, db_index=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('language', models.CharField(max_length=10)),
                ('label', models.CharField(max_length=100)),
                ('kind', models.CharField(choices=[('subtitle', 'Subtitle'), ('caption', 'Caption')], default='subtitle', max_length=20)),
                ('url', models.URLField(max_length=1000)),
                ('is_default', models.BooleanField(default=False)),
                ('asset', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='subtitle_tracks', to='core.videoasset')),
            ],
            options={
                'db_table': 'subtitle_tracks',
                'ordering': ['language', 'label'],
            },
        ),
        migrations.CreateModel(
            name='PaymentWebhookEvent',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('created_at', models.DateTimeField(auto_now_add=True, db_index=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('provider', models.CharField(choices=[('stripe', 'Stripe'), ('paypal', 'PayPal'), ('cinetpay', 'CinetPay'), ('paystack', 'Paystack'), ('flutterwave', 'Flutterwave'), ('orange_money', 'Orange Money'), ('mtn_money', 'MTN Money'), ('moov_money', 'Moov Money'), ('wave', 'Wave')], max_length=50)),
                ('event_id', models.CharField(blank=True, max_length=255)),
                ('event_type', models.CharField(blank=True, max_length=100)),
                ('provider_reference', models.CharField(blank=True, max_length=255)),
                ('payload', models.JSONField(default=dict)),
                ('headers', models.JSONField(default=dict)),
                ('signature_valid', models.BooleanField(default=False)),
                ('processed', models.BooleanField(default=False)),
                ('processed_at', models.DateTimeField(blank=True, null=True)),
                ('error_message', models.TextField(blank=True)),
                ('payment', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='webhook_events', to='core.payment')),
            ],
            options={
                'db_table': 'payment_webhook_events',
            },
        ),
        migrations.CreateModel(
            name='OfflineDownloadLicense',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('created_at', models.DateTimeField(auto_now_add=True, db_index=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('device_id', models.CharField(max_length=255)),
                ('device_name', models.CharField(blank=True, max_length=255)),
                ('device_type', models.CharField(blank=True, max_length=50)),
                ('max_quality', models.CharField(blank=True, max_length=20)),
                ('offline_token', models.UUIDField(default=uuid.uuid4, editable=False, unique=True)),
                ('status', models.CharField(choices=[('active', 'Active'), ('expired', 'Expired'), ('revoked', 'Revoked')], default='active', max_length=20)),
                ('expires_at', models.DateTimeField()),
                ('last_verified_at', models.DateTimeField(blank=True, null=True)),
                ('asset', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='offline_licenses', to='core.videoasset')),
                ('content', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='core.content')),
                ('episode', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.CASCADE, to='core.episode')),
                ('profile', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='offline_licenses', to='core.profile')),
            ],
            options={
                'db_table': 'offline_download_licenses',
            },
        ),
        migrations.AddIndex(
            model_name='payment',
            index=models.Index(fields=['provider'], name='payments_provide_f4ea7b_idx'),
        ),
        migrations.AddIndex(
            model_name='payment',
            index=models.Index(fields=['provider_reference'], name='payments_provide_61cc31_idx'),
        ),
        migrations.AddIndex(
            model_name='videoasset',
            index=models.Index(fields=['content', 'status'], name='video_asset_content_1e5ac7_idx'),
        ),
        migrations.AddIndex(
            model_name='videoasset',
            index=models.Index(fields=['episode', 'status'], name='video_asset_episode_f8a41e_idx'),
        ),
        migrations.AddIndex(
            model_name='videoasset',
            index=models.Index(fields=['is_default'], name='video_asset_is_defa_7779df_idx'),
        ),
        migrations.AddIndex(
            model_name='videorendition',
            index=models.Index(fields=['asset', 'quality'], name='video_rendi_asset_i_67d8bd_idx'),
        ),
        migrations.AlterUniqueTogether(
            name='videorendition',
            unique_together={('asset', 'quality')},
        ),
        migrations.AlterUniqueTogether(
            name='subtitletrack',
            unique_together={('asset', 'language', 'kind')},
        ),
        migrations.AddIndex(
            model_name='paymentwebhookevent',
            index=models.Index(fields=['provider', 'event_id'], name='payment_web_provider_1f3787_idx'),
        ),
        migrations.AddIndex(
            model_name='paymentwebhookevent',
            index=models.Index(fields=['provider', 'provider_reference'], name='payment_web_provider_5f52b5_idx'),
        ),
        migrations.AddIndex(
            model_name='paymentwebhookevent',
            index=models.Index(fields=['processed'], name='payment_web_proces_155326_idx'),
        ),
        migrations.AddIndex(
            model_name='offlinedownloadlicense',
            index=models.Index(fields=['profile', 'status'], name='offline_dow_profile_68f3cd_idx'),
        ),
        migrations.AddIndex(
            model_name='offlinedownloadlicense',
            index=models.Index(fields=['device_id', 'status'], name='offline_dow_device__8f42b7_idx'),
        ),
        migrations.AddIndex(
            model_name='offlinedownloadlicense',
            index=models.Index(fields=['expires_at'], name='offline_dow_expires_639313_idx'),
        ),
    ]
