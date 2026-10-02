from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [("core", "0045_produceragreement_platform_legal_snapshot")]
    operations = [
        migrations.AddField(model_name="content", name="translations", field=models.JSONField(blank=True, default=dict)),
        migrations.AddField(model_name="genre", name="translations", field=models.JSONField(blank=True, default=dict)),
        migrations.AddField(model_name="technicalspecification", name="translations", field=models.JSONField(blank=True, default=dict)),
        migrations.AddField(model_name="producercontractversion", name="canonical_content_translations", field=models.JSONField(blank=True, default=dict)),
    ]
