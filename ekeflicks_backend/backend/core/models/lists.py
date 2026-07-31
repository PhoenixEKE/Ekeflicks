# core/models/lists.py
from django.db import models
from .base import TimeStampedModel
from .profiles import Profile
from .content import Content


class CustomList(TimeStampedModel):
    """Listes personnalisées"""
    profile = models.ForeignKey(Profile, on_delete=models.CASCADE, related_name='custom_lists')
    name = models.CharField(max_length=100)
    description = models.TextField(blank=True)
    is_public = models.BooleanField(default=False)

    class Meta:
        db_table = 'custom_lists'

    def __str__(self):
        return f"{self.profile.name} - {self.name}"


class ListItem(models.Model):
    """Éléments des listes"""
    list = models.ForeignKey(CustomList, on_delete=models.CASCADE, related_name='items')
    content = models.ForeignKey(Content, on_delete=models.CASCADE)
    added_order = models.IntegerField(default=0)
    added_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'list_items'
        unique_together = ['list', 'content']

    def __str__(self):
        return f"{self.list.name}: {self.content.title}"
