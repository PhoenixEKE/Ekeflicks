from django.db import migrations


BROKEN_DEFAULT_AVATAR_URLS = [
    'https://cdn.ekeflicks.com/avatars/default-adult.png',
    'https://cdn.ekeflicks.com/avatars/default-child.png',
]


def remove_broken_default_avatar_urls(apps, schema_editor):
    Profile = apps.get_model('core', 'Profile')
    Profile.objects.filter(avatar_url__in=BROKEN_DEFAULT_AVATAR_URLS).update(avatar_url='')


class Migration(migrations.Migration):
    dependencies = [
        ('core', '0014_restore_free_30_day_plan'),
    ]

    operations = [
        migrations.RunPython(remove_broken_default_avatar_urls, migrations.RunPython.noop),
    ]
