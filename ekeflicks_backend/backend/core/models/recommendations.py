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



# ==========================================================
# G5-1D7 — PRODUCT TOP 10 + IMMUTABLE HISTORY
# ==========================================================

class Top10Snapshot(models.Model):
    """
    Immutable publication of the product Top 10.

    PostgreSQL is the source of truth for the published
    product ranking. ClickHouse remains the analytics source
    used to calculate the ranking.

    A snapshot represents one complete publication window.
    """

    SCOPE_GLOBAL = 'global'

    SCOPE_CHOICES = [
        (SCOPE_GLOBAL, 'Global'),
    ]

    ALGORITHM_V1 = 'd4_7d_v1'

    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False,
    )

    generated_at = models.DateTimeField(
        auto_now_add=True,
        db_index=True,
    )

    window_start = models.DateTimeField(
        db_index=True,
    )

    window_end = models.DateTimeField(
        db_index=True,
    )

    scope = models.CharField(
        max_length=32,
        choices=SCOPE_CHOICES,
        default=SCOPE_GLOBAL,
        db_index=True,
    )

    algorithm_version = models.CharField(
        max_length=64,
        default=ALGORITHM_V1,
    )

    is_published = models.BooleanField(
        default=False,
        db_index=True,
    )

    class Meta:
        db_table = 'top10_snapshots'
        ordering = [
            '-generated_at',
            '-id',
        ]
        indexes = [
            models.Index(
                fields=[
                    'scope',
                    'is_published',
                    '-generated_at',
                ],
                name='top10_snap_scope_pub_idx',
            ),
        ]

    def __str__(self):
        return (
            f'Top10 {self.scope} '
            f'{self.generated_at.isoformat()}'
        )


class Top10Entry(models.Model):
    """
    One ranked content row belonging to an immutable
    Top10Snapshot.

    The analytics values are frozen at publication time so
    historical rankings remain reproducible even when the
    underlying ClickHouse window changes later.
    """

    MOVEMENT_NEW = 'new'
    MOVEMENT_UP = 'up'
    MOVEMENT_DOWN = 'down'
    MOVEMENT_UNCHANGED = 'unchanged'

    MOVEMENT_CHOICES = [
        (MOVEMENT_NEW, 'New'),
        (MOVEMENT_UP, 'Up'),
        (MOVEMENT_DOWN, 'Down'),
        (MOVEMENT_UNCHANGED, 'Unchanged'),
    ]

    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False,
    )

    snapshot = models.ForeignKey(
        Top10Snapshot,
        on_delete=models.CASCADE,
        related_name='entries',
    )

    content = models.ForeignKey(
        'Content',
        on_delete=models.PROTECT,
        related_name='top10_entries',
    )

    position = models.PositiveSmallIntegerField()

    qualified_views = models.PositiveBigIntegerField(
        default=0,
    )

    watch_seconds = models.PositiveBigIntegerField(
        default=0,
    )

    unique_viewers = models.PositiveBigIntegerField(
        default=0,
    )

    completed_views = models.PositiveBigIntegerField(
        default=0,
    )

    qualification_rate_percent = models.DecimalField(
        max_digits=6,
        decimal_places=2,
        default=0,
    )

    previous_position = models.PositiveSmallIntegerField(
        null=True,
        blank=True,
    )

    position_change = models.SmallIntegerField(
        null=True,
        blank=True,
    )

    movement = models.CharField(
        max_length=16,
        choices=MOVEMENT_CHOICES,
        default=MOVEMENT_NEW,
    )

    class Meta:
        db_table = 'top10_entries'
        ordering = [
            'position',
            'id',
        ]
        constraints = [
            models.UniqueConstraint(
                fields=[
                    'snapshot',
                    'position',
                ],
                name='uniq_top10_snapshot_position',
            ),
            models.UniqueConstraint(
                fields=[
                    'snapshot',
                    'content',
                ],
                name='uniq_top10_snapshot_content',
            ),
            models.CheckConstraint(
                check=models.Q(
                    position__gte=1,
                    position__lte=10,
                ),
                name='top10_position_1_10',
            ),
        ]
        indexes = [
            models.Index(
                fields=[
                    'snapshot',
                    'position',
                ],
                name='top10_entry_snap_pos_idx',
            ),
            models.Index(
                fields=[
                    'content',
                    '-snapshot',
                ],
                name='top10_entry_content_idx',
            ),
        ]

    def __str__(self):
        return (
            f'#{self.position} '
            f'{self.content_id}'
        )
