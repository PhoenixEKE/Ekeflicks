from django.db import models
from django.db.models import Q

from .base import TimeStampedModel


class TrailerAnalysisReport(TimeStampedModel):
    """
    Rapport de conformité technique d'une bande-annonce.

    Une instance cible exactement :
    - soit le trailer global d'un Content ;
    - soit le trailer d'une Season.

    Le modèle reste volontairement distinct de VideoAsset :
    les trailers suivent leur propre cycle TEMP/FINAL.
    """

    STATUS_PENDING = "pending"
    STATUS_ANALYZING = "analyzing"
    STATUS_PASSED = "passed"
    STATUS_REVIEW_REQUIRED = "review_required"
    STATUS_FAILED = "failed"

    STATUS_CHOICES = [
        (STATUS_PENDING, "Pending"),
        (STATUS_ANALYZING, "Analyzing"),
        (STATUS_PASSED, "Passed"),
        (
            STATUS_REVIEW_REQUIRED,
            "Review required",
        ),
        (STATUS_FAILED, "Failed"),
    ]

    content = models.OneToOneField(
        "core.Content",
        on_delete=models.CASCADE,
        related_name="trailer_analysis_report",
        null=True,
        blank=True,
    )

    season = models.OneToOneField(
        "core.Season",
        on_delete=models.CASCADE,
        related_name="trailer_analysis_report",
        null=True,
        blank=True,
    )

    status = models.CharField(
        max_length=30,
        choices=STATUS_CHOICES,
        default=STATUS_PENDING,
        db_index=True,
    )

    # Snapshot exact du fichier ayant produit ce rapport.
    # Il permettra de rejeter un résultat Celery obsolète
    # si le producteur remplace le trailer entre-temps.
    source_path = models.CharField(
        max_length=1000,
        blank=True,
    )

    source_size_bytes = models.BigIntegerField(
        default=0,
    )

    container = models.CharField(
        max_length=50,
        blank=True,
    )

    video_codec = models.CharField(
        max_length=50,
        blank=True,
    )

    audio_codec = models.CharField(
        max_length=50,
        blank=True,
    )

    width = models.PositiveIntegerField(
        default=0,
    )

    height = models.PositiveIntegerField(
        default=0,
    )

    frame_rate = models.DecimalField(
        max_digits=8,
        decimal_places=3,
        null=True,
        blank=True,
    )

    video_bitrate = models.BigIntegerField(
        default=0,
    )

    audio_bitrate = models.BigIntegerField(
        default=0,
    )

    duration_seconds = models.DecimalField(
        max_digits=12,
        decimal_places=3,
        null=True,
        blank=True,
    )

    audio_channels = models.PositiveSmallIntegerField(
        default=0,
    )

    sample_rate = models.PositiveIntegerField(
        default=0,
    )

    technical_metadata = models.JSONField(
        default=dict,
        blank=True,
    )

    flags = models.JSONField(
        default=list,
        blank=True,
    )

    analysis_version = models.CharField(
        max_length=50,
        default="eke-trailer-qc-v1",
    )

    error_message = models.TextField(
        blank=True,
    )

    analyzed_at = models.DateTimeField(
        null=True,
        blank=True,
    )

    class Meta:
        db_table = "trailer_analysis_reports"

        indexes = [
            models.Index(
                fields=[
                    "status",
                    "created_at",
                ],
            ),
        ]

        constraints = [
            models.CheckConstraint(
                check=(
                    Q(
                        content__isnull=False,
                        season__isnull=True,
                    )
                    | Q(
                        content__isnull=True,
                        season__isnull=False,
                    )
                ),
                name=(
                    "trailer_analysis_"
                    "exactly_one_target"
                ),
            ),
        ]

    def __str__(self):
        if self.content_id:
            target = (
                f"content:{self.content_id}"
            )
        else:
            target = (
                f"season:{self.season_id}"
            )

        return (
            f"Trailer QC {target} "
            f"- {self.status}"
        )
