from decimal import Decimal

from django.db import transaction
from django.db.models import Sum
from django.utils import timezone
from rest_framework import exceptions
from rest_framework import serializers
from rest_framework.status import HTTP_409_CONFLICT

from apps.analytics.services import convert_eur_for_producer, revenue_settings
from apps.notifications.services import notify_staff, notify_user
from core.models import ProducerContentView, ProducerPayoutRequest, User


class PayoutConflict(exceptions.APIException):
    status_code = HTTP_409_CONFLICT
    default_code = 'payout_conflict'


def available_producer_views(producer):
    return ProducerContentView.objects.filter(producer=producer, status='pending')


def producer_balance(producer):
    views = available_producer_views(producer)
    amount_eur = views.aggregate(total=Sum('amount_eur'))['total'] or Decimal('0')
    currency, amount_local = convert_eur_for_producer(amount_eur, producer)
    return {
        'eligible_views': views.count(),
        'amount_eur': amount_eur,
        'currency': currency,
        'amount_local': amount_local,
    }


@transaction.atomic
def create_payout_request(producer, payout_method='', payout_account='', producer_note=''):
    setting = revenue_settings()
    if not setting.remuneration_enabled:
        raise serializers.ValidationError({'detail': 'La remuneration globale des producteurs est desactivee.'})
    if not producer.producer_remuneration_enabled:
        raise serializers.ValidationError({'detail': 'La remuneration de ce producteur est desactivee.'})

    views = available_producer_views(producer).select_for_update()
    balance = producer_balance(producer)
    if balance['eligible_views'] <= 0 or balance['amount_eur'] <= 0:
        raise serializers.ValidationError({'detail': 'Aucune vue eligible disponible pour paiement.'})
    if balance['amount_eur'] < setting.minimum_payout_eur:
        raise serializers.ValidationError({
            'detail': f"Le solde disponible est inferieur au minimum de paiement ({setting.minimum_payout_eur} EUR)."
        })

    payout = ProducerPayoutRequest.objects.create(
        producer=producer,
        amount_eur=balance['amount_eur'],
        currency=balance['currency'],
        amount_local=balance['amount_local'],
        eligible_views=balance['eligible_views'],
        payout_method=payout_method,
        payout_account=payout_account,
        producer_note=producer_note,
    )
    views.update(status='requested', payout_request=payout)

    notify_user(
        producer,
        'producer_payout_requested',
        data={'payout_request_id': str(payout.id)},
    )
    notify_staff(
        'producer_payout_requested',
        title='Nouvelle demande de paiement producteur',
        message=f"{producer.email} demande {payout.amount_local} {payout.currency}.",
        data={'payout_request_id': str(payout.id), 'producer_id': str(producer.id)},
    )
    return payout


def approve_payout_request(payout, reviewer, reason=''):
    if payout.status != 'pending':
        raise PayoutConflict('Cette demande a déjà été traitée.')
    payout.status = 'approved'
    payout.admin_reason = reason
    payout.reviewed_by = reviewer
    payout.reviewed_at = timezone.now()
    payout.save(update_fields=['status', 'admin_reason', 'reviewed_by', 'reviewed_at', 'updated_at'])
    notify_user(
        payout.producer,
        'producer_payout_approved',
        data={'payout_request_id': str(payout.id)},
    )
    return payout


def reject_payout_request(payout, reviewer, reason):
    if payout.status != 'pending':
        raise PayoutConflict('Cette demande a déjà été traitée.')
    payout.status = 'rejected'
    payout.admin_reason = reason
    payout.reviewed_by = reviewer
    payout.reviewed_at = timezone.now()
    payout.save(update_fields=['status', 'admin_reason', 'reviewed_by', 'reviewed_at', 'updated_at'])
    payout.producer_views.update(status='pending', payout_request=None)
    notify_user(
        payout.producer,
        'producer_payout_rejected',
        message=reason,
        data={'payout_request_id': str(payout.id)},
    )
    return payout


def mark_payout_paid(payout, reviewer, reason=''):
    if payout.status != 'approved':
        raise PayoutConflict('La demande doit être approuvée avant le paiement.')
    if payout.reviewed_by_id == reviewer.pk:
        raise exceptions.PermissionDenied(
            'La mise en paiement doit être validée par un second agent finance.'
        )
    payout.status = 'paid'
    payout.admin_reason = reason or payout.admin_reason
    payout.reviewed_at = payout.reviewed_at or timezone.now()
    payout.paid_at = timezone.now()
    payout.save(update_fields=['status', 'admin_reason', 'reviewed_at', 'paid_at', 'updated_at'])
    payout.producer_views.update(status='paid')
    return payout


def set_global_remuneration(enabled):
    setting = revenue_settings()
    setting.remuneration_enabled = enabled
    setting.save(update_fields=['remuneration_enabled', 'updated_at'])
    return setting


def set_producer_remuneration(producer_id, enabled):
    producer = User.objects.get(pk=producer_id, is_producer=True)
    producer.producer_remuneration_enabled = enabled
    producer.save(update_fields=['producer_remuneration_enabled', 'updated_at'])
    return producer
