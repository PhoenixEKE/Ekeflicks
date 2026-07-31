from datetime import timedelta
import uuid

from django.utils import timezone
from rest_framework import serializers

from apps.common.serializers import get_request_user
from core.models import Payment, ProducerPayoutRequest, Subscription, SubscriptionPlan


class SubscriptionPlanSerializer(serializers.ModelSerializer):
    class Meta:
        model = SubscriptionPlan
        fields = [
            'id',
            'name',
            'slug',
            'description',
            'price',
            'currency',
            'duration_days',
            'max_profiles',
            'max_devices',
            'max_quality',
            'ads_included',
            'download_enabled',
            'features',
            'display_order',
            'is_active',
            'created_at',
            'updated_at',
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


class SubscriptionSerializer(serializers.ModelSerializer):
    plan = SubscriptionPlanSerializer(read_only=True)
    plan_id = serializers.PrimaryKeyRelatedField(
        source='plan',
        queryset=SubscriptionPlan.objects.filter(is_active=True),
        write_only=True,
    )

    class Meta:
        model = Subscription
        fields = [
            'id',
            'plan',
            'plan_id',
            'status',
            'started_at',
            'expires_at',
            'cancelled_at',
            'auto_renew',
            'created_at',
            'updated_at',
        ]
        read_only_fields = [
            'id',
            'plan',
            'status',
            'started_at',
            'expires_at',
            'cancelled_at',
            'created_at',
            'updated_at',
        ]

    def create(self, validated_data):
        user = get_request_user(self)
        if not user or not user.is_authenticated:
            raise serializers.ValidationError("Authentification requise.")

        plan = validated_data['plan']
        expires_at = timezone.now() + timedelta(days=plan.duration_days)
        return Subscription.objects.create(
            user=user,
            plan=plan,
            status='pending',
            expires_at=expires_at,
            auto_renew=validated_data.get('auto_renew', True),
        )


class PaymentSerializer(serializers.ModelSerializer):
    subscription = SubscriptionSerializer(read_only=True)
    subscription_id = serializers.PrimaryKeyRelatedField(
        source='subscription',
        queryset=Subscription.objects.all(),
        write_only=True,
    )

    class Meta:
        model = Payment
        fields = [
            'id',
            'subscription',
            'subscription_id',
            'amount',
            'currency',
            'status',
            'provider',
            'provider_payment_id',
            'provider_reference',
            'checkout_url',
            'metadata',
            'provider_payload',
            'verified_at',
            'paid_at',
            'created_at',
            'updated_at',
        ]
        read_only_fields = [
            'id',
            'subscription',
            'amount',
            'currency',
            'status',
            'provider_reference',
            'checkout_url',
            'provider_payment_id',
            'provider_payload',
            'verified_at',
            'paid_at',
            'created_at',
            'updated_at',
        ]

    def validate_subscription_id(self, subscription):
        user = get_request_user(self)
        if not user or not user.is_authenticated or subscription.user_id != user.id:
            raise serializers.ValidationError("Abonnement invalide pour cet utilisateur.")
        return subscription

    def create(self, validated_data):
        subscription = validated_data['subscription']
        plan = subscription.plan
        provider = validated_data.get('provider') or 'cinetpay'
        provider_reference = f"eke_{uuid.uuid4().hex}"
        return Payment.objects.create(
            subscription=subscription,
            amount=plan.price,
            currency=plan.currency,
            status='pending',
            provider=provider,
            provider_reference=provider_reference,
            metadata={'subscription_id': str(subscription.id), 'plan_id': str(plan.id)},
        )


class ProducerPayoutRequestSerializer(serializers.ModelSerializer):
    producer_email = serializers.EmailField(source='producer.email', read_only=True)

    class Meta:
        model = ProducerPayoutRequest
        fields = [
            'id',
            'producer',
            'producer_email',
            'amount_eur',
            'currency',
            'amount_local',
            'eligible_views',
            'payout_method',
            'payout_account',
            'status',
            'producer_note',
            'admin_reason',
            'reviewed_by',
            'reviewed_at',
            'paid_at',
            'created_at',
            'updated_at',
        ]
        read_only_fields = [
            'id',
            'producer',
            'producer_email',
            'amount_eur',
            'currency',
            'amount_local',
            'eligible_views',
            'status',
            'admin_reason',
            'reviewed_by',
            'reviewed_at',
            'paid_at',
            'created_at',
            'updated_at',
        ]


class PayoutReviewSerializer(serializers.Serializer):
    reason = serializers.CharField(required=False, allow_blank=True)


class PayoutRejectSerializer(serializers.Serializer):
    reason = serializers.CharField(required=True, allow_blank=False)


class RemunerationToggleSerializer(serializers.Serializer):
    enabled = serializers.BooleanField(required=True)
    producer_id = serializers.UUIDField(required=False)
