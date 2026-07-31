from rest_framework import serializers
from core.models.users import AccountClosureRequest, EmailChangeSupportRequest, User
from core.models.profiles import Profile, ProfileType

class UserSerializer(serializers.ModelSerializer):
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
    class Meta:
        model = User
        fields = ['id', 'email', 'firstname', 'lastname', 'phone', 'country_code', 'is_verified', 'created_at']
        read_only_fields = ['id', 'email', 'is_verified', 'created_at']


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
            if requested_email == current_user.email.lower():
                raise serializers.ValidationError('Le nouvel email doit etre different de votre email actuel.')

        if User.objects.filter(email__iexact=requested_email).exists():
            raise serializers.ValidationError('Cet email est deja utilise.')

        return requested_email

class UserCreateSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=8)
    avatar_url = serializers.URLField(required=False, allow_blank=True, allow_null=True)
    profile_name = serializers.CharField(required=False, allow_blank=True)
    profile_type = serializers.CharField(required=False, default='main')

    class Meta:
        model = User
        fields = ['email', 'password', 'firstname', 'lastname', 'phone', 'country_code', 'avatar_url', 'profile_name', 'profile_type']

    def create(self, validated_data):
        avatar_url = validated_data.pop('avatar_url', None)
        profile_name = validated_data.pop('profile_name', None)
        profile_type_name = validated_data.pop('profile_type', 'main')
        
        user = User.objects.create_user(
            email=validated_data['email'],
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
