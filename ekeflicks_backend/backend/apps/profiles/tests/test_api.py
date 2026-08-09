from django.contrib.auth.hashers import check_password, make_password
from django.core import mail
from django.urls import reverse
from django.utils import timezone
from rest_framework import status
from rest_framework.test import APITestCase

from core.models import Profile, ProfileType, Subscription, SubscriptionPlan, User


class ProfileApiTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            email='owner@example.com',
            password='StrongPass123',
            firstname='Owner',
        )
        self.other_user = User.objects.create_user(
            email='other@example.com',
            password='StrongPass123',
            firstname='Other',
        )
        self.profile = Profile.objects.get(user=self.user)

    def test_profiles_require_authentication(self):
        response = self.client.get(reverse('profile-list'))

        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_profiles_are_limited_to_current_user(self):
        self.client.force_authenticate(user=self.user)

        response = self.client.get(reverse('profile-list'))

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        payload = response.data['results'] if 'results' in response.data else response.data
        self.assertEqual(len(payload), 1)
        self.assertEqual(payload[0]['id'], str(self.profile.id))

    def test_simultaneous_devices_define_profile_creation_limit(self):
        """
        Test que la limite de création de profils est définie par le nombre
        d'appareils simultanés autorisés par l'abonnement.
        """
        child_type, _ = ProfileType.objects.get_or_create(name='child')
        plan = SubscriptionPlan.objects.create(
            name='Deux écrans',
            slug='deux-ecrans',
            price=10,
            duration_days=30,
            max_devices=2,
        )
        Subscription.objects.create(
            user=self.user,
            plan=plan,
            status='active',
            expires_at=timezone.now() + timezone.timedelta(days=30),
        )
        self.client.force_authenticate(user=self.user)

        # Vérifier la capacité
        capacity = self.client.get(reverse('profile-capacity'))
        self.assertEqual(capacity.data['profile_limit'], 2)
        self.assertEqual(capacity.data['profiles_used'], 1)

        # Premier profil enfant - doit réussir
        first = self.client.post(
            reverse('profile-list'),
            {'name': 'Enfant', 'type_id': child_type.pk},
            format='json',
        )
        self.assertEqual(first.status_code, status.HTTP_201_CREATED)

        # Deuxième profil - doit échouer car limite atteinte
        second = self.client.post(
            reverse('profile-list'),
            {'name': 'Invité', 'type_id': child_type.pk},
            format='json',
        )
        self.assertEqual(second.status_code, status.HTTP_400_BAD_REQUEST)

    def test_parental_pin_is_hashed_and_required_to_unlock_adult_profile(self):
        """
        Test complet du cycle de vie du PIN parental :
        - Hachage du PIN à la création/modification
        - Vérification du PIN pour déverrouiller un profil adulte
        - Validation de l'ancien PIN pour modifier le PIN
        """
        self.client.force_authenticate(user=self.user)
        detail_url = reverse('profile-detail', kwargs={'pk': self.profile.pk})

        # 1. Création du PIN parental
        response = self.client.patch(
            detail_url,
            {'pin_code': '2468', 'adult_profiles_locked': True},
            format='json',
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.profile.refresh_from_db()

        # Vérification que le PIN est haché et non stocké en clair
        self.assertNotEqual(self.profile.pin_code, '2468')
        self.assertTrue(check_password('2468', self.profile.pin_code))

        # 2. Vérification du PIN pour déverrouiller un profil adulte
        verify_url = reverse('profile-verify-pin', kwargs={'pk': self.profile.pk})

        # 2.1. Requête sans PIN - retourne que le PIN est requis
        required = self.client.post(verify_url, {}, format='json')
        self.assertEqual(required.data, {'verified': False, 'pin_required': True})

        # 2.2. PIN incorrect - accès refusé (403)
        denied = self.client.post(verify_url, {'pin': '0000'}, format='json')
        self.assertEqual(denied.status_code, status.HTTP_403_FORBIDDEN)

        # 2.3. PIN correct - accès autorisé
        allowed = self.client.post(verify_url, {'pin': '2468'}, format='json')
        self.assertEqual(allowed.data, {'verified': True, 'pin_required': True})

        # 3. Modification du PIN parental

        # 3.1. Sans l'ancien PIN - erreur
        missing_old = self.client.patch(detail_url, {'pin_code': '1357'}, format='json')
        self.assertEqual(missing_old.status_code, status.HTTP_400_BAD_REQUEST)

        # 3.2. Avec un ancien PIN incorrect - erreur
        wrong_old = self.client.patch(
            detail_url, {'pin_code': '1357', 'old_pin': '0000'}, format='json'
        )
        self.assertEqual(wrong_old.status_code, status.HTTP_400_BAD_REQUEST)

        # 3.3. Avec l'ancien PIN correct - succès
        changed = self.client.patch(
            detail_url, {'pin_code': '1357', 'old_pin': '2468'}, format='json'
        )
        self.assertEqual(changed.status_code, status.HTTP_200_OK)
        self.profile.refresh_from_db()
        self.assertTrue(check_password('1357', self.profile.pin_code))

    def test_parental_pin_reset_uses_host_safe_link_and_embedded_logo(self):
        """
        Test que la réinitialisation du PIN parental utilise un lien compatible
        avec les hébergements partagés et que le logo est intégré dans l'email.
        """
        self.client.force_authenticate(user=self.user)

        response = self.client.post(
            reverse('profile-request-pin-reset', kwargs={'pk': self.profile.pk}),
            format='json',
        )

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(mail.outbox), 1)

        message = mail.outbox[0]

        # Vérifier que le lien utilise le format query string (compatible hébergements partagés)
        self.assertIn('/?action=reset-parental-pin&amp;token=', message.alternatives[0][0])

        # Vérifier que le logo est intégré en CID
        self.assertIn('cid:logo_light.png', message.alternatives[0][0])

        # Vérifier que le logo est attaché à l'email
        self.assertTrue(
            any(
                attachment.get('Content-ID') == '<logo_light.png>'
                for attachment in message.attachments
            )
        )

    def test_child_profile_changes_require_parental_pin(self):
        """
        Test que les modifications d'un profil enfant nécessitent un PIN parental.
        """
        child_type, _ = ProfileType.objects.get_or_create(name='child')
        child = Profile.objects.create(
            user=self.user,
            type=child_type,
            name='Enfant',
        )

        # Configurer le PIN parental sur le profil principal
        self.profile.pin_code = make_password('2468')
        self.profile.save(update_fields=['pin_code'])

        self.client.force_authenticate(user=self.user)
        url = reverse('profile-detail', kwargs={'pk': child.pk})

        # 1. Modification sans PIN parental - erreur
        missing = self.client.patch(url, {'name': 'Junior'}, format='json')
        self.assertEqual(missing.status_code, status.HTTP_400_BAD_REQUEST)

        # 2. Modification avec PIN incorrect - erreur
        wrong = self.client.patch(
            url,
            {'name': 'Junior', 'parental_pin': '0000'},
            format='json',
        )
        self.assertEqual(wrong.status_code, status.HTTP_400_BAD_REQUEST)

        # 3. Modification avec PIN correct - succès
        allowed = self.client.patch(
            url,
            {
                'name': 'Junior',
                'parental_pin': '2468',
                'allowed_min_age': 3,
                'allowed_max_age': 12,
            },
            format='json',
        )
        self.assertEqual(allowed.status_code, status.HTTP_200_OK)

        # Vérifier que les modifications ont été appliquées
        child.refresh_from_db()
        self.assertEqual(child.name, 'Junior')
        self.assertEqual(child.allowed_min_age, 3)
        self.assertEqual(child.allowed_max_age, 12)
