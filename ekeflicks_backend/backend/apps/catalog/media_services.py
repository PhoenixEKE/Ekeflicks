from rest_framework import serializers

from apps.common.media_storage import (
    dated_path,
    object_id,
    publish_uploaded_media,
    safe_extension,
)


CONTENT_MEDIA_CONFIG = {
    'poster': {
        'field': 'poster_url',
        'storage_alias': 'final_posters',
        'cdn_prefix': 'posters',
        'default_extension': '.jpg',
        'allowed_extensions': {'.jpg', '.jpeg', '.png', '.webp'},
        'final_name': 'poster',
    },
    'backdrop': {
        'field': 'backdrop_url',
        'storage_alias': 'final_backdrops',
        'cdn_prefix': 'backdrops',
        'default_extension': '.jpg',
        'allowed_extensions': {'.jpg', '.jpeg', '.png', '.webp'},
        'final_name': 'backdrop',
    },
    'trailer': {
        'field': 'trailer_url',
        'storage_alias': 'final_trailers',
        'cdn_prefix': 'trailers',
        'default_extension': '.mp4',
        'allowed_extensions': {'.mp4', '.m4v', '.mov', '.webm'},
        'final_name': 'trailer',
    },
}


def publish_content_media(content, uploaded_file, media_type, uploader=None):
    config = CONTENT_MEDIA_CONFIG[media_type]
    extension = safe_extension(uploaded_file.name, config['default_extension'])
    if extension not in config['allowed_extensions']:
        raise serializers.ValidationError(
            {'file': f"Extension non autorisee pour {media_type}: {extension}"}
        )

    producer_id = object_id(uploader)
    internal_path = (
        f"uploads/producer_{producer_id}/{dated_path()}/"
        f"content_{content.id}/{media_type}_original{extension}"
    )
    final_path = f"{content.id}/{config['final_name']}{extension}"
    published = publish_uploaded_media(
        uploaded_file=uploaded_file,
        internal_path=internal_path,
        storage_alias=config['storage_alias'],
        final_path=final_path,
        cdn_prefix=config['cdn_prefix'],
    )

    setattr(content, config['field'], published['url'])
    content.save(update_fields=[config['field'], 'updated_at'])

    return {
        'content_id': str(content.id),
        'media_type': media_type,
        'field': config['field'],
        **published,
    }
