import django.db.models.deletion
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
        ('core', '0003_video_asset_ingest_fields'),
    ]

    operations = [
        migrations.AddField(
            model_name='videoasset',
            name='moderation_status',
            field=models.CharField(
                choices=[
                    ('pending', 'Pending'),
                    ('approved', 'Approved'),
                    ('rejected', 'Rejected'),
                ],
                default='pending',
                max_length=20,
            ),
        ),
        migrations.AddField(
            model_name='videoasset',
            name='moderation_reason',
            field=models.TextField(blank=True),
        ),
        migrations.AddField(
            model_name='videoasset',
            name='moderated_at',
            field=models.DateTimeField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name='videoasset',
            name='moderated_by',
            field=models.ForeignKey(
                blank=True,
                null=True,
                on_delete=django.db.models.deletion.SET_NULL,
                related_name='moderated_video_assets',
                to=settings.AUTH_USER_MODEL,
            ),
        ),
        migrations.AddIndex(
            model_name='videoasset',
            index=models.Index(fields=['moderation_status'], name='video_asset_moderat_319b0f_idx'),
        ),
    ]
