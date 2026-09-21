from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        (
            "core",
            "0038_content_audio_subtitle_languages",
        ),
    ]

    operations = [
        migrations.AddField(
            model_name="videoasset",
            name="delivery_level",
            field=models.CharField(
                choices=[
                    (
                        "premium",
                        "Master Premium",
                    ),
                    (
                        "standard",
                        "Master Standard",
                    ),
                    (
                        "distribution",
                        "Master Distribution",
                    ),
                ],
                db_index=True,
                default="distribution",
                max_length=20,
            ),
        ),
    ]
