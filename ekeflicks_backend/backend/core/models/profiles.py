# core/models/profiles.py
import uuid

from django.db import models
from .base import TimeStampedModel
from .users import User


class ProfileType(models.Model):
    """Types de profils"""
    name = models.CharField(max_length=50, unique=True)
    description = models.TextField(blank=True)
    max_age_restriction = models.IntegerField(null=True, blank=True)
    can_create_lists = models.BooleanField(default=True)
    can_rate_content = models.BooleanField(default=True)

    class Meta:
        db_table = 'profile_types'

    def __str__(self):
        return self.name


class Profile(TimeStampedModel):
    """Profils utilisateur"""
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='profiles')
    type = models.ForeignKey(ProfileType, on_delete=models.CASCADE)
    name = models.CharField(max_length=100)
    avatar_url = models.URLField(max_length=500, blank=True)
    age = models.IntegerField(null=True, blank=True)
    allowed_min_age = models.PositiveSmallIntegerField(default=0)
    allowed_max_age = models.PositiveSmallIntegerField(default=13)
    phone = models.CharField(max_length=20, blank=True)
    country_code = models.CharField(max_length=2, blank=True)
    # Stores Django's salted password hash, never the parental PIN itself.
    pin_code = models.CharField(max_length=128, blank=True)
    adult_profiles_locked = models.BooleanField(default=False)
    child_history_enabled = models.BooleanField(default=True)
    safe_search_enabled = models.BooleanField(default=True)
    is_active = models.BooleanField(default=True)

    class Meta:
        db_table = 'profiles'
        unique_together = ['user', 'name']
        indexes = [
            models.Index(fields=['user']),
            models.Index(fields=['type']),
        ]

    def __str__(self):
        return f"{self.user.email} - {self.name}"


class ParentalPinResetToken(TimeStampedModel):
    """
    Token pour la réinitialisation du PIN parental.
    Valable 30 minutes, à usage unique.
    """
    profile = models.ForeignKey(
        Profile,
        on_delete=models.CASCADE,
        related_name='pin_reset_tokens'
    )
    token = models.UUIDField(
        default=uuid.uuid4,
        unique=True,
        editable=False
    )
    expires_at = models.DateTimeField()
    used_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = 'parental_pin_reset_tokens'
        indexes = [
            models.Index(fields=['token']),
            models.Index(fields=['profile', 'expires_at']),
        ]

    def __str__(self):
        return f"PIN reset for {self.profile.name} - {self.token}"
