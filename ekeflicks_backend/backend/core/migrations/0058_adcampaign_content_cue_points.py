from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [
        ("core", "0057_advertising_control_plane"),
    ]

    operations = [
        migrations.AddField(
            model_name="adcampaign",
            name="content_cue_points",
            field=models.JSONField(blank=True, default=dict),
        ),
    ]
