import hashlib
import hmac
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone as datetime_timezone
from decimal import Decimal

import stripe

from django.conf import settings
from django.db import transaction
from django.utils import timezone

from apps.notifications.services import notify_user
from core.models import Payment, Subscription


@dataclass
class PaymentEvent:
    event_id: str
    event_type: str
    provider_reference: str
    provider_payment_id: str
    successful: bool
    failed: bool
    amount: int | None = None
    currency: str = ''
    subscription_id: str = ''
    customer_id: str = ''
    local_subscription_id: str = ''
    cancel_at_period_end: bool | None = None
    current_period_end: int | None = None
    subscription_status: str = ''
    recurring_checkout: bool = False


def _header(headers, name):
    return headers.get(name) or headers.get(name.lower()) or headers.get(name.upper())


def _hmac_digest(secret, body, algorithm):
    return hmac.new(secret.encode(), body, algorithm).hexdigest()


def verify_webhook_signature(provider, body, headers):
    if provider == 'stripe':
        secret = getattr(settings, 'STRIPE_WEBHOOK_SECRET', '')
        signature = _header(headers, 'stripe-signature')

        if not secret or not signature:
            return False

        try:
            stripe.Webhook.construct_event(
                payload=body,
                sig_header=signature,
                secret=secret,
            )
            return True
        except (ValueError, stripe.error.SignatureVerificationError):
            return False

    if provider == 'paystack':
        secret = getattr(settings, 'PAYSTACK_SECRET_KEY', '')
        signature = _header(headers, 'x-paystack-signature')
        if not secret or not signature:
            return False
        expected = _hmac_digest(secret, body, hashlib.sha512)
        return hmac.compare_digest(expected, signature)

    if provider == 'flutterwave':
        secret = getattr(settings, 'FLUTTERWAVE_WEBHOOK_SECRET', '')
        signature = _header(headers, 'verif-hash')
        return bool(secret and signature and hmac.compare_digest(secret, signature))

    secret_map = {
        'cinetpay': getattr(settings, 'CINETPAY_WEBHOOK_SECRET', ''),
        'wave': getattr(settings, 'WAVE_WEBHOOK_SECRET', ''),
    }
    secret = secret_map.get(provider, '')
    signature = (
        _header(headers, 'x-signature')
        or _header(headers, 'x-token')
        or _header(headers, f'x-{provider}-signature')
    )
    if not secret or not signature:
        return False

    expected = _hmac_digest(secret, body, hashlib.sha256)
    return hmac.compare_digest(expected, signature)


