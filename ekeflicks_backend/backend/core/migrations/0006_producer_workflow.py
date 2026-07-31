import django.db.models.deletion
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
        ('core', '0005_playback_license'),
    ]

    operations = [
        migrations.AddField(
            model_name='user',
            name='is_producer',
            field=models.BooleanField(default=False),
        ),
        migrations.AddField(
            model_name='user',
            name='producer_company',
            field=models.CharField(blank=True, max_length=255),
        ),
        migrations.AddField(
            model_name='content',
            name='producer',
            field=models.ForeignKey(
                blank=True,
                null=True,
                on_delete=django.db.models.deletion.SET_NULL,
                related_name='produced_contents',
                to=settings.AUTH_USER_MODEL,
            ),
        ),
        migrations.AddField(
            model_name='content',
            name='producer_submission_status',
            field=models.CharField(
                choices=[
                    ('draft', 'Draft'),
                    ('pending', 'Pending review'),
                    ('approved', 'Approved'),
                    ('rejected', 'Rejected'),
                ],
                db_index=True,
                default='draft',
                max_length=20,
            ),
        ),
        migrations.AddField(
            model_name='content',
            name='producer_notes',
            field=models.TextField(blank=True),
        ),
        migrations.AddField(
            model_name='content',
            name='review_reason',
            field=models.TextField(blank=True),
        ),
        migrations.AddField(
            model_name='content',
            name='submitted_at',
            field=models.DateTimeField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name='content',
            name='reviewed_by',
            field=models.ForeignKey(
                blank=True,
                null=True,
                on_delete=django.db.models.deletion.SET_NULL,
                related_name='reviewed_contents',
                to=settings.AUTH_USER_MODEL,
            ),
        ),
        migrations.AddField(
            model_name='content',
            name='reviewed_at',
            field=models.DateTimeField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name='videoasset',
            name='source_uploaded_by',
            field=models.ForeignKey(
                blank=True,
                null=True,
                on_delete=django.db.models.deletion.SET_NULL,
                related_name='uploaded_video_assets',
                to=settings.AUTH_USER_MODEL,
            ),
        ),
        migrations.AddIndex(
            model_name='content',
            index=models.Index(
                fields=['producer', 'producer_submission_status'],
                name='content_producer_status_idx',
            ),
        ),
        migrations.AddIndex(
            model_name='videoasset',
            index=models.Index(
                fields=['source_uploaded_by', 'source_uploaded_at'],
                name='video_asset_source_upload_idx',
            ),
        ),
    ]
