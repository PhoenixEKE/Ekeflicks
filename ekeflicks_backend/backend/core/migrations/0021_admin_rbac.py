from django.db import migrations, models


ROLE_PERMISSIONS = {
    'Support': (
        'view_user', 'change_user', 'view_accountclosurerequest',
        'view_emailchangesupportrequest',
    ),
    'Modérateur': (
        'view_user', 'view_content', 'change_content', 'view_contentstatus',
        'change_contentstatus', 'view_videoasset', 'change_videoasset',
    ),
    'Finance': (
        'view_user', 'view_payment', 'view_subscription',
        'view_producerpayoutrequest', 'change_producerpayoutrequest',
    ),
}

PERMISSION_MODELS = {
    'view_user': 'user',
    'change_user': 'user',
    'view_accountclosurerequest': 'accountclosurerequest',
    'view_emailchangesupportrequest': 'emailchangesupportrequest',
    'view_content': 'content',
    'change_content': 'content',
    'view_contentstatus': 'contentstatus',
    'change_contentstatus': 'contentstatus',
    'view_videoasset': 'videoasset',
    'change_videoasset': 'videoasset',
    'view_payment': 'payment',
    'view_subscription': 'subscription',
    'view_producerpayoutrequest': 'producerpayoutrequest',
    'change_producerpayoutrequest': 'producerpayoutrequest',
}


def seed_admin_roles(apps, schema_editor):
    Group = apps.get_model('auth', 'Group')
    Permission = apps.get_model('auth', 'Permission')
    ContentType = apps.get_model('contenttypes', 'ContentType')
    permissions_by_codename = {}
    # Django creates default model permissions from the post_migrate signal. A
    # fresh test database has not emitted that signal while this data migration
    # is running, so create the exact permissions required by the seeded roles.
    for codename, model in PERMISSION_MODELS.items():
        content_type, _ = ContentType.objects.get_or_create(
            app_label='core', model=model,
        )
        action, readable_model = codename.split('_', 1)
        permission, _ = Permission.objects.get_or_create(
            content_type=content_type,
            codename=codename,
            defaults={'name': f'Can {action} {readable_model}'},
        )
        permissions_by_codename[codename] = permission
    for name, codenames in ROLE_PERMISSIONS.items():
        group, _ = Group.objects.get_or_create(name=name)
        group.permissions.set([permissions_by_codename[codename] for codename in codenames])


def remove_admin_roles(apps, schema_editor):
    apps.get_model('auth', 'Group').objects.filter(name__in=ROLE_PERMISSIONS).delete()


class Migration(migrations.Migration):
    dependencies = [('core', '0020_admin_security')]
    operations = [
        migrations.AddField(
            model_name='usersession',
            name='is_admin',
            field=models.BooleanField(default=False),
        ),
        migrations.RunPython(seed_admin_roles, remove_admin_roles),
    ]
