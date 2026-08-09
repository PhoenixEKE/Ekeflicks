from django.conf import settings
from django.contrib.auth.hashers import check_password, make_password
from django.utils import timezone
from rest_framework import decorators, exceptions, filters, permissions, response, status, viewsets

from apps.common.permissions import IsAdminOrReadOnly
from apps.notifications.services import notify_user
from apps.profiles.serializers import ProfileSerializer, ProfileTypeSerializer
from core.models import ParentalPinResetToken, Profile, ProfileType, Subscription, User


class ProfileTypeViewSet(viewsets.ModelViewSet):
    queryset = ProfileType.objects.all().order_by('name')
    serializer_class = ProfileTypeSerializer
    permission_classes = [IsAdminOrReadOnly]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['name', 'description']
    ordering_fields = ['name']
    ordering = ['name']


class ProfileViewSet(viewsets.ModelViewSet):
    serializer_class = ProfileSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return (
            Profile.objects.filter(user=self.request.user, is_active=True)
            .select_related('type')
            .order_by('-is_active', 'created_at')
        )

    def perform_destroy(self, instance):
        """
        Supprime un profil (soft delete) avec vérification du PIN parental.
        """
        # Empêcher la suppression du profil principal
        if instance.type.name == 'main':
            raise exceptions.PermissionDenied(
                'Le profil principal ne peut pas être supprimé.'
            )

        # Vérifier que la requête provient du profil principal
        active_profile_id = self.request.headers.get('x-profile-id')
        active_profile = self.get_queryset().filter(pk=active_profile_id).first()
        if not active_profile or active_profile.type.name != 'main':
            raise exceptions.PermissionDenied(
                'La suppression est réservée au profil principal.'
            )

        # Vérifier le PIN parental
        main_profile = self.get_queryset().filter(type__name='main').first()
        pin = str(self.request.data.get('parental_pin', ''))
        if main_profile and main_profile.pin_code and not check_password(pin, main_profile.pin_code):
            raise exceptions.PermissionDenied('PIN parental incorrect.')

        # Soft delete
        instance.is_active = False
        instance.save(update_fields=['is_active', 'updated_at'])

    @decorators.action(detail=False, methods=['get'], url_path='capacity')
    def capacity(self, request):
        """
        Retourne la capacité de profils en fonction de l'abonnement.
        """
        subscription = (
            Subscription.objects.filter(
                user=request.user,
                status='active',
                expires_at__gt=timezone.now(),
            )
            .select_related('plan')
            .order_by('-expires_at')
            .first()
        )
        limit = max(subscription.plan.max_devices, 1) if subscription else 1
        used = self.get_queryset().count()
        return response.Response({
            'profile_limit': limit,
            'profiles_used': used,
            'profiles_remaining': max(limit - used, 0),
            'can_create': used < limit,
            'source': 'simultaneous_devices_allowed',
        })

    @decorators.action(detail=True, methods=['post'], url_path='verify-pin')
    def verify_pin(self, request, pk=None):
        """
        Vérifie le PIN parental pour accéder à un profil adulte.
        Ne retourne jamais le hash du PIN.
        """
        profile = self.get_object()
        main_profile = self.get_queryset().filter(type__name='main').first()

        # Si le verrouillage des profils adultes n'est pas activé
        if not main_profile or not main_profile.adult_profiles_locked:
            return response.Response({'verified': True, 'pin_required': False})

        pin = str(request.data.get('pin', ''))
        if not pin:
            return response.Response({'verified': False, 'pin_required': True})

        # Vérification du PIN avec check_password (hachage sécurisé)
        if not check_password(pin, main_profile.pin_code):
            return response.Response(
                {'verified': False, 'pin_required': True, 'detail': 'PIN incorrect.'},
                status=status.HTTP_403_FORBIDDEN,
            )

        return response.Response({'verified': True, 'pin_required': True})

    @decorators.action(detail=True, methods=['post'], url_path='request-pin-reset')
    def request_pin_reset(self, request, pk=None):
        """
        Demande une réinitialisation du PIN parental.
        Envoie un lien par email avec un token valide 30 minutes.
        """
        profile = self.get_object()

        # Seul le profil principal peut réinitialiser le PIN parental
        if profile.type.name != 'main':
            return response.Response({'detail': 'Profil principal requis.'}, status=403)

        email = str(request.data.get('email') or request.user.email or '').strip().lower()
        if not email:
            return response.Response({'email': 'Une adresse e-mail est obligatoire.'}, status=400)

        # Vérifier que l'email n'est pas déjà utilisé par un autre utilisateur
        if User.objects.exclude(pk=request.user.pk).filter(email__iexact=email).exists():
            return response.Response({'email': 'Cette adresse e-mail est déjà utilisée.'}, status=400)

        # Mettre à jour l'email si différent
        if request.user.email != email:
            request.user.email = email
            request.user.is_verified = False
            request.user.save(update_fields=['email', 'is_verified', 'updated_at'])

        # Créer le token de réinitialisation
        token = ParentalPinResetToken.objects.create(
            profile=profile,
            expires_at=timezone.now() + timezone.timedelta(minutes=30),
        )

        # Construire le lien de réinitialisation
        # Utilisation du format query string pour éviter les problèmes de routage
        # sur les hébergements partagés qui ne redirigent pas les chemins arbitraires
        # vers index.html de Flutter.
        base = settings.FRONTEND_BASE_URL.rstrip('/')
        link = (
            f'{base}/?action=reset-parental-pin&token={token.token}'
            f'&profile={profile.pk}'
        )

        # Envoyer la notification par email
        notify_user(
            request.user,
            'parental_pin_reset',
            title='Réinitialiser votre PIN parental EkeFlicks',
            message=f'Utilisez ce lien dans les 30 minutes pour modifier votre PIN : {link}',
            data={'parental_pin_reset_link': link},
        )

        return response.Response({'detail': 'Lien envoyé par e-mail.'})

    @decorators.action(detail=True, methods=['post'], url_path='confirm-pin-reset')
    def confirm_pin_reset(self, request, pk=None):
        """
        Confirme la réinitialisation du PIN parental avec le token reçu par email.
        """
        profile = self.get_object()

        # Recherche du token valide (non utilisé et non expiré)
        token = ParentalPinResetToken.objects.filter(
            profile=profile,
            token=request.data.get('token'),
            used_at__isnull=True,
            expires_at__gt=timezone.now(),
        ).first()

        new_pin = str(request.data.get('new_pin', ''))

        # Vérification du token
        if not token:
            return response.Response({'detail': 'Lien invalide ou expiré.'}, status=400)

        # Validation du nouveau PIN
        if not new_pin.isdigit() or not 4 <= len(new_pin) <= 6:
            return response.Response(
                {'new_pin': 'Le PIN doit contenir 4 à 6 chiffres.'},
                status=400
            )

        # Mise à jour du PIN (hachage)
        profile.pin_code = make_password(new_pin)
        profile.save(update_fields=['pin_code', 'updated_at'])

        # Marquer le token comme utilisé
        token.used_at = timezone.now()
        token.save(update_fields=['used_at', 'updated_at'])

        return response.Response({'detail': 'PIN parental modifié.'})
