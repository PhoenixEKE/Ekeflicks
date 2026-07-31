from rest_framework import serializers

from apps.common.serializers import get_request_user
from core.models import Profile, ProfileType


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

    class Meta:
        model = Profile
        fields = [
            'id',
            'type',
            'type_id',
            'name',
            'avatar_url',
            'age',
            'phone',
            'country_code',
            'pin_code',
            'is_active',
            'created_at',
            'updated_at',
        ]
        read_only_fields = ['id', 'type', 'created_at', 'updated_at']

    def validate(self, attrs):
        user = get_request_user(self)
        name = attrs.get('name') or getattr(self.instance, 'name', None)

        if user and user.is_authenticated and name:
            duplicate = Profile.objects.filter(user=user, name__iexact=name)
            if self.instance:
                duplicate = duplicate.exclude(pk=self.instance.pk)
            if duplicate.exists():
                raise serializers.ValidationError({'name': 'Ce nom de profil existe deja.'})

        return attrs

    def create(self, validated_data):
        user = get_request_user(self)
        if not user or not user.is_authenticated:
            raise serializers.ValidationError("Authentification requise.")

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