def normalize_payment_event(provider, payload):
    if provider == 'stripe':
        event_type = payload.get('type', '')
        data = payload.get('data') or {}
        obj = data.get('object') or {}
        metadata = obj.get('metadata') or {}

        if event_type.startswith('invoice.'):
            invoice_id = str(obj.get('id') or '')
            parent = obj.get('parent') or {}
            details = parent.get('subscription_details') or {}
            subscription_id = obj.get('subscription') or details.get('subscription') or ''
            if isinstance(subscription_id, dict):
                subscription_id = subscription_id.get('id', '')
            amount = (
                obj.get('amount_paid')
                if event_type in {'invoice.paid', 'invoice.payment_succeeded'}
                else obj.get('amount_due')
            )
            return PaymentEvent(
                event_id=str(payload.get('id') or invoice_id),
                event_type=event_type,
                provider_reference=f'stripe-invoice:{invoice_id}',
                provider_payment_id=invoice_id,
                successful=event_type in {'invoice.paid', 'invoice.payment_succeeded'},
                failed=event_type == 'invoice.payment_failed',
                amount=amount,
                currency=str(obj.get('currency') or '').upper(),
                subscription_id=str(subscription_id),
            )

        if event_type in {
            'customer.subscription.created',
            'customer.subscription.updated',
            'customer.subscription.deleted',
        }:
            subscription_id = str(obj.get('id') or '')
            return PaymentEvent(
                event_id=str(payload.get('id') or subscription_id),
                event_type=event_type,
                provider_reference=f'stripe-subscription:{subscription_id}',
                provider_payment_id=subscription_id,
                successful=False,
                failed=False,
                subscription_id=subscription_id,
                cancel_at_period_end=bool(obj.get('cancel_at_period_end', False)),
                current_period_end=obj.get('current_period_end'),
                customer_id=str(obj.get('customer') or ''),
                local_subscription_id=str(metadata.get('local_subscription_id') or ''),
                subscription_status=str(obj.get('status') or ''),
            )

        reference = (
            obj.get('client_reference_id')
            or metadata.get('provider_reference')
            or ''
        )
        provider_payment_id = str(obj.get('payment_intent') or obj.get('id') or '')
        payment_status = obj.get('payment_status', '')
        successful = (
            event_type in {'checkout.session.completed', 'checkout.session.async_payment_succeeded'}
            and payment_status in {'paid', 'no_payment_required'}
        )
        failed = event_type == 'checkout.session.async_payment_failed'
        subscription_id = obj.get('subscription') or ''
        if isinstance(subscription_id, dict):
            subscription_id = subscription_id.get('id', '')
        return PaymentEvent(
            event_id=str(payload.get('id') or obj.get('id') or reference),
            event_type=event_type,
            provider_reference=str(reference),
            provider_payment_id=provider_payment_id,
            successful=successful,
            failed=failed,
            amount=obj.get('amount_total'),
            currency=str(obj.get('currency') or '').upper(),
            subscription_id=str(subscription_id),
            customer_id=str(obj.get('customer') or ''),
            recurring_checkout=obj.get('mode') == 'subscription',
        )

    if provider == 'paystack':
        data = payload.get('data') or {}
        event_type = payload.get('event', '')
        reference = data.get('reference') or payload.get('reference') or ''
        provider_payment_id = str(data.get('id') or '')
        return PaymentEvent(
            event_id=provider_payment_id or reference,
            event_type=event_type,
            provider_reference=reference,
            provider_payment_id=provider_payment_id,
            successful=event_type == 'charge.success' or data.get('status') == 'success',
            failed=data.get('status') == 'failed',
        )

    if provider == 'flutterwave':
        data = payload.get('data') or {}
        event_type = payload.get('event', '')
        reference = data.get('tx_ref') or data.get('reference') or payload.get('tx_ref') or ''
        provider_payment_id = str(data.get('id') or data.get('flw_ref') or '')
        status = data.get('status') or payload.get('status')
        return PaymentEvent(
            event_id=provider_payment_id or reference,
            event_type=event_type,
            provider_reference=reference,
            provider_payment_id=provider_payment_id,
            successful=event_type == 'charge.completed' and status == 'successful',
            failed=status in {'failed', 'cancelled'},
        )

    if provider == 'cinetpay':
        reference = (
            payload.get('transaction_id')
            or payload.get('cpm_trans_id')
            or payload.get('metadata')
            or ''
        )
        provider_payment_id = str(payload.get('payment_token') or payload.get('cpm_trans_id') or '')
        event_type = payload.get('event') or payload.get('type') or 'payment.notification'
        provider_status = payload.get('cpm_trans_status') or payload.get('status') or payload.get('code')
        return PaymentEvent(
            event_id=provider_payment_id or str(reference),
            event_type=event_type,
            provider_reference=str(reference),
            provider_payment_id=provider_payment_id,
            successful=provider_status in {'ACCEPTED', 'SUCCESS', 'SUCCEEDED', '00'},
            failed=provider_status in {'REFUSED', 'FAILED', 'CANCELLED'},
        )

    if provider == 'wave':
        reference = payload.get('client_reference') or payload.get('reference') or payload.get('transaction_id') or ''
        provider_payment_id = str(payload.get('id') or payload.get('transaction_id') or '')
        event_type = payload.get('event') or payload.get('type') or 'payment.notification'
        provider_status = payload.get('status')
        return PaymentEvent(
            event_id=provider_payment_id or str(reference),
            event_type=event_type,
            provider_reference=str(reference),
            provider_payment_id=provider_payment_id,
            successful=provider_status in {'success', 'succeeded', 'completed'},
            failed=provider_status in {'failed', 'cancelled', 'expired'},
        )

    reference = payload.get('reference') or payload.get('transaction_id') or ''
    provider_payment_id = str(payload.get('id') or '')
    status = payload.get('status')
    return PaymentEvent(
        event_id=provider_payment_id or str(reference),
        event_type=payload.get('event') or payload.get('type') or 'payment.notification',
        provider_reference=str(reference),
        provider_payment_id=provider_payment_id,
        successful=status in {'success', 'succeeded', 'completed'},
        failed=status in {'failed', 'cancelled'},
    )


