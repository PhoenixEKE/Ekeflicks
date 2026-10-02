from decimal import Decimal, ROUND_HALF_UP

from django.db import transaction
from django.db.models import Count, Sum
from django.utils import timezone
from rest_framework import exceptions
from rest_framework import serializers
from rest_framework.status import HTTP_409_CONFLICT

from apps.analytics.services import convert_eur_for_producer, producer_currency, revenue_settings
from apps.notifications.services import notify_staff, notify_user
from core.models import ProducerAdvertisingRevenue, ProducerContentView, ProducerDemoEarning, ProducerPayoutRequest, ProducerRevenueSetting, User


class PayoutConflict(exceptions.APIException):
    status_code = HTTP_409_CONFLICT
    default_code = 'payout_conflict'


def available_producer_views(producer):
    return ProducerContentView.objects.filter(producer=producer, status='pending')


def producer_balance(producer, include_demo=False):
    views = available_producer_views(producer)
    ad_revenues = ProducerAdvertisingRevenue.objects.filter(
        producer=producer,
        status='pending',
    ).select_related('content')
    view_amount = views.aggregate(total=Sum('amount_eur'))['total'] or Decimal('0')
    ad_amount = ad_revenues.aggregate(total=Sum('producer_share_eur'))['total'] or Decimal('0')
    amount_eur = view_amount + ad_amount
    currency, amount_local = convert_eur_for_producer(amount_eur, producer)
    _, currency_rate = producer_currency(producer)

    def local_amount(value):
        return (Decimal(value or 0) * currency_rate).quantize(
            Decimal('0.0001'), rounding=ROUND_HALF_UP
        )
    available_by_content = {}
    for row in views.values('content_id', 'content__title').annotate(
        views=Count('id'), amount=Sum('amount_eur')
    ):
        available_by_content[row['content_id']] = {
            'content_id': str(row['content_id']),
            'title': row['content__title'],
            'eligible_views': row['views'] or 0,
            'view_revenue_eur': row['amount'] or Decimal('0'),
            'advertising_revenue_eur': Decimal('0'),
        }
    for row in ad_revenues.values('content_id', 'content__title').annotate(
        amount=Sum('producer_share_eur')
    ):
        entry = available_by_content.setdefault(row['content_id'], {
            'content_id': str(row['content_id']),
            'title': row['content__title'],
            'eligible_views': 0,
            'view_revenue_eur': Decimal('0'),
            'advertising_revenue_eur': Decimal('0'),
        })
        entry['advertising_revenue_eur'] = row['amount'] or Decimal('0')
    setting = revenue_settings()
    all_view_rows = ProducerContentView.objects.filter(
        producer=producer,
        status__in=['pending', 'requested', 'paid'],
    ).values('content_id', 'content__title').annotate(
        views=Count('id'), amount=Sum('amount_eur')
    )
    all_ad_rows = ProducerAdvertisingRevenue.objects.filter(
        producer=producer,
        status__in=['pending', 'requested', 'paid'],
    ).values('content_id', 'content__title').annotate(
        amount=Sum('producer_share_eur')
    )
    all_by_content = {}
    for row in all_view_rows:
        all_by_content[row['content_id']] = {
            'content_id': str(row['content_id']),
            'title': row['content__title'],
            'eligible_views': row['views'] or 0,
            'view_revenue_eur': row['amount'] or Decimal('0'),
            'advertising_revenue_eur': Decimal('0'),
        }
    for row in all_ad_rows:
        entry = all_by_content.setdefault(row['content_id'], {
            'content_id': str(row['content_id']),
            'title': row['content__title'],
            'eligible_views': 0,
            'view_revenue_eur': Decimal('0'),
            'advertising_revenue_eur': Decimal('0'),
        })
        entry['advertising_revenue_eur'] = row['amount'] or Decimal('0')
    demo_rows = list(
        ProducerDemoEarning.objects.filter(producer=producer, seed_key='producer_portal_demo_v1').select_related('content')
    ) if include_demo else []
    demo_view_amount = sum((Decimal(row.view_revenue_eur) for row in demo_rows), Decimal('0'))
    demo_ad_amount = sum((Decimal(row.advertising_share_eur) for row in demo_rows), Decimal('0'))
    demo_eligible_views = sum(row.eligible_views for row in demo_rows)
    demo_amount = demo_view_amount + demo_ad_amount
    for row in demo_rows:
        for target in (all_by_content, available_by_content):
            entry = target.setdefault(row.content_id, {
                'content_id': str(row.content_id),
                'title': row.content.title,
                'eligible_views': 0,
                'view_revenue_eur': Decimal('0'),
                'advertising_revenue_eur': Decimal('0'),
            })
            entry['eligible_views'] += row.eligible_views
            entry['view_revenue_eur'] += Decimal(row.view_revenue_eur)
            entry['advertising_revenue_eur'] += Decimal(row.advertising_share_eur)
    view_amount += demo_view_amount
    ad_amount += demo_ad_amount
    amount_eur = view_amount + ad_amount
    # Recompute after opt-in demo rows have been included.
    currency, amount_local = convert_eur_for_producer(amount_eur, producer)

    return {
        'eligible_views': views.count() + demo_eligible_views,
        'demo_mode': bool(demo_rows),
        'demo_eligible_views': demo_eligible_views,
        'demo_amount_eur': demo_amount,
        'demo_amount_local': local_amount(demo_amount),
        'amount_eur': amount_eur,
        'currency': currency,
        'amount_local': amount_local,
        'available_content_earnings': [
            {
                **row,
                'total_eur': row['view_revenue_eur'] + row['advertising_revenue_eur'],
                'view_revenue_local': local_amount(row['view_revenue_eur']),
                'advertising_revenue_local': local_amount(row['advertising_revenue_eur']),
                'total_local': local_amount(row['view_revenue_eur'] + row['advertising_revenue_eur']),
            }
            for row in available_by_content.values()
        ],
        'content_earnings': [
            {
                **row,
                'total_eur': row['view_revenue_eur'] + row['advertising_revenue_eur'],
                'view_revenue_local': local_amount(row['view_revenue_eur']),
                'advertising_revenue_local': local_amount(row['advertising_revenue_eur']),
                'total_local': local_amount(row['view_revenue_eur'] + row['advertising_revenue_eur']),
            }
            for row in all_by_content.values()
        ],
        'rate_per_1000_views_eur': setting.rate_per_1000_views_eur,
        'rate_per_1000_views_local': local_amount(setting.rate_per_1000_views_eur),
        'eligible_progress_percent': setting.eligible_progress_percent,
        'advertising_share_percent': setting.advertising_share_percent,
        'minimum_payout_eur': setting.minimum_payout_eur,
        'minimum_payout_local': local_amount(setting.minimum_payout_eur),
    }


@transaction.atomic
def create_payout_request(producer, payout_method='', payout_account='', producer_note=''):
    setting = revenue_settings()
    if not setting.remuneration_enabled:
        raise serializers.ValidationError({'detail': 'La remuneration globale des producteurs est desactivee.'})
    if not producer.producer_remuneration_enabled:
        raise serializers.ValidationError({'detail': 'La remuneration de ce producteur est desactivee.'})

    views = available_producer_views(producer).select_for_update()
    ad_revenues = ProducerAdvertisingRevenue.objects.filter(
        producer=producer,
        status='pending',
    ).select_for_update()
    balance = producer_balance(producer)
    if balance['amount_eur'] <= 0:
        raise serializers.ValidationError({'detail': 'Aucune rémunération disponible pour paiement.'})
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
    ad_revenues.update(status='requested', payout_request=payout)

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
    payout.advertising_earnings.update(status='pending', payout_request=None)
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
    payout.advertising_earnings.update(status='paid')
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
