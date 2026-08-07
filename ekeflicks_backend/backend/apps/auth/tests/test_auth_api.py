from django.urls import reverse
from django.core import mail
from django.utils import timezone
from rest_framework import status
from rest_framework.test import APITestCase

from core.models import (
    AccountClosureRequest,
    EmailChangeSupportRequest,
    EmailVerificationToken,
    PasswordResetToken,
    Profile,
    User,
    Subscription,
)


class AuthApiTests(APITestCase):
    def test_login_accepts_phone_number(self):
        User.objects.create_user(
            email='phone.viewer@example.com',
            password='StrongPass123',
            phone='+22501020304',
        )

        response = self.client.post(
            reverse('login'),
            {'email': '+225 01 02 03 04', 'password': 'StrongPass123'},
            format='json',
        )

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('access', response.data)
        self.assertIn('refresh', response.data)

    def test_register_creates_user_profile_and_tokens(self):
        self.assertEqual(reverse('register'), '/api/v1/auth/register/')
        response = self.client.post(
            reverse('register'),
            {
                'email': 'new.viewer@example.com',
                'password': 'StrongPass123',
                'firstname': 'New',
                'lastname': 'Viewer',
                'profile_name': 'Salon',
            },
            format='json',
        )

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertIn('access', response.data)
        self.assertIn('refresh', response.data)
        self.assertEqual(response.data['user']['email'], 'new.viewer@example.com')
        self.assertEqual(response.data['profile']['name'], 'Salon')

        user = User.objects.get(email='new.viewer@example.com')
        self.assertFalse(user.is_verified)
        self.assertTrue(Profile.objects.filter(user=user, name='Salon').exists())
        self.assertTrue(EmailVerificationToken.objects.filter(user=user, used_at__isnull=True).exists())
        self.assertFalse(Subscription.objects.filter(user=user).exists())
        self.assertEqual(len(mail.outbox), 2)
        self.assertIn('logo_light.png', mail.outbox[0].alternatives[0][0])

    def test_register_and_login_with_phone_without_sending_email(self):
        response = self.client.post(
            reverse('register'),
            {'phone': '+225 01 02 03 04 05', 'password': 'StrongPass123', 'firstname': 'Awa'},
            format='json',
        )

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertIsNone(response.data['user']['email'])
        self.assertEqual(response.data['user']['phone'], '+2250102030405')
        self.assertEqual(len(mail.outbox), 0)

        login = self.client.post(
            reverse('login'),
            {'email': '+2250102030405', 'password': 'StrongPass123'},
            format='json',
        )
        self.assertEqual(login.status_code, status.HTTP_200_OK)
        self.assertFalse(login.data['has_active_subscription'])

    def test_phone_registration_and_login_require_country_calling_code(self):
        registration = self.client.post(
            reverse('register'),
            {'phone': '0102030405', 'password': 'StrongPass123'},
            format='json',
        )
        self.assertEqual(registration.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('indicatif du pays', str(registration.data['phone'][0]))
        self.assertEqual(registration.data['phone'], registration.data['errors']['phone'])

        User.objects.create_user(phone='+2250102030405', password='StrongPass123')
        login = self.client.post(
            reverse('login'),
            {'email': '0102030405', 'password': 'StrongPass123'},
            format='json',
        )
        self.assertEqual(login.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('indicatif du pays', str(login.data['email'][0]))
        self.assertEqual(login.data['email'], login.data['errors']['email'])

    def test_me_requires_authentication(self):
        response = self.client.get(reverse('me'))

        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_user_can_request_and_process_account_deactivation(self):
        user = User.objects.create_user(
            email='close-me@example.com',
            password='StrongPass123',
        )
        self.client.force_authenticate(user=user)

        response = self.client.post(
            reverse('account-closure-request-list'),
            {
                'request_type': 'deactivate_account',
                'reason': 'Je veux fermer mon compte',
                'requested_for': timezone.now().isoformat(),
            },
            format='json',
        )

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        closure_request = AccountClosureRequest.objects.get(id=response.data['id'])
        self.assertEqual(closure_request.status, 'approved')

        process_response = self.client.post(
            reverse('account-closure-request-process', args=[closure_request.id]),
        )

        self.assertEqual(process_response.status_code, status.HTTP_200_OK)
        user.refresh_from_db()
        self.assertFalse(user.is_active)

    def test_email_verification_token_validates_account(self):
        user = User.objects.create_user(
            email='verify-me@example.com',
            password='StrongPass123',
        )
        token = EmailVerificationToken.objects.create(
            user=user,
            expires_at=timezone.now() + timezone.timedelta(hours=1),
        )

        response = self.client.post(
            reverse('verify-email'),
            {'token': str(token.token)},
            format='json',
        )

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        user.refresh_from_db()
        token.refresh_from_db()
        self.assertTrue(user.is_verified)
        self.assertIsNotNone(token.used_at)

    def test_password_reset_flow_changes_password(self):
        user = User.objects.create_user(
            email='reset-me@example.com',
            password='OldStrongPass123',
        )

        request_response = self.client.post(
            reverse('password-reset-request'),
            {'email': user.email},
            format='json',
        )

        self.assertEqual(request_response.status_code, status.HTTP_200_OK)
        token = PasswordResetToken.objects.get(user=user)

        confirm_response = self.client.post(
            reverse('password-reset-confirm'),
            {
                'token': str(token.token),
                'password': 'NewStrongPass123',
            },
            format='json',
        )

        self.assertEqual(confirm_response.status_code, status.HTTP_200_OK)
        user.refresh_from_db()
        token.refresh_from_db()
        self.assertTrue(user.check_password('NewStrongPass123'))
        self.assertIsNotNone(token.used_at)

    def test_personal_info_update_does_not_change_email(self):
        user = User.objects.create_user(
            email='profile-owner@example.com',
            password='StrongPass123',
            firstname='Old',
        )
        self.client.force_authenticate(user=user)

        response = self.client.patch(
            reverse('personal-info'),
            {
                'email': 'hijack@example.com',
                'firstname': 'Updated',
                'lastname': 'Name',
                'phone': '+22501020304',
                'country_code': 'CI',
            },
            format='json',
        )

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        user.refresh_from_db()
        self.assertEqual(user.email, 'profile-owner@example.com')
        self.assertEqual(user.firstname, 'Updated')
        self.assertEqual(user.phone, '+22501020304')

    def test_user_can_request_email_change_through_support(self):
        user = User.objects.create_user(
            email='current-email@example.com',
            password='StrongPass123',
        )
        staff = User.objects.create_user(
            email='support@example.com',
            password='StrongPass123',
            is_staff=True,
        )
        self.client.force_authenticate(user=user)

        response = self.client.post(
            reverse('email-change-support-request-list'),
            {
                'requested_email': 'new-email@example.com',
                'reason': 'Je n ai plus acces a mon ancien email',
            },
            format='json',
        )

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        support_request = EmailChangeSupportRequest.objects.get(id=response.data['id'])
        self.assertEqual(support_request.status, 'pending')
        self.assertEqual(support_request.user, user)

        self.client.force_authenticate(user=staff)
        resolve_response = self.client.post(
            reverse('email-change-support-request-resolve', args=[support_request.id]),
            {'reason': 'Identite verifiee par support'},
            format='json',
        )

        self.assertEqual(resolve_response.status_code, status.HTTP_200_OK)
        support_request.refresh_from_db()
        user.refresh_from_db()
        self.assertEqual(support_request.status, 'resolved')
        self.assertEqual(user.email, 'current-email@example.com')