def _stripe_expected_minor_amount(amount, currency):
    zero_decimal_currencies = {
        'BIF', 'CLP', 'DJF', 'GNF', 'JPY', 'KMF',
        'KRW', 'MGA', 'PYG', 'RWF', 'UGX', 'VND',
        'VUV', 'XAF', 'XOF', 'XPF',
    }
    amount = Decimal(amount or 0)
    if str(currency or '').upper() in zero_decimal_currencies:
        return int(amount)
    return int(amount * 100)


def _stripe_invoice_period_end(invoice):
    lines = (invoice.get('lines') or {}).get('data') or []
    for line in lines:
        period = line.get('period') or {}
        if period.get('end'):
            return datetime.fromtimestamp(
                int(period['end']),
                tz=datetime_timezone.utc,
            )
    return None


def _apply_stripe_invoice_event(event, payload):
    invoice = ((payload.get('data') or {}).get('object') or {})
    invoice_id = str(invoice.get('id') or '')
    if not invoice_id:
        return None, 'Facture Stripe sans identifiant.'

    parent = invoice.get('parent') or {}
    details = parent.get('subscription_details') or {}
    subscription_ref = invoice.get('subscription') or details.get('subscription') or ''
    if isinstance(subscription_ref, dict):
        subscription_ref = subscription_ref.get('id', '')
    subscription_id = str(event.subscription_id or subscription_ref)
    metadata = details.get('metadata') or invoice.get('metadata') or {}
    local_subscription_id = (
        metadata.get('local_subscription_id')
        or metadata.get('subscription_id')
    )

    queryset = Subscription.objects.select_for_update().select_related('user', 'plan')
    subscription = queryset.filter(
        stripe_subscription_id=subscription_id
    ).first()
    if subscription is None and local_subscription_id:
        subscription = queryset.filter(pk=local_subscription_id).first()
    if subscription is None:
        return None, 'Abonnement local introuvable pour cette facture Stripe.'

    expected_currency = str(
        subscription.currency_at_purchase or subscription.plan.currency or ''
    ).upper()
    if event.successful:
        if event.amount is None:
            return None, 'Montant de facture Stripe absent.'
        if not event.currency:
            return None, 'Devise de facture Stripe absente.'
        expected_amount = _stripe_expected_minor_amount(
            subscription.price_at_purchase or subscription.plan.price,
            expected_currency,
        )
        if int(event.amount) != expected_amount:
            return None, 'Montant de renouvellement Stripe incohérent.'
        if event.currency.upper() != expected_currency:
            return None, 'Devise de renouvellement Stripe incohérente.'

    reference = f'stripe-invoice:{invoice_id}'
    payment = (
        Payment.objects.select_for_update()
        .filter(provider='stripe', provider_reference=reference)
        .first()
    )
    if payment is None:
        payment = Payment.objects.create(
            subscription=subscription,
            amount=subscription.price_at_purchase or subscription.plan.price,
            currency=expected_currency or subscription.plan.currency,
            status='pending',
            provider='stripe',
            provider_reference=reference,
        )

    previous_status = payment.status
    payment.provider_payment_id = invoice_id
    payment.provider_payload = payload
    payment.verified_at = timezone.now()
    if event.successful:
        payment.status = 'success'
        payment.paid_at = payment.paid_at or timezone.now()
        subscription.status = 'active'
        subscription.stripe_subscription_id = (
            subscription_id or subscription.stripe_subscription_id
        )
        subscription.stripe_customer_id = (
            event.customer_id or subscription.stripe_customer_id
        )
        new_expiry = _stripe_invoice_period_end(invoice)
        if new_expiry is None:
            base = max(subscription.expires_at, timezone.now())
            new_expiry = base + timedelta(
                days=subscription.duration_days_at_purchase or 30
            )
        subscription.expires_at = new_expiry
        subscription.save(update_fields=[
            'status',
            'stripe_subscription_id',
            'stripe_customer_id',
            'expires_at',
            'updated_at',
        ])
        if previous_status != 'success':
            user = subscription.user
            payment_id = str(payment.id)
            subscription_pk = str(subscription.id)
            transaction.on_commit(
                lambda: notify_user(
                    user,
                    'subscription_created',
                    title='Abonnement renouvelé',
                    message='Votre prélèvement récurrent EkeFlicks a été confirmé.',
                    data={
                        'payment_id': payment_id,
                        'subscription_id': subscription_pk,
                    },
                )
            )
    elif event.failed and previous_status != 'success':
        payment.status = 'failed'

    payment.save(update_fields=[
        'provider_payment_id',
        'provider_payload',
        'verified_at',
        'status',
        'paid_at',
        'updated_at',
    ])
    return payment, ''


