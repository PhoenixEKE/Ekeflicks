from django.db import migrations


class Migration(migrations.Migration):
    """Join the parallel admin-security repair and RBAC migration branches."""

    dependencies = [
        ('core', '0021_recreate_admin_security_with_uuid'),
        ('core', '0022_moderator_producer_management'),
    ]

    operations = []
