from django.db import transaction

from apps.streaming.tasks import analyze_trailer
from core.models import (
    Content,
    Season,
    TrailerAnalysisReport,
)


_RESET_FIELDS = (
    "source_size_bytes",
    "container",
    "video_codec",
    "audio_codec",
    "width",
    "height",
    "frame_rate",
    "video_bitrate",
    "audio_bitrate",
    "duration_seconds",
    "audio_channels",
    "sample_rate",
    "technical_metadata",
    "flags",
    "error_message",
    "analyzed_at",
)


def _field_default(field_name):
    field = TrailerAnalysisReport._meta.get_field(
        field_name
    )
    return field.get_default()


def _reset_defaults(source_path):
    defaults = {
        "source_path": source_path,
        "status": TrailerAnalysisReport.STATUS_PENDING,
    }

    for field_name in _RESET_FIELDS:
        defaults[field_name] = _field_default(
            field_name
        )

    return defaults


def schedule_trailer_analysis(target):
    """
    Crée ou remet à zéro le rapport QC du trailer TEMP
    puis planifie l'analyse uniquement après commit DB.

    La cible doit être exactement un Content ou une Season.
    """

    source_path = str(
        target.trailer_temp_path or ""
    ).strip()

    if not source_path:
        return None

    defaults = _reset_defaults(
        source_path
    )

    with transaction.atomic():
        if isinstance(target, Content):
            report, _created = (
                TrailerAnalysisReport.objects
                .update_or_create(
                    content=target,
                    defaults={
                        **defaults,
                        "season": None,
                    },
                )
            )

        elif isinstance(target, Season):
            report, _created = (
                TrailerAnalysisReport.objects
                .update_or_create(
                    season=target,
                    defaults={
                        **defaults,
                        "content": None,
                    },
                )
            )

        else:
            raise TypeError(
                "La cible trailer doit être "
                "Content ou Season."
            )

        report_id = str(
            report.pk
        )

        transaction.on_commit(
            lambda report_id=report_id: (
                analyze_trailer.delay(
                    report_id
                )
            )
        )

    return report

def retry_trailer_analysis(target):
    """Relance l'analyse QC du trailer courant."""
    return schedule_trailer_analysis(target)