def _apply_stripe_subscription_event(event, payload):
    obj = ((payload.get('data') or {}).get('object') or {})
    subscription_id = str(event.subscription_id or obj.get('id') or '')
    metadata = obj.get('metadata') or {}
    local_subscription_id = (
        event.local_subscription_id
        or metadata.get('local_subscription_id')
    )
    queryset = Subscription.objects.select_for_update()
    subscription = queryset.filter(
        stripe_subscription_id=subscription_id
    ).first()
    if subscription is None and local_subscription_id:
        subscription = queryset.filter(pk=local_subscription_id).first()
    if subscription is None:
        return None, 'Abonnement local introuvable pour cet événement Stripe.'

    subscription.stripe_subscription_id = (
        subscription_id or subscription.stripe_subscription_id
    )
    subscription.stripe_customer_id = (
        event.customer_id or subscription.stripe_customer_id
    )
    subscription.cancel_at_period_end = bool(
        event.cancel_at_period_end
    )
    subscription.auto_renew = (
        not subscription.cancel_at_period_end
        and event.event_type != 'customer.subscription.deleted'
        and event.subscription_status not in {'canceled', 'incomplete_expired'}
    )
    if event.current_period_end:
        subscription.expires_at = datetime.fromtimestamp(
            int(event.current_period_end),
            tz=datetime_timezone.utc,
        )
    if (
        event.event_type == 'customer.subscription.deleted'
        and subscription.expires_at <= timezone.now()
    ):
        subscription.status = 'expired'
    subscription.save(update_fields=[
        'stripe_subscription_id',
        'stripe_customer_id',
        'cancel_at_period_end',
        'auto_renew',
        'expires_at',
        'status',
        'updated_at',
    ])
    return None, ''


