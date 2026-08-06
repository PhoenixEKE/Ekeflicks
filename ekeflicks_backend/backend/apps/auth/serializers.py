import hashlib
import uuid

from rest_framework import serializers
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from core.models.users import AccountClosureRequest, EmailChangeSupportRequest, User
from core.models.profiles import Profile, ProfileType


PHONE_ACCOUNT_EMAIL_DOMAIN = '@users.ekeflicks.invalid'


def normalize_phone(value):
    """Return the compact international representation used for authentication."""
    value = value.strip()
    prefix = '+' if value.startswith('+') else ''
    digits = ''.join(character for character in value if character.isdigit())
    return f'{prefix}{digits}'


def phone_account_email(phone):
    """Build a non-routable internal identifier for accounts without email."""
    digest = hashlib.sha256(phone.encode('utf-8')).hexdigest()
    return f'phone-{digest}@accounts.ekeflicks.invalid'


def public_email(user):
    """Hide the internal identifier used for accounts created by phone."""
    return '' if user.email and user.email.endswith(PHONE_ACCOUNT_EMAIL_DOMAIN) else user.email


class LoginSerializer(TokenObtainPairSerializer):
    # SimpleJWT names this field after User.USERNAME_FIELD (email). Keep the
    # wire format backward compatible while also accepting a phone number.
    email = serializers.CharField(required=True, trim_whitespace=True)

    def validate(self, attrs):
        identifier = attrs.get('email', '').strip()
        if '@' in identifier:
            attrs['email'] = identifier.lower()
        else:
            phone = normalize_phone(identifier)
            matches = User.objects.filter(phone=phone, is_active=True).values_list(
                'email', flat=True
            )[:2]
            emails = list(matches)
            if len(emails) == 1:
                attrs['email'] = emails[0]

        return super().validate(attrs)


class UserSerializer(serializers.ModelSerializer):
    email = serializers.SerializerMethodField()

    def get_email(self, obj):
        return public_email(obj)

    class Meta:
        model = User
        fields = [
            'id',
            'email',
            'firstname',
            'lastname',
            'phone',
            'country_code',
            'is_active',
            'is_verified',
            'is_producer',
            'producer_company',
            'created_at',
        ]
        read_only_fields = ['id', 'email', 'is_active', 'is_verified', 'is_producer', 'created_at']


class UserPersonalInfoSerializer(serializers.ModelSerializer):
    email = serializers.SerializerMethodField()

    def get_email(self, obj):
        return public_email(obj)

    class Meta:
        model = User
        fields = ['id', 'email', 'firstname', 'lastname', 'phone', 'country_code', 'is_verified', 'created_at']
        read_only_fields = ['id', 'email', 'is_verified', 'created_at']

    def validate_phone(self, value):
        return normalize_phone(value)


class EmailVerificationSerializer(serializers.Serializer):
    token = serializers.UUIDField(required=True)


class PasswordResetRequestSerializer(serializers.Serializer):
    email = serializers.EmailField(required=True)


class PasswordResetConfirmSerializer(serializers.Serializer):
    token = serializers.UUIDField(required=True)
    password = serializers.CharField(required=True, write_only=True, min_length=8)


class EmailChangeSupportRequestSerializer(serializers.ModelSerializer):
    user_email = serializers.EmailField(source='user.email', read_only=True)

    class Meta:
        model = EmailChangeSupportRequest
        fields = [
            'id',
            'user',
            'user_email',
            'requested_email',
            'reason',
            'status',
            'admin_reason',
            'reviewed_by',
            'reviewed_at',
            'created_at',
            'updated_at',
        ]
        read_only_fields = [
            'id',
            'user',
            'user_email',
            'status',
            'admin_reason',
            'reviewed_by',
            'reviewed_at',
            'created_at',
            'updated_at',
        ]

    def validate_requested_email(self, value):
        requested_email = value.strip().lower()
        request = self.context.get('request')
        current_user = getattr(request, 'user', None)

        if current_user and current_user.is_authenticated:
            if current_user.email and requested_email == current_user.email.lower():
                raise serializers.ValidationError('Le nouvel email doit etre different de votre email actuel.')

        if User.objects.filter(email__iexact=requested_email).exists():
            raise serializers.ValidationError('Cet email est deja utilise.')

        return requested_email


