from pathlib import Path

from django.utils import timezone


def _object_id(value, fallback='system'):
    if value is None:
        return fallback
    if hasattr(value, 'pk') and value.pk:
        return str(value.pk)
    if hasattr(value, 'id') and value.id:
        return str(value.id)
    return str(value)


def _dated_path(when=None):
    current = timezone.localtime(when or timezone.now())
    return current.strftime('%Y/%m/%d')


def _safe_extension(filename, default='.mp4'):
    extension = Path(filename or '').suffix.lower()
    return extension or default


def build_source_upload_path(asset, uploaded_file, producer=None, when=None):
    producer_id = _object_id(producer)
    extension = _safe_extension(getattr(uploaded_file, 'name', ''))
    return (
        f"uploads/producer_{producer_id}/{_dated_path(when)}/"
        f"asset_{asset.id}/video_original{extension}"
    )


def build_processing_prefix(job_id):
    return f"processing/{job_id}"


def build_video_output_prefix(asset):
    if asset.episode_id:
        episode = asset.episode
        season = episode.season
        return (
            f"series/{asset.content_id}/"
            f"season_{season.season_number:02d}/"
            f"episode_{episode.episode_number:02d}"
        )

    if asset.content.type == 'series':
        return f"series/{asset.content_id}/asset_{asset.id}"

    return f"movies/{asset.content_id}"


def build_final_hls_path(asset, relative_path):
    filename = 'manifest.m3u8' if relative_path == 'master.m3u8' else relative_path
    return f"{build_video_output_prefix(asset)}/{filename}"


def build_final_dash_path(asset, relative_path):
    return f"{build_video_output_prefix(asset)}/dash/{relative_path}"
