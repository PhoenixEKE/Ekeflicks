from django.db import migrations


ROLE_PERMISSIONS = {
    'Support': ('view_user', 'change_user', 'view_accountclosurerequest',
                'view_emailchangesupportrequest'),
    'Modérateur': ('view_user', 'change_user', 'view_content', 'change_content',
                   'view_contentstatus', 'change_contentstatus', 'view_videoasset',
                   'change_videoasset'),
    'Finance': ('view_user', 'view_payment', 'view_subscription',
                'view_producerpayoutrequest', 'change_producerpayoutrequest'),
}

PERMISSION_MODELS = {
    'view_user': 'user', 'change_user': 'user',
    'view_accountclosurerequest': 'accountclosurerequest',
    'view_emailchangesupportrequest': 'emailchangesupportrequest',
    'view_content': 'content', 'change_content': 'content',
    'view_contentstatus': 'contentstatus', 'change_contentstatus': 'contentstatus',
    'view_videoasset': 'videoasset', 'change_videoasset': 'videoasset',
    'view_payment': 'payment', 'view_subscription': 'subscription',
    'view_producerpayoutrequest': 'producerpayoutrequest',
    'change_producerpayoutrequest': 'producerpayoutrequest',
}


def repair_admin_roles(apps, schema_editor):
    Group = apps.get_model('auth', 'Group')
    Permission = apps.get_model('auth', 'Permission')
    ContentType = apps.get_model('contenttypes', 'ContentType')
    resolved = {}
    for codename, model in PERMISSION_MODELS.items():
        content_type, _ = ContentType.objects.get_or_create(app_label='core', model=model)
        action, readable_model = codename.split('_', 1)
        resolved[codename], _ = Permission.objects.get_or_create(
            content_type=content_type, codename=codename,
            defaults={'name': f'Can {action} {readable_model}'},
        )
    for role, codenames in ROLE_PERMISSIONS.items():
        group, _ = Group.objects.get_or_create(name=role)
        group.permissions.set([resolved[codename] for codename in codenames])


class Migration(migrations.Migration):
    dependencies = [('core', '0023_merge_admin_security_and_rbac')]
    operations = [migrations.RunPython(repair_admin_roles, migrations.RunPython.noop)]
