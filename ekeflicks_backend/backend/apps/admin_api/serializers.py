from django.contrib.auth.models import Group, Permission
from rest_framework import serializers
from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError as DjangoValidationError
from django.db.models import Sum

from apps.auth.serializers import AccountClosureRequestSerializer, EmailChangeSupportRequestSerializer
from core.models.users import User, UserSession
from core.models.content import Content
from core.models.streaming import VideoAsset
from core.models.interactions import WatchHistory
from core.models.subscriptions import ProducerPayoutRequest


class AdminUserSerializer(serializers.ModelSerializer):
    roles = serializers.SlugRelatedField(source='groups', slug_field='name', many=True, read_only=True)
    permissions = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = ('id', 'email', 'firstname', 'lastname', 'phone', 'country_code', 'is_active',
                  'is_verified', 'is_staff', 'is_superuser', 'is_producer', 'producer_company',
                  'roles', 'permissions', 'created_at')
        read_only_fields = ('id', 'email', 'firstname', 'lastname', 'phone', 'country_code',
                            'is_staff', 'is_superuser', 'is_producer', 'producer_company',
                            'roles', 'permissions', 'created_at')

    def get_permissions(self, obj):
        if obj.is_superuser:
            return ['*']
        return sorted(obj.get_all_permissions())


class AdminUserDetailSerializer(AdminUserSerializer):
    address = serializers.SerializerMethodField()
    subscription = serializers.SerializerMethodField()
    profiles = serializers.SerializerMethodField()
    activity = serializers.SerializerMethodField()
    producer_statistics = serializers.SerializerMethodField()
    recent_contents = serializers.SerializerMethodField()
    revenues = serializers.SerializerMethodField()

    class Meta(AdminUserSerializer.Meta):
        fields = AdminUserSerializer.Meta.fields + (
            'address', 'subscription', 'profiles', 'activity',
            'producer_statistics', 'recent_contents', 'revenues',
        )

    def get_address(self, obj):
        return (obj.preferences or {}).get('address', '')

    def get_subscription(self, obj):
        subscription = obj.subscriptions.select_related('plan').order_by('-created_at').first()
        if not subscription:
            return None
        return {
            'id': subscription.pk,
            'plan': subscription.plan.name,
            'status': subscription.status,
            'started_at': subscription.started_at,
            'expires_at': subscription.expires_at,
            'auto_renew': subscription.auto_renew,
        }

    def get_profiles(self, obj):
        return [{
            'id': profile.pk,
            'name': profile.name,
            'type': profile.type.name,
            'age': profile.age,
            'is_active': profile.is_active,
        } for profile in obj.profiles.select_related('type').order_by('created_at')]

    def get_activity(self, obj):
        history = WatchHistory.objects.filter(profile__user=obj)
        sessions = obj.usersession_set.order_by('-created_at')
        devices = list(sessions.exclude(device_id='').values_list('device_type', flat=True).distinct())
        return {
            'last_login': obj.last_login,
            'device_count': sessions.exclude(device_id='').values('device_id').distinct().count(),
            'devices': devices,
            'watch_seconds': history.aggregate(total=Sum('watched_duration'))['total'] or 0,
        }

    def get_producer_statistics(self, obj):
        if not obj.is_producer:
            return None
        contents = obj.produced_contents.all()
        statuses = {key: contents.filter(producer_submission_status=key).count()
                    for key in ('approved', 'rejected', 'pending')}
        return {
            'content_count': contents.count(),
            **statuses,
            'total_views': contents.aggregate(total=Sum('view_count'))['total'] or 0,
        }

    def get_recent_contents(self, obj):
        if not obj.is_producer:
            return []
        return list(obj.produced_contents.order_by('-created_at').values(
            'id', 'title', 'type', 'producer_submission_status', 'view_count',
        )[:5])

    def get_revenues(self, obj):
        if not obj.is_producer:
            return None
        payouts = obj.payout_requests.all()
        last = payouts.filter(status='paid').order_by('-paid_at').first()
        return {
            'total': payouts.filter(status='paid').aggregate(total=Sum('amount_eur'))['total'] or 0,
            'pending': payouts.filter(status='pending').aggregate(total=Sum('amount_eur'))['total'] or 0,
            'last_payment': None if not last else {
                'amount': last.amount_eur,
                'currency': last.currency,
                'paid_at': last.paid_at,
            },
        }


