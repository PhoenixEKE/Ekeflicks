from django.core.exceptions import ValidationError
from django.db import models

from .base import TimeStampedModel


class TechnicalSpecification(TimeStampedModel):
    """
    Version administrable du cahier des charges technique producteur.

    Une seule version doit normalement être publiée à la fois.
    Le contenu structuré est utilisé à la fois par l'API et le PDF.
    """

    title = models.CharField(
        max_length=255,
        default="Cahier des charges technique EKEFLICKS",
    )
    version = models.CharField(
        max_length=50,
        unique=True,
    )
    introduction = models.TextField(blank=True)
    sections = models.JSONField(default=list, blank=True)
    is_published = models.BooleanField(default=False, db_index=True)
    published_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = "technical_specifications"
        ordering = ["-published_at", "-created_at"]

    IMMUTABLE_WHEN_PINNED_FIELDS = (
        "title",
        "version",
        "introduction",
        "sections",
    )

    def _validate_pinned_immutability(self):
        if not self.pk:
            return

        if not self.submitted_contents.exists():
            return

        previous = (
            type(self).objects
            .filter(pk=self.pk)
            .values(
                *self.IMMUTABLE_WHEN_PINNED_FIELDS
            )
            .first()
        )

        if previous is None:
            return

        changed_fields = [
            field_name
            for field_name in self.IMMUTABLE_WHEN_PINNED_FIELDS
            if getattr(self, field_name) != previous[field_name]
        ]

        if changed_fields:
            raise ValidationError({
                field_name: (
                    "Cette spécification technique est déjà "
                    "pinnée par au moins un contenu soumis et "
                    "ne peut plus être modifiée."
                )
                for field_name in changed_fields
            })

    def save(self, *args, **kwargs):
        self._validate_pinned_immutability()
        return super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.title} — {self.version}"
