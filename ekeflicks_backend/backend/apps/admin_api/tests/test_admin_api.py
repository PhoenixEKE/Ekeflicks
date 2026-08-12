from django.utils import timezone
from rest_framework.test import APITestCase

from apps.admin_api.security import totp
from core.models.users import AdminMFADevice, User, UserSession


class AdminSecurityApiTests(APITestCase):
    def setUp(self):
        self.admin = User.objects.create_superuser('root@example.com', 'strong-password')
        self.device = AdminMFADevice.objects.create(user=self.admin, confirmed_at=timezone.now())

    def login(self):
        return self.client.post('/api/v1/admin/auth/login/', {
            'email': self.admin.email,
            'password': 'strong-password',
            'otp': totp(self.device.secret),
            'device_id': 'test-browser',
        }, format='json')

    def test_admin_login_requires_mfa_and_creates_revocable_session(self):
        invalid = self.client.post('/api/v1/admin/auth/login/', {
            'email': self.admin.email, 'password': 'strong-password', 'otp': '000000',
        }, format='json')
        self.assertEqual(invalid.status_code, 401)
        response = self.login()
        self.assertEqual(response.status_code, 200)
        self.assertTrue(UserSession.objects.get(pk=response.data['session_id']).is_active)

    def test_refresh_rotates_session_and_rejects_replay(self):
        login = self.login()
        response = self.client.post('/api/v1/admin/auth/refresh/', {'refresh': login.data['refresh']}, format='json')
        self.assertEqual(response.status_code, 200)
        self.assertFalse(UserSession.objects.get(pk=login.data['session_id']).is_active)
        replay = self.client.post('/api/v1/admin/auth/refresh/', {'refresh': login.data['refresh']}, format='json')
        self.assertEqual(replay.status_code, 401)

    def test_superadmin_can_create_role_and_assign_it(self):
        login = self.login()
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {login.data['access']}")
        role = self.client.post('/api/v1/admin/roles/', {'name': 'Support', 'permissions': []}, format='json')
        self.assertEqual(role.status_code, 201)
        support = User.objects.create_user('support@example.com', 'strong-password')
        assigned = self.client.put(f'/api/v1/admin/users/{support.pk}/roles/', {'role_ids': [role.data['id']]}, format='json')
        self.assertEqual(assigned.status_code, 200)
        support.refresh_from_db()
        self.assertTrue(support.is_staff)
        self.assertEqual(list(support.groups.values_list('name', flat=True)), ['Support'])
