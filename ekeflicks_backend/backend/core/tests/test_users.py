from django.test import TestCase

from core.models import Profile, ProfileType, User


class UserModelTests(TestCase):
    def test_create_user_normalizes_email_and_sets_password(self):
        user = User.objects.create_user(
            email='TEST@Example.COM',
            password='StrongPass123',
            firstname='Test',
            lastname='User',
        )

        self.assertEqual(user.email, 'TEST@example.com')
        self.assertTrue(user.check_password('StrongPass123'))
        self.assertTrue(user.is_active)
        self.assertFalse(user.is_staff)

    def test_create_user_requires_email(self):
        with self.assertRaises(ValueError):
            User.objects.create_user(email='', password='StrongPass123')

    def test_create_superuser_sets_admin_flags(self):
        user = User.objects.create_superuser(
            email='admin@example.com',
            password='StrongPass123',
        )

        self.assertTrue(user.is_staff)
        self.assertTrue(user.is_superuser)
        self.assertTrue(user.is_active)


class ProfileSignalTests(TestCase):
    def test_default_profile_is_created_for_new_user(self):
        user = User.objects.create_user(
            email='viewer@example.com',
            password='StrongPass123',
            firstname='Viewer',
        )

        profile = Profile.objects.get(user=user)
        self.assertEqual(profile.name, 'Viewer')
        self.assertEqual(profile.type.name, 'main')
        self.assertTrue(profile.is_active)

        self.assertTrue(ProfileType.objects.filter(name='main').exists())
        self.assertTrue(ProfileType.objects.filter(name='child').exists())
        self.assertTrue(ProfileType.objects.filter(name='guest').exists())
