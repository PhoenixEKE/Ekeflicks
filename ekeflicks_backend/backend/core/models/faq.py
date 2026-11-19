from django.db import models

from .base import TimeStampedModel


class FrequentlyAskedQuestion(TimeStampedModel):
    AUDIENCE_PRODUCER = 'producer'
    AUDIENCE_CLIENT = 'client'
    AUDIENCE_ADMIN = 'admin'
    AUDIENCE_CHOICES = [
        (AUDIENCE_PRODUCER, 'Producteurs'),
        (AUDIENCE_CLIENT, 'Clients'),
        (AUDIENCE_ADMIN, 'Administration EKEFLICKS'),
    ]

    audience = models.CharField(max_length=16, choices=AUDIENCE_CHOICES, db_index=True)
    category = models.CharField(max_length=48, db_index=True)
    question_fr = models.CharField(max_length=240)
    answer_fr = models.TextField()
    question_en = models.CharField(max_length=240, blank=True)
    answer_en = models.TextField(blank=True)
    sort_order = models.PositiveIntegerField(default=0)
    is_published = models.BooleanField(default=True, db_index=True)

    class Meta:
        db_table = 'frequently_asked_questions'
        ordering = ['audience', 'category', 'sort_order', 'id']
        indexes = [models.Index(fields=['audience', 'is_published', 'sort_order'], name='faq_aud_pub_sort_idx')]

    def __str__(self):
        return f'[{self.audience}] {self.question_fr}'
