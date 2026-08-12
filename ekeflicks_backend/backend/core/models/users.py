import uuid
import re
import secrets

from django.db import models
from django.contrib.auth.models import AbstractBaseUser, PermissionsMixin, BaseUserManager
from django.db import models
from .base import TimeStampedModel


def normalize_phone_number(value):
    """Normalize an international phone number to a compact E.164 form."""
    phone = re.sub(r'[\s().-]', '', (value or '').strip())
    if not re.fullmatch(r'\+[1-9]\d{7,14}', phone):
        raise ValueError("Phone must include its country calling code, for example +2250102030405")
    return phone


COUNTRY_CALLING_CODES = {
    '225': 'CI', '221': 'SN', '237': 'CM', '261': 'MG', '212': 'MA',
    '216': 'TN', '213': 'DZ', '33': 'FR', '32': 'BE', '41': 'CH',
    '44': 'GB', '49': 'DE', '39': 'IT', '34': 'ES', '1': 'US',
}


def generate_mfa_secret():
    return secrets.token_hex(20)


def country_code_from_phone(value):
    """Infer an ISO country code from an E.164 calling code when possible."""
    digits = normalize_phone_number(value)[1:]
    for prefix in sorted(COUNTRY_CALLING_CODES, key=len, reverse=True):
        if digits.startswith(prefix):
            return COUNTRY_CALLING_CODES[prefix]
    return ''


class UserManager(BaseUserManager):
    def create_user(self, email=None, password=None, **extra_fields):
        phone = str(extra_fields.get('phone') or '').strip()
        if not email and not phone:
            raise ValueError("Email or phone required")
        email = self.normalize_email(email) if email else None
        preferences = dict(extra_fields.get('preferences') or {})
        preferences.setdefault('registration_identifier', 'email' if email else 'phone')
        extra_fields['preferences'] = preferences
        extra_fields['phone'] = normalize_phone_number(phone) if phone else ''
        if phone and not extra_fields.get('country_code'):
            extra_fields['country_code'] = country_code_from_phone(phone)
        user = self.model(email=email, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, email, password=None, **extra_fields):
        extra_fields.setdefault("is_staff", True)
        extra_fields.setdefault("is_superuser", True)
        extra_fields.setdefault("is_active", True)
        return self.create_user(email, password, **extra_fields)


class User(AbstractBaseUser, PermissionsMixin, TimeStampedModel):
    email = models.EmailField(unique=True, null=True, blank=True)
    firstname = models.CharField(max_length=100, blank=True)
    lastname = models.CharField(max_length=100, blank=True)
    phone = models.CharField(max_length=20, blank=True)
    country_code = models.CharField(max_length=2, blank=True)

    is_active = models.BooleanField(default=True)
    is_verified = models.BooleanField(default=False)
    is_staff = models.BooleanField(default=False)
    is_producer = models.BooleanField(default=False)
    producer_company = models.CharField(max_length=255, blank=True)
    producer_remuneration_enabled = models.BooleanField(default=True)

    preferences = models.JSONField(default=dict)

    objects = UserManager()

    USERNAME_FIELD = "email"
    REQUIRED_FIELDS = []

    def __str__(self):
        return self.email or self.phone


class UserSession(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    device_id = models.CharField(max_length=255, blank=True)
    device_type = models.CharField(max_length=50)
    refresh_token = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField()
    is_active = models.BooleanField(default=True)

    def __str__(self):
        return f"{self.user.email} - {self.device_type}"


class AdminMFADevice(TimeStampedModel):
    """TOTP second factor attached to a privileged account."""

    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='admin_mfa_device')
    secret = models.CharField(max_length=64, default=generate_mfa_secret)
    confirmed_at = models.DateTimeField(null=True, blank=True)
    last_counter = models.BigIntegerField(default=-1)

    class Meta:
        db_table = 'admin_mfa_devices'


class AdminAuditLog(TimeStampedModel):
    """Append-only attribution trail for privileged changes."""

    actor = models.ForeignKey(User, on_delete=models.PROTECT, related_name='admin_audit_logs')
    action = models.CharField(max_length=120)
    target_type = models.CharField(max_length=80)
    target_id = models.CharField(max_length=80, blank=True)
    metadata = models.JSONField(default=dict, blank=True)
    ip_address = models.GenericIPAddressField(null=True, blank=True)

    class Meta:
        db_table = 'admin_audit_logs'
        ordering = ('-created_at',)


class AccountClosureRequest(TimeStampedModel):
    REQUEST_CHOICES = [
        ('deactivate_account', 'Deactivate account'),
        ('delete_account', 'Delete account'),
        ('cancel_subscription', 'Cancel subscription'),
    ]
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('approved', 'Approved'),
        ('rejected', 'Rejected'),
        ('cancelled', 'Cancelled'),
        ('processed', 'Processed'),
    ]

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='closure_requests')
    request_type = models.CharField(max_length=30, choices=REQUEST_CHOICES)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    reason = models.TextField(blank=True)
    admin_reason = models.TextField(blank=True)
    requested_for = models.DateTimeField(null=True, blank=True)
    reviewed_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        related_name='reviewed_closure_requests',
        null=True,
        blank=True
    )
    reviewed_at = models.DateTimeField(null=True, blank=True)
    processed_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = 'account_closure_requests'
        indexes = [
            models.Index(fields=['user', 'status']),
            models.Index(fields=['request_type', 'status']),
            models.Index(fields=['requested_for']),
        ]

    def __str__(self):
        return f"{self.user.email} - {self.request_type} ({self.status})"


class EmailVerificationToken(TimeStampedModel):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='email_verification_tokens')
    token = models.UUIDField(default=uuid.uuid4, unique=True, editable=False)
    expires_at = models.DateTimeField()
    used_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = 'email_verification_tokens'
        indexes = [
            models.Index(fields=['token']),
            models.Index(fields=['user', 'used_at']),
            models.Index(fields=['expires_at']),
        ]

    def __str__(self):
        return f"{self.user.email} - email verification"


class PasswordResetToken(TimeStampedModel):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='password_reset_tokens')
    token = models.UUIDField(default=uuid.uuid4, unique=True, editable=False)
    expires_at = models.DateTimeField()
    used_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = 'password_reset_tokens'
        indexes = [
            models.Index(fields=['token']),
            models.Index(fields=['user', 'used_at']),
            models.Index(fields=['expires_at']),
        ]

    def __str__(self):
        return f"{self.user.email} - password reset"


class EmailChangeSupportRequest(TimeStampedModel):
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('resolved', 'Resolved'),
        ('rejected', 'Rejected'),
        ('cancelled', 'Cancelled'),
    ]

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='email_change_requests')
    requested_email = models.EmailField()
    reason = models.TextField(blank=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    admin_reason = models.TextField(blank=True)
    reviewed_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        related_name='reviewed_email_change_requests',
        null=True,
        blank=True
    )
    reviewed_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = 'email_change_support_requests'
        indexes = [
            models.Index(fields=['user', 'status']),
            models.Index(fields=['requested_email']),
        ]

    def __str__(self):
        return f"{self.user.email} -> {self.requested_email} ({self.status})"