class AdminUserUpdateSerializer(serializers.ModelSerializer):
    address = serializers.CharField(required=False, allow_blank=True, max_length=500, write_only=True)

    class Meta:
        model = User
        fields = ('firstname', 'lastname', 'phone', 'country_code', 'producer_company', 'address')

    def update(self, instance, validated_data):
        address = validated_data.pop('address', None)
        instance = super().update(instance, validated_data)
        if address is not None:
            instance.preferences = {**(instance.preferences or {}), 'address': address}
            instance.save(update_fields=['preferences'])
        return instance


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


class AdminStaffCreateSerializer(serializers.Serializer):
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True, min_length=12)
    firstname = serializers.CharField(required=False, allow_blank=True, max_length=100)
    lastname = serializers.CharField(required=False, allow_blank=True, max_length=100)
    role = serializers.ChoiceField(choices=('Modérateur', 'Finance', 'Support'))

    def validate_email(self, value):
        if User.objects.filter(email__iexact=value).exists():
            raise serializers.ValidationError('Cette adresse e-mail est déjà utilisée.')
        return value

    def validate_password(self, value):
        try:
            validate_password(value)
        except DjangoValidationError as exc:
            raise serializers.ValidationError(list(exc.messages)) from exc
        return value


class AdminContentSerializer(serializers.ModelSerializer):
    producer_email = serializers.EmailField(source='producer.email', read_only=True)

    class Meta:
        model = Content
        fields = ('id', 'title', 'type', 'producer_email', 'producer_submission_status',
                  'producer_notes', 'review_reason', 'submitted_at', 'reviewed_at')


class AdminVideoAssetSerializer(serializers.ModelSerializer):
    content_title = serializers.CharField(source='content.title', read_only=True)
    producer_email = serializers.EmailField(source='content.producer.email', read_only=True)

    class Meta:
        model = VideoAsset
        fields = ('id', 'title', 'content', 'content_title', 'producer_email', 'status',
                  'moderation_status', 'moderation_reason', 'source_uploaded_at', 'moderated_at')


class AdminPayoutSerializer(serializers.ModelSerializer):
    producer_email = serializers.EmailField(source='producer.email', read_only=True)
    first_approver = serializers.EmailField(source='reviewed_by.email', read_only=True)

    class Meta:
        model = ProducerPayoutRequest
        fields = ('id', 'producer', 'producer_email', 'amount_eur', 'amount_local', 'currency',
                  'eligible_views', 'payout_method', 'payout_account', 'status', 'producer_note',
                  'admin_reason', 'first_approver', 'reviewed_at', 'paid_at', 'created_at')
        read_only_fields = fields


class CriticalPayoutSerializer(serializers.Serializer):
    password = serializers.CharField(write_only=True)
    reason = serializers.CharField(required=False, allow_blank=True)

    def validate_password(self, value):
        if not self.context['request'].user.check_password(value):
            raise serializers.ValidationError('Réauthentification incorrecte.')
        return value


class AdminSessionSerializer(serializers.ModelSerializer):
    current = serializers.SerializerMethodField()

    class Meta:
        model = UserSession
        fields = ('id', 'device_id', 'device_type', 'created_at', 'expires_at', 'is_active', 'current')

    def get_current(self, obj):
        return str(obj.id) == str(self.context.get('session_id'))


ClaimClosureSerializer = AccountClosureRequestSerializer
ClaimEmailSerializer = EmailChangeSupportRequestSerializer
