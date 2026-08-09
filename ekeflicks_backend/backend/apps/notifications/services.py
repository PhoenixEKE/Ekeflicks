from email.mime.image import MIMEImage
from django.conf import settings
from django.contrib.staticfiles import finders
from django.core.mail import EmailMultiAlternatives
from django.utils.html import escape
from django.utils import timezone

from core.models import Notification, NotificationType, User


EVENT_DEFAULTS = {
    'account_created': ('Bienvenue sur EkeFlicks', 'Votre compte EkeFlicks a ete cree.'),
    'email_verification': ('Validez votre email', 'Cliquez sur le lien de validation envoye par EkeFlicks.'),
    'password_reset': ('Reinitialisation du mot de passe', 'Cliquez sur le lien pour changer votre mot de passe.'),
    'password_changed': ('Mot de passe modifie', 'Votre mot de passe EkeFlicks a bien ete modifie.'),
    'parental_pin_reset': ('Reinitialisation du PIN parental', 'Utilisez le lien pour modifier votre PIN parental.'),
    'parental_pin_changed': ('PIN parental modifie', 'Votre PIN parental EkeFlicks a bien ete modifie.'),
    'email_change_support_requested': ('Demande de changement email recue', 'Le support EkeFlicks traitera votre demande.'),
    'email_change_support_resolved': ('Demande de changement email resolue', 'Le support EkeFlicks a traite votre demande.'),
    'email_change_support_rejected': ('Demande de changement email refusee', 'Le support EkeFlicks a refuse votre demande.'),
    'subscription_created': ('Abonnement cree', 'Votre demande d abonnement a ete creee.'),
    'content_submitted': ('Depot recu', 'Votre contenu a ete soumis a validation.'),
    'content_approved': ('Contenu valide', 'Votre contenu a ete valide.'),
    'content_rejected': ('Contenu refuse', 'Votre contenu a ete refuse.'),
    'video_uploaded': ('Source video recue', 'Votre source video a ete deposee.'),
    'video_approved': ('Video validee', 'Votre video a ete validee.'),
    'video_rejected': ('Video refusee', 'Votre video a ete refusee.'),
    'content_published': ('Nouveau contenu publie', 'Un nouveau film ou une nouvelle serie est disponible.'),
    'producer_payout_requested': ('Demande de paiement recue', 'Votre demande de paiement producteur a ete creee.'),
    'producer_payout_approved': ('Paiement producteur valide', 'Votre demande de paiement producteur a ete validee.'),
    'producer_payout_rejected': ('Paiement producteur refuse', 'Votre demande de paiement producteur a ete refusee.'),
    'account_closure_requested': ('Demande de fermeture recue', 'Votre demande de fermeture de compte a ete enregistree.'),
}


def _email_html(title, message):
    """Return a responsive, dark streaming-style transactional email."""
    safe_title = escape(title)
    safe_message = escape(message).replace('\n', '<br>')
    logo_url = getattr(settings, 'EMAIL_LOGO_URL', '')
    logo = (
        f'<img src="{escape(logo_url)}" width="150" alt="EkeFlicks" style="display:block;border:0">'
        if logo_url else '<img src="cid:logo_dark.png" width="150" alt="EkeFlicks" style="display:block;border:0">'
    )
    return f'''<!doctype html><html><body style="margin:0;background:#141414;color:#fff;font-family:Arial,sans-serif">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#141414"><tr><td align="center" style="padding:32px 16px">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="max-width:600px;background:#1f1f1f;border-radius:8px">
<tr><td style="padding:30px 36px;border-bottom:1px solid #333">{logo}</td></tr>
<tr><td style="padding:38px 36px"><h1 style="margin:0 0 20px;font-size:28px">{safe_title}</h1>
<p style="margin:0;color:#d2d2d2;font-size:16px;line-height:1.65">{safe_message}</p></td></tr>
<tr><td style="padding:22px 36px;color:#888;font-size:12px;border-top:1px solid #333">EkeFlicks · Votre divertissement, partout.</td></tr>
</table></td></tr></table></body></html>'''


def _notification_type(event_name, email_enabled=True):
    title, message = EVENT_DEFAULTS.get(event_name, (event_name, ''))
    notification_type, _created = NotificationType.objects.get_or_create(
        name=event_name,
        defaults={
            'template': message,
            'is_push_enabled': True,
            'is_email_enabled': email_enabled,
        },
    )
    return notification_type, title, message


def _attach_email_logo(email):
    """Embed the logo so mail clients do not depend on a public asset URL."""
    if getattr(settings, 'EMAIL_LOGO_URL', ''):
        return
    logo_path = finders.find('notifications/images/logo_dark.png')
    if not logo_path:
        return
    with open(logo_path, 'rb') as logo_file:
        logo = MIMEImage(logo_file.read(), _subtype='png')
    logo.add_header('Content-ID', '<logo_dark.png>')
    logo.add_header('Content-Disposition', 'inline', filename='logo_dark.png')
    email.attach(logo)


def notify_user(user, event_name, title='', message='', data=None, email_enabled=True):
    if not user or not getattr(user, 'is_authenticated', True):
        return None

    notification_type, default_title, default_message = _notification_type(
        event_name,
        email_enabled=email_enabled,
    )
    payload = data or {}
    notification = Notification.objects.create(
        user=user,
        type=notification_type,
        title=title or default_title,
        message=message or default_message,
        data=payload,
    )

    should_email = email_enabled and notification_type.is_email_enabled and bool(user.email)
    if should_email:
        try:
            email = EmailMultiAlternatives(
                notification.title,
                notification.message,
                getattr(settings, 'DEFAULT_FROM_EMAIL', 'noreply@ekeflicks.com'),
                [user.email],
            )
            email.attach_alternative(_email_html(notification.title, notification.message), 'text/html')
            # A related multipart is required for cid: images to render as
            # inline HTML resources rather than ordinary attachments.
            email.mixed_subtype = 'related'
            _attach_email_logo(email)
            email.send(fail_silently=True)
            notification.is_sent = True
            notification.sent_at = timezone.now()
            notification.save(update_fields=['is_sent', 'sent_at'])
        except Exception:
            pass

    return notification


def notify_staff(event_name, title='', message='', data=None):
    notifications = []
    for user in User.objects.filter(is_staff=True, is_active=True):
        notifications.append(notify_user(user, event_name, title, message, data))
    return notifications


def notify_new_publication(content):
    producer = getattr(content, 'producer', None)
    if producer:
        notify_user(
            producer,
            'content_published',
            title='Votre contenu est publie',
            message=f"{content.title} est maintenant disponible sur EkeFlicks.",
            data={'content_id': str(content.id)},
        )

    for user in User.objects.filter(is_active=True, is_staff=False)[:500]:
        notify_user(
            user,
            'content_published',
            title='Nouveau sur EkeFlicks',
            message=f"{content.title} est disponible.",
            data={'content_id': str(content.id)},
            email_enabled=False,
        )
