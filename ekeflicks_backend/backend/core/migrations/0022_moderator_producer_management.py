from django.db import migrations


def allow_moderator_user_management(apps, schema_editor):
    group, _ = apps.get_model('auth', 'Group').objects.get_or_create(name='Modérateur')
    content_type, _ = apps.get_model('contenttypes', 'ContentType').objects.get_or_create(
        app_label='core', model='user',
    )
    permission, _ = apps.get_model('auth', 'Permission').objects.get_or_create(
        content_type=content_type,
        codename='change_user',
        defaults={'name': 'Can change user'},
    )
    group.permissions.add(permission)


def disallow_moderator_user_management(apps, schema_editor):
    Group = apps.get_model('auth', 'Group')
    Permission = apps.get_model('auth', 'Permission')
    group = Group.objects.filter(name='Modérateur').first()
    permission = Permission.objects.filter(
        content_type__app_label='core', codename='change_user',
    ).first()
    if group and permission:
        group.permissions.remove(permission)


class Migration(migrations.Migration):
    dependencies = [('core', '0021_admin_rbac')]
    operations = [migrations.RunPython(
        allow_moderator_user_management,
        disallow_moderator_user_management,
    )]