def apply_verified_payment_event(provider, event, payload):
    if provider == 'stripe':
        if event.event_type.startswith('invoice.'):
            if event.event_type not in {
                'invoice.paid',
                'invoice.payment_succeeded',
                'invoice.payment_failed',
            }:
                return None, ''
            with transaction.atomic():
                return _apply_stripe_invoice_event(event, payload)

        if event.event_type in {
            'customer.subscription.created',
            'customer.subscription.updated',
            'customer.subscription.deleted',
        }:
            with transaction.atomic():
                return _apply_stripe_subscription_event(event, payload)

        if event.event_type not in {
            'checkout.session.completed',
            'checkout.session.async_payment_succeeded',
            'checkout.session.async_payment_failed',
        }:
            return None, ''

    with transaction.atomic():
        payment = (
            Payment.objects
            .select_for_update()
            .select_related('subscription', 'subscription__user')
            .filter(
                provider=provider,
                provider_reference=event.provider_reference,
            )
            .first()
        )

        if not payment:
            return None, 'Paiement introuvable pour cette reference.'

        previous_status = payment.status

        # Stripe doit confirmer exactement le montant et la devise
        # enregistres localement lors de la creation du paiement.
        if provider == 'stripe' and event.successful:
            expected_currency = str(payment.currency or '').upper()
            expected_amount = _stripe_expected_minor_amount(
                payment.amount,
                expected_currency,
            )

            if event.amount is None:
                return None, (
                    'Montant Stripe absent du webhook.'
                )

            if not event.currency:
                return None, (
                    'Devise Stripe absente du webhook.'
                )

            if int(event.amount) != expected_amount:
                return None, (
                    'Montant Stripe incoherent avec le paiement attendu.'
                )

            if event.currency.upper() != expected_currency:
                return None, (
                    'Devise Stripe incoherente avec le paiement attendu.'
                )

        if provider == 'stripe' and event.recurring_checkout:
            payment.subscription.stripe_subscription_id = (
                event.subscription_id
                or payment.subscription.stripe_subscription_id
            )
            payment.subscription.stripe_customer_id = (
                event.customer_id
                or payment.subscription.stripe_customer_id
            )
            payment.subscription.save(update_fields=[
                'stripe_subscription_id',
                'stripe_customer_id',
                'updated_at',
            ])

        payment.provider_payment_id = (
            event.provider_payment_id
            or payment.provider_payment_id
        )
        payment.provider_payload = payload
        payment.verified_at = timezone.now()

        if event.successful:
            payment.status = 'success'
            payment.paid_at = payment.paid_at or timezone.now()

            if payment.subscription.status != 'active':
                payment.subscription.status = 'active'
                payment.subscription.save(
                    update_fields=['status', 'updated_at']
                )

            # Notification uniquement lors de la premiere transition
            # vers un paiement reussi.
            if previous_status != 'success':
                user = payment.subscription.user
                payment_id = str(payment.id)
                subscription_id = str(payment.subscription_id)

                transaction.on_commit(
                    lambda: notify_user(
                        user,
                        'subscription_created',
                        title='Abonnement active',
                        message=(
                            'Votre abonnement EkeFlicks est maintenant actif.'
                        ),
                        data={
                            'payment_id': payment_id,
                            'subscription_id': subscription_id,
                        },
                    )
                )

        elif event.failed:
            # Un evenement tardif ne doit jamais degrader
            # un paiement deja confirme comme reussi.
            if previous_status != 'success':
                payment.status = 'failed'

                # Notification uniquement lors de la premiere transition
                # vers failed.
                if previous_status != 'failed':
                    user = payment.subscription.user
                    payment_id = str(payment.id)
                    subscription_id = str(payment.subscription_id)

                    transaction.on_commit(
                        lambda: notify_user(
                            user,
                            'subscription_created',
                            title='Paiement refuse',
                            message=(
                                'Votre paiement n a pas pu etre valide.'
                            ),
                            data={
                                'payment_id': payment_id,
                                'subscription_id': subscription_id,
                            },
                        )
                    )

        payment.save(
            update_fields=[
                'provider_payment_id',
                'provider_payload',
                'verified_at',
                'status',
                'paid_at',
                'updated_at',
            ]
        )

        return payment, ''
