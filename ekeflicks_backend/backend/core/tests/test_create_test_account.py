from io import StringIO

from django.core.management import call_command
from django.test import TestCase, override_settings
from django.utils import timezone

from core.models import Subscription, SubscriptionPlan, User


class DefaultTestAccountMigrationTests(TestCase):
    def test_default_account_is_available_after_migrations(self):
        user = User.objects.get(email='test@ekeflicks.com')

        self.assertTrue(user.check_password('Test1234!'))
        self.assertTrue(user.is_active)
        self.assertTrue(user.is_verified)
        self.assertTrue(user.profiles.filter(name='Compte', is_active=True).exists())
        self.assertTrue(
            Subscription.objects.filter(
                user=user,
                plan__slug='basic',
                status='active',
                expires_at__gt=timezone.now(),
            ).exists()
        )


@override_settings(DEBUG=True)
class CreateTestAccountCommandTests(TestCase):
    def test_command_creates_basic_account_and_active_subscription(self):
        call_command('create_test_account', stdout=StringIO())

        user = User.objects.get(email='test@ekeflicks.com')
        plan = SubscriptionPlan.objects.get(slug='basic')
        subscription = Subscription.objects.get(user=user, plan=plan)

        self.assertTrue(user.check_password('Test1234!'))
        self.assertTrue(user.is_verified)
        self.assertTrue(user.profiles.filter(name='Compte', is_active=True).exists())
        self.assertEqual(plan.name, 'Basic')
        self.assertEqual(subscription.status, 'active')
        self.assertGreater(subscription.expires_at, timezone.now())

    def test_command_is_idempotent_and_accepts_custom_credentials(self):
        arguments = ('create_test_account',)
        options = {
            'email': 'viewer@example.com',
            'password': 'CustomPass123!',
            'stdout': StringIO(),
        }

        call_command(*arguments, **options)
        call_command(*arguments, **options)

        user = User.objects.get(email='viewer@example.com')
        self.assertTrue(user.check_password('CustomPass123!'))
        self.assertEqual(User.objects.filter(email=user.email).count(), 1)
        self.assertEqual(SubscriptionPlan.objects.filter(slug='basic').count(), 1)
        self.assertEqual(Subscription.objects.filter(user=user, status='active').count(), 1)

    def test_command_repairs_a_missing_profile(self):
        user = User.objects.get(email='test@ekeflicks.com')
        user.profiles.all().delete()

        call_command('create_test_account', stdout=StringIO())

        profile = user.profiles.get(name='Compte')
        self.assertEqual(profile.type.name, 'main')
        self.assertTrue(profile.is_active)