class UserCreateSerializer(serializers.ModelSerializer):
    email = serializers.EmailField(required=False, allow_blank=True)
    password = serializers.CharField(write_only=True, min_length=8)
    avatar_url = serializers.URLField(required=False, allow_blank=True, allow_null=True)
    profile_name = serializers.CharField(required=False, allow_blank=True)
    profile_type = serializers.CharField(required=False, default='main')

    class Meta:
        model = User
        fields = ['email', 'password', 'firstname', 'lastname', 'phone', 'country_code', 'avatar_url', 'profile_name', 'profile_type']

    def validate_phone(self, value):
        return normalize_phone(value)

    def validate(self, attrs):
        email = attrs.get('email', '').strip().lower()
        phone = attrs.get('phone', '').strip()

        if not email and not phone:
            raise serializers.ValidationError({
                'non_field_errors': ["Une adresse email ou un numero de telephone est obligatoire."]
            })

        # Validate email uniqueness if provided
        if email and User.objects.filter(email__iexact=email).exists():
            raise serializers.ValidationError({'email': 'Cette adresse email est deja utilisee.'})

        # Validate phone uniqueness if provided
        if phone and User.objects.filter(phone=phone).exists():
            raise serializers.ValidationError({
                'phone': 'Ce numero de telephone est deja utilise.'
            })

        attrs['email'] = email
        attrs['phone'] = phone
        return attrs

    def create(self, validated_data):
        avatar_url = validated_data.pop('avatar_url', None)
        profile_name = validated_data.pop('profile_name', None)
        profile_type_name = validated_data.pop('profile_type', 'main')

        email = validated_data.get('email')
        if not email:
            # The current user model uses email as its database identifier. Keep
            # that implementation detail internal while allowing phone-only
            # accounts to be created without inventing an address for the user.
            email = f"phone-{uuid.uuid4().hex}{PHONE_ACCOUNT_EMAIL_DOMAIN}"

        user = User.objects.create_user(
            email=email,
            password=validated_data['password'],
            firstname=validated_data.get('firstname', ''),
            lastname=validated_data.get('lastname', ''),
            phone=validated_data.get('phone', ''),
            country_code=validated_data.get('country_code', '')
        )

        profile = Profile.objects.filter(user=user).first()
        if profile:
            if profile_name:
                profile.name = profile_name
            if avatar_url:
                profile.avatar_url = avatar_url
            elif profile_type_name == 'child':
                profile.avatar_url = 'https://cdn.ekeflicks.com/avatars/default-child.png'
            if profile_type_name != 'main':
                new_type = ProfileType.objects.filter(name=profile_type_name).first()
                if new_type:
                    profile.type = new_type
            profile.save()

        return user


class EmailOrPhoneTokenObtainPairSerializer(TokenObtainPairSerializer):
    username_field = 'identifier'
    identifier = serializers.CharField(write_only=True, required=False)
    email = serializers.CharField(write_only=True, required=False)

    def validate(self, attrs):
        identifier = (attrs.pop('identifier', None) or attrs.pop('email', None) or '').strip()
        if not identifier:
            raise serializers.ValidationError({'identifier': 'Email ou numero de telephone requis.'})

        # Chercher par email
        user = User.objects.filter(email__iexact=identifier).first()

        # Si non trouvé, chercher par téléphone
        if user is None:
            try:
                phone = normalize_phone(identifier)
            except ValueError:
                raise serializers.ValidationError({
                    'identifier': 'Ajoutez obligatoirement l indicatif du pays, par exemple +2250102030405.'
                })
            user = User.objects.filter(phone=phone).first()

        if user is None:
            # Keep authentication failures deliberately indistinguishable.
            raise serializers.ValidationError('Identifiant ou mot de passe incorrect.')

        if not user.check_password(attrs.get('password')) or not user.is_active:
            raise serializers.ValidationError('Identifiant ou mot de passe incorrect.')

        refresh = self.get_token(user)
        return {'refresh': str(refresh), 'access': str(refresh.access_token)}


class AccountClosureRequestSerializer(serializers.ModelSerializer):
    user_email = serializers.EmailField(source='user.email', read_only=True)

    class Meta:
        model = AccountClosureRequest
        fields = [
            'id',
            'user',
            'user_email',
            'request_type',
            'status',
            'reason',
            'admin_reason',
            'requested_for',
            'reviewed_by',
            'reviewed_at',
            'processed_at',
            'created_at',
            'updated_at',
        ]
        read_only_fields = [
            'id',
            'user',
            'user_email',
            'status',
            'admin_reason',
            'reviewed_by',
            'reviewed_at',
            'processed_at',
            'created_at',
            'updated_at',
        ]


class AccountClosureReviewSerializer(serializers.Serializer):
    reason = serializers.CharField(required=False, allow_blank=True)
