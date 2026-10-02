from django.conf import settings
from django.db import models

from .base import TimeStampedModel


class ProducerFinanceAccess(TimeStampedModel):
    """PIN and email second-factor state for producer financial information."""
    producer = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='finance_access',
    )
    pin_hash = models.CharField(max_length=128, blank=True)
    pending_pin_hash = models.CharField(max_length=128, blank=True)
    challenge_hash = models.CharField(max_length=128, blank=True)
    challenge_purpose = models.CharField(max_length=16, blank=True)
    challenge_expires_at = models.DateTimeField(null=True, blank=True)
    challenge_attempts = models.PositiveSmallIntegerField(default=0)
    pin_attempts = models.PositiveSmallIntegerField(default=0)
    pin_locked_until = models.DateTimeField(null=True, blank=True)
    unlocked_until = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = 'producer_finance_access'
