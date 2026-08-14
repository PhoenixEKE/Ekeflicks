from django.utils import timezone
from datetime import timedelta
from decimal import Decimal
from django.contrib.auth.models import Group
from rest_framework.test import APITestCase
from rest_framework_simplejwt.tokens import RefreshToken

from apps.admin_api.security import totp
from core.models.content import Content
from core.models.streaming import VideoAsset
from core.models.profiles import Profile, ProfileType
from core.models.subscriptions import ProducerPayoutRequest, Subscription, SubscriptionPlan
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

    def test_regular_staff_session_cannot_enter_admin_api(self):
        session = UserSession.objects.create(
            user=self.admin, device_type='web', expires_at=timezone.now() + timedelta(hours=1),
        )
        access = RefreshToken.for_user(self.admin).access_token
        access['sid'] = session.pk
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {access}')
        response = self.client.get('/api/v1/admin/users/')
        self.assertEqual(response.status_code, 403)

    def test_refresh_is_rejected_after_staff_access_is_removed(self):
        login = self.login()
        self.admin.is_staff = False
        self.admin.save(update_fields=['is_staff'])
        response = self.client.post('/api/v1/admin/auth/refresh/', {'refresh': login.data['refresh']}, format='json')
        self.assertEqual(response.status_code, 401)

    def test_superadmin_can_create_role_and_assign_it(self):
        login = self.login()
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {login.data['access']}")
        role = self.client.post('/api/v1/admin/roles/', {'name': 'Auditeur', 'permissions': []}, format='json')
        self.assertEqual(role.status_code, 201)
        support = User.objects.create_user('support@example.com', 'strong-password')
        assigned = self.client.put(f'/api/v1/admin/users/{support.pk}/roles/', {'role_ids': [role.data['id']]}, format='json')
        self.assertEqual(assigned.status_code, 200)
        support.refresh_from_db()
        self.assertTrue(support.is_staff)
        self.assertEqual(list(support.groups.values_list('name', flat=True)), ['Auditeur'])

    def test_custom_role_can_be_deleted_but_base_role_is_protected(self):
        login = self.login()
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {login.data['access']}")
        role = self.client.post('/api/v1/admin/roles/', {'name': 'Temporaire'}, format='json')
        deleted = self.client.delete(f"/api/v1/admin/roles/{role.data['id']}/")
        base = Group.objects.get(name='Support')
        protected = self.client.delete(f'/api/v1/admin/roles/{base.pk}/')
        self.assertEqual(deleted.status_code, 204)
        self.assertEqual(protected.status_code, 400)
        self.assertTrue(Group.objects.filter(pk=base.pk).exists())

    def test_superadmin_creates_staff_with_fixed_role_and_mfa_enrollment(self):
        login = self.login()
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {login.data['access']}")
        response = self.client.post('/api/v1/admin/users/staff/', {
            'email': 'moderator@example.com',
            'password': 'A-very-strong-password-2026!',
            'role': 'Modérateur',
        }, format='json')
        self.assertEqual(response.status_code, 201)
        self.assertTrue(response.data['mfa_provisioning_uri'].startswith('otpauth://totp/'))
        moderator = User.objects.get(email='moderator@example.com')
        self.assertTrue(moderator.is_staff)
        self.assertEqual(list(moderator.groups.values_list('name', flat=True)), ['Modérateur'])
        self.assertIsNone(moderator.admin_mfa_device.confirmed_at)

    def test_new_staff_can_confirm_mfa_enrollment(self):
        staff = User.objects.create_user('support@example.com', 'strong-password', is_staff=True)
        staff.groups.add(Group.objects.get(name='Support'))
        device = AdminMFADevice.objects.create(user=staff)
        response = self.client.post('/api/v1/admin/auth/mfa/confirm/', {
            'email': staff.email, 'password': 'strong-password', 'otp': totp(device.secret),
        }, format='json')
        self.assertEqual(response.status_code, 200)
        device.refresh_from_db()
        self.assertIsNotNone(device.confirmed_at)

    def test_non_superadmin_cannot_create_staff(self):
        moderator = User.objects.create_user('moderator@example.com', 'strong-password', is_staff=True)
        moderator.groups.add(Group.objects.get(name='Modérateur'))
        device = AdminMFADevice.objects.create(user=moderator, confirmed_at=timezone.now())
        response = self.client.post('/api/v1/admin/auth/login/', {
            'email': moderator.email, 'password': 'strong-password', 'otp': totp(device.secret),
        }, format='json')
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {response.data['access']}")
        denied = self.client.post('/api/v1/admin/users/staff/', {
            'email': 'finance@example.com', 'password': 'A-very-strong-password-2026!', 'role': 'Finance',
        }, format='json')
        self.assertEqual(denied.status_code, 403)

    def test_moderator_can_validate_content_and_video_deposits(self):
        moderator = User.objects.create_user('moderator@example.com', 'strong-password', is_staff=True)
        moderator.groups.add(Group.objects.get(name='Modérateur'))
        device = AdminMFADevice.objects.create(user=moderator, confirmed_at=timezone.now())
        producer = User.objects.create_user('producer@example.com', 'strong-password', is_producer=True)
        content = Content.objects.create(title='Dépôt test', type='movie', producer=producer,
                                         producer_submission_status='pending')
        asset = VideoAsset.objects.create(content=content, moderation_status='pending')
        login = self.client.post('/api/v1/admin/auth/login/', {
            'email': moderator.email, 'password': 'strong-password', 'otp': totp(device.secret),
        }, format='json')
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {login.data['access']}")
        content_response = self.client.post(f'/api/v1/admin/contents/{content.pk}/review/', {
            'decision': 'approved',
        }, format='json')
        video_response = self.client.post(f'/api/v1/admin/videos/{asset.pk}/review/', {
            'decision': 'approved',
        }, format='json')
        self.assertEqual(content_response.status_code, 200)
        self.assertEqual(video_response.status_code, 200)
        content.refresh_from_db()
        asset.refresh_from_db()
        self.assertEqual(content.producer_submission_status, 'approved')
        self.assertEqual(asset.moderation_status, 'approved')

    def test_default_roles_are_seeded_with_least_privilege_permissions(self):
        support = Group.objects.get(name='Support')
        moderator = Group.objects.get(name='Modérateur')
        finance = Group.objects.get(name='Finance')
        self.assertTrue(support.permissions.filter(codename='view_accountclosurerequest').exists())
        self.assertFalse(support.permissions.filter(codename='view_payment').exists())
        self.assertTrue(moderator.permissions.filter(codename='change_content').exists())
        self.assertTrue(moderator.permissions.filter(codename='change_user').exists())
        self.assertTrue(finance.permissions.filter(codename='view_payment').exists())
        self.assertFalse(finance.permissions.filter(codename='change_content').exists())

    def test_user_detail_returns_subscription_profiles_and_activity(self):
        customer = User.objects.create_user('customer@example.com', 'strong-password')
        profile_type = ProfileType.objects.create(name='Principal')
        Profile.objects.create(user=customer, type=profile_type, name='Jean')
        plan = SubscriptionPlan.objects.create(name='Premium', slug='premium-test', price=10,
                                               duration_days=30)
        Subscription.objects.create(user=customer, plan=plan, expires_at=timezone.now() + timedelta(days=30))
        login = self.login()
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {login.data['access']}")
        response = self.client.get(f'/api/v1/admin/users/{customer.pk}/')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data['subscription']['plan'], 'Premium')
        self.assertEqual(response.data['profiles'][0]['name'], 'Jean')
        self.assertIn('watch_seconds', response.data['activity'])

    def test_user_search_accepts_phone_and_country(self):
        customer = User.objects.create_user(
            'search@example.com', 'strong-password', phone='+2250701020304', country_code='CI',
        )
        login = self.login()
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {login.data['access']}")
        by_phone = self.client.get('/api/v1/admin/users/?kind=customer&search=070102')
        by_country = self.client.get('/api/v1/admin/users/?kind=customer&search=CI')
        self.assertEqual(by_phone.data['results'][0]['id'], str(customer.pk))
        self.assertEqual(by_country.data['results'][0]['id'], str(customer.pk))

    def test_subscription_accounting_list_returns_rows_and_statistics(self):
        customer = User.objects.create_user('subscriber@example.com', 'strong-password')
        plan = SubscriptionPlan.objects.create(
            name='Essentiel', slug='essential-admin-test', price=7, duration_days=30,
        )
        subscription = Subscription.objects.create(
            user=customer, plan=plan, expires_at=timezone.now() + timedelta(days=30),
        )
        from core.models.subscriptions import Payment
        Payment.objects.create(subscription=subscription, amount=7, status='success')
        login = self.login()
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {login.data['access']}")
        response = self.client.get('/api/v1/admin/subscriptions/?search=subscriber')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data['results'][0]['email'], customer.email)
        self.assertEqual(response.data['statistics']['by_status']['active'], 1)
        self.assertEqual(response.data['statistics']['successful_revenue'], Decimal('7'))

    def test_producer_detail_returns_content_and_revenue_aggregates(self):
        producer = User.objects.create_user('producer-detail@example.com', 'strong-password', is_producer=True)
        Content.objects.create(title='Film validé', type='movie', producer=producer,
                               producer_submission_status='approved', view_count=125)
        ProducerPayoutRequest.objects.create(producer=producer, amount_eur=250, status='paid',
                                             paid_at=timezone.now())
        login = self.login()
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {login.data['access']}")
        response = self.client.get(f'/api/v1/admin/users/{producer.pk}/')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data['producer_statistics']['approved'], 1)
        self.assertEqual(response.data['producer_statistics']['total_views'], 125)
        self.assertEqual(len(response.data['recent_contents']), 1)
        self.assertEqual(response.data['revenues']['total'], Decimal('250'))

    def test_dashboard_returns_dynamic_stats_activity_and_alerts(self):
        customer = User.objects.create_user('recent@example.com', 'strong-password')
        producer = User.objects.create_user('suspended@example.com', 'strong-password',
                                            is_producer=True, is_active=False)
        Content.objects.create(title='Film dashboard', type='movie', producer=producer,
                               producer_submission_status='pending', submitted_at=timezone.now())
        login = self.login()
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {login.data['access']}")
        response = self.client.get('/api/v1/admin/dashboard/')
        self.assertEqual(response.status_code, 200)
        self.assertGreaterEqual(response.data['stats']['users'], 2)
        self.assertGreaterEqual(response.data['stats']['pending_moderation'], 1)
        self.assertTrue(any(row['message'] == customer.email for row in response.data['recent_activity']))
        suspended = next(row for row in response.data['alerts'] if row['type'] == 'producers')
        self.assertEqual(suspended['count'], 1)

    def test_admin_action_creates_admin_notifications_and_marks_them_read(self):
        customer = User.objects.create_user('notify@example.com', 'strong-password')
        login = self.login()
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {login.data['access']}")
        changed = self.client.patch(f'/api/v1/admin/users/{customer.pk}/status/',
                                    {'is_active': False}, format='json')
        self.assertEqual(changed.status_code, 200)
        notifications = self.client.get('/api/v1/admin/notifications/')
        self.assertEqual(notifications.status_code, 200)
        self.assertGreaterEqual(notifications.data['unread'], 1)
        marked = self.client.post('/api/v1/admin/notifications/', {}, format='json')
        self.assertGreaterEqual(marked.data['updated'], 1)

    def test_payout_requires_two_distinct_finance_approvers_and_reauthentication(self):
        producer = User.objects.create_user('payout-detail@example.com', 'strong-password', is_producer=True)
        payout = ProducerPayoutRequest.objects.create(producer=producer, amount_eur=100,
                                                      amount_local=100, status='pending')
        login = self.login()
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {login.data['access']}")
        approved = self.client.post(f'/api/v1/admin/payouts/{payout.pk}/approve/',
                                    {'reason': 'Contrôle initial'}, format='json')
        self.assertEqual(approved.status_code, 200)
        same_agent = self.client.post(f'/api/v1/admin/payouts/{payout.pk}/mark-paid/', {
            'reason': 'Paiement', 'password': 'strong-password',
        }, format='json')
        self.assertEqual(same_agent.status_code, 403)

        finance = User.objects.create_user('finance@example.com', 'finance-strong-password', is_staff=True)
        finance.groups.add(Group.objects.get(name='Finance'))
        device = AdminMFADevice.objects.create(user=finance, confirmed_at=timezone.now())
        finance_login = self.client.post('/api/v1/admin/auth/login/', {
            'email': finance.email, 'password': 'finance-strong-password', 'otp': totp(device.secret),
        }, format='json')
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {finance_login.data['access']}")
        paid = self.client.post(f'/api/v1/admin/payouts/{payout.pk}/mark-paid/', {
            'reason': 'Virement confirmé', 'password': 'finance-strong-password',
        }, format='json')
        self.assertEqual(paid.status_code, 200)
        self.assertEqual(paid.data['status'], 'paid')

    def test_payout_rejects_stale_concurrent_decision(self):
        producer = User.objects.create_user('payout-race@example.com', 'strong-password', is_producer=True)
        payout = ProducerPayoutRequest.objects.create(producer=producer, amount_eur=100,
                                                      amount_local=100, status='pending')
        login = self.login()
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {login.data['access']}")
        first = self.client.post(f'/api/v1/admin/payouts/{payout.pk}/approve/', {}, format='json')
        stale = self.client.post(f'/api/v1/admin/payouts/{payout.pk}/reject/',
                                 {'reason': 'Décision tardive'}, format='json')
        self.assertEqual(first.status_code, 200)
        self.assertEqual(stale.status_code, 409)
