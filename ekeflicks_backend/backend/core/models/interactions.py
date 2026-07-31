# core/models/interactions.py
from django.db import models
from .base import TimeStampedModel
from .profiles import Profile
from .content import Content
from .seasons import Episode


class WatchHistory(models.Model):
    """Historique de visionnage"""
    profile = models.ForeignKey(Profile, on_delete=models.CASCADE, related_name='watch_history')
    content = models.ForeignKey(Content, on_delete=models.CASCADE)
    episode = models.ForeignKey(Episode, on_delete=models.CASCADE, null=True, blank=True)
    progress = models.IntegerField(default=0, help_text="Pourcentage 0-100")
    last_position = models.IntegerField(default=0, help_text="Position en secondes")
    watched_duration = models.IntegerField(default=0, help_text="Durée regardée en secondes")
    completed = models.BooleanField(default=False)
    watched_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'watch_history'
        indexes = [
            models.Index(fields=['profile', '-updated_at']),
            models.Index(fields=['content']),
        ]

    def __str__(self):
        episode_info = f" - E{self.episode.episode_number}" if self.episode else ""
        return f"{self.profile.name} - {self.content.title}{episode_info}: {self.progress}%"


class Favorite(models.Model):
    """Favoris"""
    profile = models.ForeignKey(Profile, on_delete=models.CASCADE, related_name='favorites')
    content = models.ForeignKey(Content, on_delete=models.CASCADE)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'favorites'
        unique_together = ['profile', 'content']

    def __str__(self):
        return f"{self.profile.name} - {self.content.title}"


class Rating(TimeStampedModel):
    """Notes et avis"""
    profile = models.ForeignKey(Profile, on_delete=models.CASCADE, related_name='ratings')
    content = models.ForeignKey(Content, on_delete=models.CASCADE, related_name='ratings')
    rating = models.DecimalField(max_digits=2, decimal_places=1)
    review = models.TextField(blank=True)

    class Meta:
        db_table = 'ratings'
        unique_together = ['profile', 'content']
        indexes = [
            models.Index(fields=['content', '-rating']),
        ]

    def __str__(self):
        return f"{self.profile.name} - {self.content.title}: {self.rating}/5"
