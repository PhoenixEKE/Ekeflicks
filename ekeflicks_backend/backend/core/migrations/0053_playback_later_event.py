from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):
    dependencies = [
        ('core', '0052_frequently_asked_questions'),
    ]

    operations = [
        migrations.CreateModel(
            name='PlaybackLaterEvent',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('created_at', models.DateTimeField(auto_now_add=True, db_index=True)),
                ('content', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='playback_later_events', to='core.content')),
            ],
            options={'db_table': 'playback_later_events'},
        ),
        migrations.AddIndex(
            model_name='playbacklaterevent',
            index=models.Index(fields=['content', 'created_at'], name='pb_later_content_created_ix'),
        ),
    ]
