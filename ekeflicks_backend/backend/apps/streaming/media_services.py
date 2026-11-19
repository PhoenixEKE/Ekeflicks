from rest_framework import serializers

from apps.common.media_storage import (
    dated_path,
    object_id,
    publish_uploaded_media,
    safe_extension,
)
from core.models import SubtitleTrack


ALLOWED_SUBTITLE_EXTENSIONS = {'.vtt', '.srt'}


def build_subtitle_final_path(asset, language, extension):
    if asset.episode_id:
        episode = asset.episode
        season = episode.season
        return (
            f"{asset.content_id}/season_{season.season_number:02d}/"
            f"episode_{episode.episode_number:02d}/{language}{extension}"
        )
    return f"{asset.content_id}/{language}{extension}"


def publish_subtitle_track(
    asset,
    uploaded_file,
    language,
    label='',
    kind='subtitle',
    is_default=False,
    uploader=None,
):
    extension = safe_extension(uploaded_file.name, '.vtt')
    if extension not in ALLOWED_SUBTITLE_EXTENSIONS:
        raise serializers.ValidationError(
            {'file': f"Extension non autorisee pour un sous-titre: {extension}"}
        )

    producer_id = object_id(uploader)
    internal_path = (
        f"uploads/producer_{producer_id}/{dated_path()}/"
        f"content_{asset.content_id}/asset_{asset.id}/subtitles/"
        f"{language}_original{extension}"
    )
    final_path = build_subtitle_final_path(asset, language, extension)
    published = publish_uploaded_media(
        uploaded_file=uploaded_file,
        internal_path=internal_path,
        storage_alias='final_subtitles',
        final_path=final_path,
        cdn_prefix='subtitles',
    )

    if is_default:
        SubtitleTrack.objects.filter(asset=asset, kind=kind).update(is_default=False)

    track, _created = SubtitleTrack.objects.update_or_create(
        asset=asset,
        language=language,
        kind=kind,
        defaults={
            'label': label or language.upper(),
            'url': published['url'],
            'is_default': is_default,
        },
    )

    return track, {
        'asset_id': str(asset.id),
        'content_id': str(asset.content_id),
        'language': language,
        'kind': kind,
        **published,
    }
