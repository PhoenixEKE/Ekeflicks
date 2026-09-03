from django.conf import settings
from django.db import transaction
from django.urls import reverse
from django.utils import timezone
from urllib.parse import urlencode

from apps.notifications.services import notify_staff, notify_user
from core.models import (
    AccountClosureRequest,
    EmailChangeSupportRequest,
    EmailVerificationToken,
    PasswordResetToken,
    Subscription,
    User,
)


def _absolute_link(request, route_name, token):
    path = f"{reverse(route_name)}?token={token}"
    if request:
        return request.build_absolute_uri(path)
    api_base = getattr(settings, 'API_BASE_URL', '').rstrip('/')
    return f"{api_base}{path}" if api_base else path


def _frontend_link(token, path_setting, default_path, action=None):
    base_url = getattr(settings, 'FRONTEND_BASE_URL', '').rstrip('/')
    if not base_url:
        return ''

    path = getattr(settings, path_setting, default_path) or default_path
    
    # LWS does not rewrite arbitrary paths (such as /reset-password) to the
    # Flutter index. Reset links therefore target the existing root document
    # and let the application select the screen from the action parameter.
    if action:
        path = '/'
    
    if not path.startswith('/'):
        path = f"/{path}"

    separator = '&' if '?' in path else '?'
    parameters = {'token': str(token)}
    if action:
        parameters = {'action': action, **parameters}
    return f"{base_url}{path}{separator}{urlencode(parameters)}"


def _producer_email_verification_link(token):
    base_url = getattr(
        settings,
        'PRODUCER_FRONTEND_BASE_URL',
        'https://producteurs.ekeflicks.com',
    ).rstrip('/')

    parameters = urlencode({'token': str(token)})

    return f"{base_url}/#/verify-email?{parameters}"


def _email_verification_link(request, token, user=None):
    if user is not None and getattr(user, 'is_producer', False):
        return _producer_email_verification_link(token)

    return (
        _frontend_link(token, 'EMAIL_VERIFICATION_FRONTEND_PATH', '/verify-email')
        or _absolute_link(request, 'verify-email', token)
    )


def _password_reset_link(request, token):
    return (
        _frontend_link(
            token,
            'PASSWORD_RESET_FRONTEND_PATH',
            '/?action=reset-password',
        )
        or _absolute_link(request, 'password-reset-confirm', token)
    )


def email_verification_expires_at():
    hours = getattr(settings, 'EMAIL_VERIFICATION_TOKEN_TTL_HOURS', 24)
    return timezone.now() + timezone.timedelta(hours=hours)


def password_reset_expires_at():
    minutes = getattr(settings, 'PASSWORD_RESET_TOKEN_TTL_MINUTES', 30)
    return timezone.now() + timezone.timedelta(minutes=minutes)


def send_email_verification(user, request=None):
    token = EmailVerificationToken.objects.create(
        user=user,
        expires_at=email_verification_expires_at(),
    )
    link = _email_verification_link(request, token.token, user=user)
    notify_user(
        user,
        'email_verification',
        title='Validez votre email EkeFlicks',
        message=f"Validez votre adresse email avec ce lien: {link}",
        data={'verification_token_id': str(token.id), 'verification_link': link},
    )
    return token


def verify_email_token(token_value):
    token = (
        EmailVerificationToken.objects.select_related('user')
        .filter(token=token_value, used_at__isnull=True, expires_at__gt=timezone.now())
        .first()
    )
    if not token:
        return None

    token.used_at = timezone.now()
    token.save(update_fields=['used_at', 'updated_at'])
    token.user.is_verified = True
    token.user.save(update_fields=['is_verified', 'updated_at'])
    return token.user


def send_password_reset(user, request=None):
    token = PasswordResetToken.objects.create(
        user=user,
        expires_at=password_reset_expires_at(),
    )
    link = _password_reset_link(request, token.token)
    notify_user(
        user,
        'password_reset',
        title='Changer votre mot de passe EkeFlicks',
        message=f"Changez votre mot de passe avec ce lien: {link}",
        data={'password_reset_token_id': str(token.id), 'password_reset_link': link},
    )
    return token


def reset_password(token_value, password):
    token = (
        PasswordResetToken.objects.select_related('user')
        .filter(token=token_value, used_at__isnull=True, expires_at__gt=timezone.now())
        .first()
    )
    if not token:
        return None

    token.user.set_password(password)
    token.user.save(update_fields=['password', 'updated_at'])
    token.used_at = timezone.now()
    token.save(update_fields=['used_at', 'updated_at'])
    return token.user


def create_email_change_support_request(user, requested_email, reason=''):
    support_request = EmailChangeSupportRequest.objects.create(
        user=user,
        requested_email=requested_email,
        reason=reason,
    )
    notify_user(
        user,
        'email_change_support_requested',
        data={'email_change_request_id': str(support_request.id), 'requested_email': requested_email},
    )
    notify_staff(
        'email_change_support_requested',
        title='Demande de changement email',
        message=f"{user.email} demande a remplacer son email par {requested_email}.",
        data={'email_change_request_id': str(support_request.id), 'user_id': str(user.id)},
    )
    return support_request


def default_closure_date():
    days = getattr(settings, 'ACCOUNT_CLOSURE_GRACE_DAYS', 7)
    return timezone.now() + timezone.timedelta(days=days)


def create_account_closure_request(user, request_type, reason='', requested_for=None):
    closure_request = AccountClosureRequest.objects.create(
        user=user,
        request_type=request_type,
        reason=reason,
        status='approved',
        requested_for=requested_for or default_closure_date(),
    )
    notify_user(
        user,
        'account_closure_requested',
        data={
            'closure_request_id': str(closure_request.id),
            'request_type': request_type,
            'requested_for': closure_request.requested_for.isoformat() if closure_request.requested_for else None,
        },
    )
    return closure_request


@transaction.atomic
def process_account_closure_request(closure_request):
    if closure_request.status not in {'approved', 'pending'}:
        return closure_request

    user = closure_request.user
    if closure_request.request_type == 'cancel_subscription':
        Subscription.objects.filter(
            user=user,
            status__in=['active', 'pending'],
        ).update(
            status='cancelled',
            cancelled_at=timezone.now(),
            auto_renew=False,
        )
    elif closure_request.request_type == 'deactivate_account':
        user.is_active = False
        user.save(update_fields=['is_active', 'updated_at'])
        Subscription.objects.filter(
            user=user,
            status__in=['active', 'pending'],
        ).update(status='cancelled', cancelled_at=timezone.now(), auto_renew=False)
    elif closure_request.request_type == 'delete_account':
        Subscription.objects.filter(user=user).update(
            status='cancelled',
            cancelled_at=timezone.now(),
            auto_renew=False,
        )
        user.email = f"deleted-{user.id}@deleted.ekeflicks.local"
        user.firstname = ''
        user.lastname = ''
        user.phone = ''
        user.is_active = False
        user.preferences = {}
        user.save(update_fields=[
            'email',
            'firstname',
            'lastname',
            'phone',
            'is_active',
            'preferences',
            'updated_at',
        ])

    closure_request.status = 'processed'
    closure_request.processed_at = timezone.now()
    closure_request.save(update_fields=['status', 'processed_at', 'updated_at'])
    return closure_request


def process_due_account_closure_requests(now=None):
    current = now or timezone.now()
    processed = 0
    queryset = AccountClosureRequest.objects.filter(
        status='approved',
        requested_for__lte=current,
    ).select_related('user')
    for closure_request in queryset:
        process_account_closure_request(closure_request)
        processed += 1
    return processed
