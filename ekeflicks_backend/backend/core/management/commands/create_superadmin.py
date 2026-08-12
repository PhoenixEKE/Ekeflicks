import os

from django.core.management.base import BaseCommand, CommandError
from django.db import DEFAULT_DB_ALIAS, connections
from django.db.migrations.executor import MigrationExecutor
from django.utils import timezone

from apps.admin_api.security import provisioning_uri
from core.models.users import AdminMFADevice, User


class Command(BaseCommand):
    help = 'Create (or secure) the initial super-administrator and print its one-time TOTP URI.'

    def add_arguments(self, parser):
        parser.add_argument('--email', default=os.environ.get('SUPERADMIN_EMAIL'))
        parser.add_argument('--password', default=os.environ.get('SUPERADMIN_PASSWORD'))

    def handle(self, *args, **options):
        if not options['email'] or not options['password']:
            raise CommandError('Provide --email/--password or SUPERADMIN_EMAIL/SUPERADMIN_PASSWORD.')
        executor = MigrationExecutor(connections[DEFAULT_DB_ALIAS])
        pending = executor.migration_plan(executor.loader.graph.leaf_nodes())
        if pending:
            raise CommandError(
                'Des migrations sont en attente. Exécutez "python manage.py migrate --noinput" '
                'avant de créer le super-administrateur.'
            )
        user, created = User.objects.get_or_create(email=options['email'].lower())
        user.set_password(options['password'])
        user.is_active = user.is_staff = user.is_superuser = user.is_verified = True
        user.save()
        device, _ = AdminMFADevice.objects.get_or_create(user=user)
        device.confirmed_at = timezone.now()
        device.last_counter = -1
        device.save(update_fields=['confirmed_at', 'last_counter', 'updated_at'])
        self.stdout.write(self.style.SUCCESS('Super-administrateur créé.' if created else 'Super-administrateur mis à jour.'))
        self.stdout.write('Enregistrez maintenant cette URI dans votre application TOTP (elle ne sera plus affichée) :')
        self.stdout.write(provisioning_uri(device))
