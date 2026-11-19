import base64
import hashlib
import hmac
import struct
import time

from rest_framework.permissions import BasePermission
from django.utils import timezone


def totp(secret, counter=None):
    """Return the RFC 6238 six-digit code for a hex-encoded secret."""
    counter = int(time.time() // 30) if counter is None else counter
    key = bytes.fromhex(secret)
    digest = hmac.new(key, struct.pack('>Q', counter), hashlib.sha1).digest()
    offset = digest[-1] & 15
    value = (struct.unpack('>I', digest[offset:offset + 4])[0] & 0x7fffffff) % 1000000
    return f'{value:06d}'


def verify_totp(device, code):
    current = int(time.time() // 30)
    for counter in range(current - 1, current + 2):
        if counter > device.last_counter and hmac.compare_digest(totp(device.secret, counter), str(code)):
            device.last_counter = counter
            device.save(update_fields=['last_counter', 'updated_at'])
            return True
    return False


def provisioning_uri(device):
    secret = base64.b32encode(bytes.fromhex(device.secret)).decode().rstrip('=')
    account = device.user.email or str(device.user_id)
    return f'otpauth://totp/EkeFlicks:{account}?secret={secret}&issuer=EkeFlicks&algorithm=SHA1&digits=6&period=30'


class AdminPermission(BasePermission):
    permission = None

    def has_permission(self, request, view):
        user = request.user
        payload = getattr(request.auth, 'payload', {})
        session_id = payload.get('sid') if payload else None
        if not session_id:
            return False
        from core.models.users import UserSession
        if not UserSession.objects.filter(
            pk=session_id, user=user, is_active=True, is_admin=True,
            expires_at__gt=timezone.now(),
        ).exists():
            return False
        resolver = getattr(view, 'get_required_permission', None)
        required = resolver() if resolver else getattr(view, 'required_permission', self.permission)
        return bool(user.is_authenticated and user.is_staff and (user.is_superuser or not required or user.has_perm(required)))


def audit(request, action, target, metadata=None):
    from core.models.users import AdminAuditLog
    forwarded = request.META.get('HTTP_X_FORWARDED_FOR', '').split(',')[0].strip()
    AdminAuditLog.objects.create(
        actor=request.user,
        action=action,
        target_type=target.__class__.__name__,
        target_id=str(getattr(target, 'pk', '')),
        metadata=metadata or {},
        ip_address=forwarded or request.META.get('REMOTE_ADDR') or None,
    )
