# core/models/seasons.py
from django.db import models
from .base import TimeStampedModel
from .content import Content


class Season(TimeStampedModel):
    """Saisons"""
    content = models.ForeignKey(Content, on_delete=models.CASCADE, related_name='seasons')
    season_number = models.IntegerField()
    title = models.CharField(max_length=255, blank=True)
    episode_count = models.IntegerField(default=0)

    class Meta:
        db_table = 'seasons'
        unique_together = ['content', 'season_number']
        ordering = ['season_number']

    def __str__(self):
        return f"{self.content.title} - S{self.season_number}"


class Episode(TimeStampedModel):
    """Épisodes"""
    season = models.ForeignKey(Season, on_delete=models.CASCADE, related_name='episodes')
    content = models.ForeignKey(Content, on_delete=models.CASCADE, related_name='episodes')
    episode_number = models.IntegerField()
    title = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    duration = models.IntegerField(null=True, blank=True, help_text="Durée en minutes")
    video_url = models.URLField(max_length=500, blank=True)
    thumbnail_url = models.URLField(max_length=500, blank=True)

    class Meta:
        db_table = 'episodes'
        unique_together = ['season', 'episode_number']
        ordering = ['episode_number']

    def __str__(self):
        return f"{self.season.content.title} - S{self.season.season_number}E{self.episode_number}: {self.title}"
