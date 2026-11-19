from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        (
            "core",
            "0034_content_backdrop_temp_path_and_more",
        ),
    ]

    operations = [
        migrations.AddField(
            model_name="season",
            name="backdrop_temp_path",
            field=models.CharField(
                blank=True,
                max_length=1000,
            ),
        ),
        migrations.AddField(
            model_name="season",
            name="backdrop_url",
            field=models.URLField(
                blank=True,
                max_length=1000,
            ),
        ),
        migrations.AddField(
            model_name="season",
            name="description",
            field=models.TextField(
                blank=True,
            ),
        ),
        migrations.AddField(
            model_name="season",
            name="poster_temp_path",
            field=models.CharField(
                blank=True,
                max_length=1000,
            ),
        ),
        migrations.AddField(
            model_name="season",
            name="poster_url",
            field=models.URLField(
                blank=True,
                max_length=1000,
            ),
        ),
        migrations.AddField(
            model_name="season",
            name="trailer_temp_path",
            field=models.CharField(
                blank=True,
                max_length=1000,
            ),
        ),
        migrations.AddField(
            model_name="season",
            name="trailer_url",
            field=models.URLField(
                blank=True,
                max_length=1000,
            ),
        ),
    ]
