# core/models/recommendations.py
import uuid
from django.db import models
from .profiles import Profile
from .content import Content


class Recommendation(models.Model):
    """Recommandations IA"""
    REASON_CHOICES = [
        ('similar_genre', 'Genres similaires'),
        ('trending', 'Tendance'),
        ('because_you_watched', 'Parce que vous avez regardé'),
        ('popular', 'Populaire'),
        ('ai_match', 'Correspondance IA'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    profile = models.ForeignKey(Profile, on_delete=models.CASCADE, related_name='recommendations')
    content = models.ForeignKey(Content, on_delete=models.CASCADE)
    score = models.DecimalField(max_digits=5, decimal_places=2, default=0)
    reason = models.CharField(max_length=50, choices=REASON_CHOICES, blank=True)
    is_viewed = models.BooleanField(default=False)
    expires_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'recommendations'
        unique_together = ['profile', 'content']
        indexes = [
            models.Index(fields=['profile', '-score']),
        ]

    def __str__(self):
        return f"{self.profile.name} - {self.content.title}: {self.score}"


class TrendingCache(models.Model):
    """Cache des tendances"""
    PERIOD_CHOICES = [
        ('day', 'Jour'),
        ('week', 'Semaine'),
        ('month', 'Mois'),
    ]

    content = models.ForeignKey(Content, on_delete=models.CASCADE)
    score = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    period = models.CharField(max_length=20, choices=PERIOD_CHOICES)
    rank = models.IntegerField(null=True, blank=True)
    calculated_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'trending_cache'
        unique_together = ['content', 'period']
        indexes = [
            models.Index(fields=['period', '-score']),
        ]

    def __str__(self):
        return f"{self.content.title} - {self.period}: {self.score}"


class ContentSimilarity(models.Model):
    """Similarité entre contenus"""
    content_1 = models.ForeignKey(Content, on_delete=models.CASCADE, related_name='similar_to')
    content_2 = models.ForeignKey(Content, on_delete=models.CASCADE, related_name='similar_from')
    similarity_score = models.DecimalField(max_digits=5, decimal_places=4)
    calculated_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'content_similarity'
        unique_together = ['content_1', 'content_2']
        indexes = [
            models.Index(fields=['-similarity_score']),
        ]

    def __str__(self):
        return f"{self.content_1.title} <-> {self.content_2.title}: {self.similarity_score}"
