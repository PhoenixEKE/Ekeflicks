from django.contrib.auth.hashers import check_password, make_password
from django.utils import timezone
from rest_framework import serializers

from apps.common.serializers import get_request_user
from core.models import Profile, ProfileType, Subscription


class ProfileTypeSerializer(serializers.ModelSerializer):
    class Meta:
        model = ProfileType
        fields = [
            'id',
            'name',
            'description',
            'max_age_restriction',
            'can_create_lists',
            'can_rate_content',
        ]
        read_only_fields = ['id']


class ProfileSummarySerializer(serializers.ModelSerializer):
    type = ProfileTypeSerializer(read_only=True)

    class Meta:
        model = Profile
        fields = ['id', 'name', 'avatar_url', 'type', 'is_active']
        read_only_fields = fields


class ProfileSerializer(serializers.ModelSerializer):
    has_parental_pin = serializers.SerializerMethodField()
    type = ProfileTypeSerializer(read_only=True)
    type_id = serializers.PrimaryKeyRelatedField(
        source='type',
        queryset=ProfileType.objects.all(),
        write_only=True,
        required=False,
    )
    pin_code = serializers.CharField(
        write_only=True,
        required=False,
        allow_blank=True,
        max_length=6,
    )
    old_pin = serializers.CharField(write_only=True, required=False, max_length=6)
    parental_pin = serializers.CharField(write_only=True, required=False, max_length=6)

    class Meta:
        model = Profile
        fields = [
            'id',
            'type',
            'type_id',
            'name',
            'avatar_url',
            'age',
            'allowed_min_age',
            'allowed_max_age',
            'phone',
            'country_code',
            'pin_code',
            'old_pin',
            'parental_pin',
            'has_parental_pin',
            'adult_profiles_locked',
            'child_history_enabled',
            'safe_search_enabled',
            'is_active',
            'created_at',
            'updated_at',
        ]
        read_only_fields = ['id', 'type', 'created_at', 'updated_at']

    def get_has_parental_pin(self, obj):
        """Indique si un PIN parental est configuré pour ce profil."""
        return bool(obj.pin_code)

    def validate(self, attrs):
        user = get_request_user(self)
        name = attrs.get('name') or getattr(self.instance, 'name', None)

        # Vérification des doublons de nom
        if user and user.is_authenticated and name:
            duplicate = Profile.objects.filter(user=user, name__iexact=name)
            if self.instance:
                duplicate = duplicate.exclude(pk=self.instance.pk)
            if duplicate.exists():
                raise serializers.ValidationError({'name': 'Ce nom de profil existe deja.'})

        # Vérification que les paramètres parentaux ne sont modifiables que depuis le profil principal
        parental_fields = {
            'pin_code', 'adult_profiles_locked', 'child_history_enabled',
            'safe_search_enabled',
        }
        if parental_fields.intersection(attrs) and self.instance:
            if self.instance.type.name != 'main':
                raise serializers.ValidationError(
                    {'detail': 'Le contrôle parental se configure depuis le profil principal.'}
                )

        # Gestion du PIN parental pour les profils enfants
        new_pin = attrs.get('pin_code')
        old_pin = attrs.pop('old_pin', '')
        parental_pin = attrs.pop('parental_pin', '')

        if self.instance and self.instance.type.name == 'child':
            main_profile = Profile.objects.filter(user=user, type__name='main').first()
            if not main_profile or not main_profile.pin_code:
                raise serializers.ValidationError(
                    {'parental_pin': 'Configurez d’abord un PIN sur le profil principal.'}
                )
            if not check_password(parental_pin, main_profile.pin_code):
                raise serializers.ValidationError(
                    {'parental_pin': 'Le PIN parental est obligatoire et doit être correct.'}
                )

        # Validation des plages d'âge
        minimum = attrs.get('allowed_min_age', getattr(self.instance, 'allowed_min_age', 0))
        maximum = attrs.get('allowed_max_age', getattr(self.instance, 'allowed_max_age', 13))
        if minimum > maximum:
            raise serializers.ValidationError(
                {'allowed_max_age': 'L’âge maximal doit être supérieur ou égal à l’âge minimal.'}
            )

        # Validation de l'ancien PIN pour la modification du PIN parental
        if new_pin and self.instance and self.instance.pin_code:
            if not check_password(old_pin, self.instance.pin_code):
                raise serializers.ValidationError(
                    {'old_pin': 'L’ancien PIN est obligatoire et doit être correct.'}
                )

        return attrs

    def validate_pin_code(self, value):
        """Valide et hache le code PIN."""
        if value and (not value.isdigit() or not 4 <= len(value) <= 6):
            raise serializers.ValidationError('Le PIN doit contenir entre 4 et 6 chiffres.')
        return make_password(value) if value else ''

    def validate_allowed_min_age(self, value):
        """Valide l'âge minimal autorisé."""
        if value < 0 or value > 18:
            raise serializers.ValidationError('L’âge minimal doit être compris entre 0 et 18 ans.')
        return value

    def validate_allowed_max_age(self, value):
        """Valide l'âge maximal autorisé."""
        if value < 0 or value > 18:
            raise serializers.ValidationError('L’âge maximal doit être compris entre 0 et 18 ans.')
        return value

    def create(self, validated_data):
        user = get_request_user(self)
        if not user or not user.is_authenticated:
            raise serializers.ValidationError("Authentification requise.")

        # Vérification de la limite de profils en fonction de l'abonnement
        subscription = (
            Subscription.objects.filter(
                user=user,
                status='active',
                expires_at__gt=timezone.now(),
            )
            .select_related('plan')
            .order_by('-expires_at')
            .first()
        )
        profile_limit = max(subscription.plan.max_devices, 1) if subscription else 1
        active_profiles = Profile.objects.filter(user=user, is_active=True).count()

        if active_profiles >= profile_limit:
            raise serializers.ValidationError({
                'detail': (
                    f'Votre offre autorise {profile_limit} profil(s), profil principal inclus. '
                    'Augmentez le nombre d’appareils simultanés pour créer un autre profil.'
                )
            })

        # Création du profil principal par défaut si aucun type n'est spécifié
        if 'type' not in validated_data:
            profile_type, _ = ProfileType.objects.get_or_create(
                name='main',
                defaults={
                    'description': 'Profil principal',
                    'can_create_lists': True,
                    'can_rate_content': True,
                },
            )
            validated_data['type'] = profile_type

        return Profile.objects.create(user=user, **validated_data)
