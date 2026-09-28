# core/models/analytics.py
import uuid
from django.db import models
from .profiles import Profile
from .content import Content
from .seasons import Episode
from .users import User


class ViewingSession(models.Model):
    """Sessions de visionnage"""
    profile = models.ForeignKey(Profile, on_delete=models.CASCADE, related_name='viewing_sessions')
    content = models.ForeignKey(Content, on_delete=models.CASCADE)
    episode = models.ForeignKey(Episode, on_delete=models.CASCADE, null=True, blank=True)
    session_id = models.UUIDField(default=uuid.uuid4, db_index=True)
    start_time = models.DateTimeField(auto_now_add=True)
    end_time = models.DateTimeField(null=True, blank=True)
    duration_watched = models.IntegerField(default=0, help_text="Durée en secondes")
    was_completed = models.BooleanField(default=False)
    device_type = models.CharField(max_length=50, blank=True)
    quality_played = models.CharField(max_length=20, blank=True)

    class Meta:
        db_table = 'viewing_sessions'
        indexes = [
            models.Index(fields=['profile', '-start_time']),
            models.Index(fields=['content']),
            models.Index(fields=['session_id']),
        ]

    def __str__(self):
        return f"{self.profile.name} - {self.content.title} - {self.start_time}"


class DailyStat(models.Model):
    """Statistiques quotidiennes"""
    stat_date = models.DateField(unique=True, db_index=True)
    total_users = models.IntegerField(default=0)
    active_users = models.IntegerField(default=0)
    total_views = models.BigIntegerField(default=0)
    total_watch_time = models.BigIntegerField(default=0, help_text="Secondes totales")
    new_subscriptions = models.IntegerField(default=0)
    revenue = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'daily_stats'
        ordering = ['-stat_date']

    def __str__(self):
        return f"{self.stat_date} - {self.active_users} actifs"


class ProducerRevenueSetting(models.Model):
    remuneration_enabled = models.BooleanField(default=True)
    eligible_progress_percent = models.DecimalField(max_digits=5, decimal_places=2, default=30)
    rate_per_1000_views_eur = models.DecimalField(max_digits=10, decimal_places=6, default=1.524490)
    advertising_share_percent = models.DecimalField(max_digits=5, decimal_places=2, default=60)
    minimum_payout_eur = models.DecimalField(max_digits=10, decimal_places=6, default=76.224509)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'producer_revenue_settings'

    def __str__(self):
        return f"{self.rate_per_1000_views_eur} EUR / 1000 views"


class ProducerAdvertisingRevenue(models.Model):
    """Net advertising revenue attributed to one producer film/content."""
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('requested', 'Requested'),
        ('paid', 'Paid'),
        ('void', 'Void'),
    ]
    producer = models.ForeignKey(User, on_delete=models.CASCADE, related_name='advertising_earnings')
    content = models.ForeignKey(Content, on_delete=models.CASCADE, related_name='producer_advertising_earnings')
    period = models.DateField(db_index=True)
    external_reference = models.CharField(max_length=120, blank=True)
    net_revenue_eur = models.DecimalField(max_digits=14, decimal_places=4)
    share_percent = models.DecimalField(max_digits=5, decimal_places=2, default=60)
    producer_share_eur = models.DecimalField(max_digits=14, decimal_places=4, default=0)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending', db_index=True)
    payout_request = models.ForeignKey(
        'ProducerPayoutRequest', on_delete=models.SET_NULL,
        related_name='advertising_earnings', null=True, blank=True,
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'producer_advertising_revenues'
        constraints = [
            models.UniqueConstraint(
                fields=['content', 'period', 'external_reference'],
                name='producer_ad_revenue_unique_ref',
            ),
            models.CheckConstraint(
                check=models.Q(net_revenue_eur__gte=0),
                name='producer_ad_net_nonnegative',
            ),
            models.CheckConstraint(
                check=models.Q(share_percent__gte=0) & models.Q(share_percent__lte=100),
                name='producer_ad_share_0_100',
            ),
        ]

    def save(self, *args, **kwargs):
        from django.core.exceptions import ValidationError
        from decimal import Decimal, ROUND_HALF_UP
        if self.content_id and self.producer_id:
            owner_id = Content.objects.filter(pk=self.content_id).values_list(
                'producer_id', flat=True
            ).first()
            if owner_id != self.producer_id:
                raise ValidationError('La rémunération publicitaire doit appartenir au producteur du contenu.')
        if Decimal(self.net_revenue_eur) < 0:
            raise ValidationError('Le revenu publicitaire net ne peut pas être négatif.')
        if self._state.adding:
            setting_share = ProducerRevenueSetting.objects.filter(pk=1).values_list(
                'advertising_share_percent', flat=True
            ).first()
            if setting_share is not None:
                self.share_percent = setting_share
        self.producer_share_eur = (
            Decimal(self.net_revenue_eur) * Decimal(self.share_percent) / Decimal('100')
        ).quantize(Decimal('0.0001'), rounding=ROUND_HALF_UP)
        super().save(*args, **kwargs)


class ProducerCountryCurrency(models.Model):
    country_code = models.CharField(max_length=2, unique=True)
    currency = models.CharField(max_length=3, default='EUR')
    eur_to_currency_rate = models.DecimalField(max_digits=12, decimal_places=6, default=1)
    is_active = models.BooleanField(default=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'producer_country_currencies'
        ordering = ['country_code']

    def __str__(self):
        return f"{self.country_code} -> {self.currency}"


class ProducerContentView(models.Model):
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('requested', 'Requested'),
        ('paid', 'Paid'),
        ('void', 'Void'),
    ]

    viewing_session = models.OneToOneField(
        ViewingSession,
        on_delete=models.CASCADE,
        related_name='producer_view',
    )
    producer = models.ForeignKey(User, on_delete=models.CASCADE, related_name='producer_views')
    content = models.ForeignKey(Content, on_delete=models.CASCADE, related_name='producer_views')
    episode = models.ForeignKey(Episode, on_delete=models.SET_NULL, null=True, blank=True)
    payout_request = models.ForeignKey(
        'ProducerPayoutRequest',
        on_delete=models.SET_NULL,
        related_name='producer_views',
        null=True,
        blank=True,
    )
    watched_seconds = models.PositiveIntegerField(default=0)
    total_seconds = models.PositiveIntegerField(default=0)
    progress_percent = models.DecimalField(max_digits=5, decimal_places=2, default=0)
    viewer_country_code = models.CharField(max_length=2, blank=True)
    amount_eur = models.DecimalField(max_digits=14, decimal_places=9, default=0)
    currency = models.CharField(max_length=3, default='EUR')
    amount_local = models.DecimalField(max_digits=12, decimal_places=6, default=0)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    counted_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'producer_content_views'
        indexes = [
            models.Index(fields=['producer', 'status']),
            models.Index(fields=['content', 'counted_at']),
            models.Index(fields=['viewer_country_code', 'counted_at']),
        ]

    def __str__(self):
        return f"{self.content.title} - {self.producer.email} - {self.amount_eur} EUR"
