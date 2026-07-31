# core/models/profiles.py
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
    phone = models.CharField(max_length=20, blank=True)
    country_code = models.CharField(max_length=2, blank=True)
    pin_code = models.CharField(max_length=6, blank=True)
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
