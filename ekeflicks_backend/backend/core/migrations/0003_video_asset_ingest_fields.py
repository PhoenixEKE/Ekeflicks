from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('core', '0002_streaming_payments'),
    ]

    operations = [
        migrations.AddField(
            model_name='videoasset',
            name='source_file_path',
            field=models.CharField(blank=True, max_length=1000),
        ),
        migrations.AddField(
            model_name='videoasset',
            name='source_file_size_bytes',
            field=models.BigIntegerField(default=0),
        ),
        migrations.AddField(
            model_name='videoasset',
            name='source_uploaded_at',
            field=models.DateTimeField(blank=True, null=True),
        ),
    ]
