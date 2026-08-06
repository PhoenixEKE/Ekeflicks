from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [('core', '0009_rename_account_clo_user_id_3bf80d_idx_account_clo_user_id_4afc73_idx_and_more')]

    operations = [
        migrations.AlterField(
            model_name='user',
            name='email',
            field=models.EmailField(blank=True, max_length=254, null=True, unique=True),
        ),
    ]
