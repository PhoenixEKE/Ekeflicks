from django.contrib.auth.models import Group, Permission
from rest_framework import serializers

from apps.auth.serializers import AccountClosureRequestSerializer, EmailChangeSupportRequestSerializer
from core.models.users import User, UserSession


class AdminUserSerializer(serializers.ModelSerializer):
    roles = serializers.SlugRelatedField(source='groups', slug_field='name', many=True, read_only=True)

    class Meta:
        model = User
        fields = ('id', 'email', 'firstname', 'lastname', 'phone', 'country_code', 'is_active',
                  'is_verified', 'is_staff', 'is_superuser', 'is_producer', 'producer_company', 'roles', 'created_at')
        read_only_fields = ('id', 'is_superuser', 'created_at')


class PermissionSerializer(serializers.ModelSerializer):
    key = serializers.SerializerMethodField()

    class Meta:
        model = Permission
        fields = ('id', 'key', 'name')

    def get_key(self, obj):
        return f'{obj.content_type.app_label}.{obj.codename}'


class RoleSerializer(serializers.ModelSerializer):
    permissions = serializers.PrimaryKeyRelatedField(many=True, queryset=Permission.objects.all(), required=False)

    class Meta:
        model = Group
        fields = ('id', 'name', 'permissions')

class RoleAssignmentSerializer(serializers.Serializer):
    role_ids = serializers.PrimaryKeyRelatedField(source='roles', many=True, queryset=Group.objects.all())


class AdminSessionSerializer(serializers.ModelSerializer):
    current = serializers.SerializerMethodField()

    class Meta:
        model = UserSession
        fields = ('id', 'device_id', 'device_type', 'created_at', 'expires_at', 'is_active', 'current')

    def get_current(self, obj):
        return str(obj.id) == str(self.context.get('session_id'))


ClaimClosureSerializer = AccountClosureRequestSerializer
ClaimEmailSerializer = EmailChangeSupportRequestSerializer
