from pathlib import Path

from django.conf import settings
from django.core.files import File
from django.core.files.storage import default_storage, storages
from django.utils import timezone


def object_id(value, fallback='system'):
    if value is None:
        return fallback
    if hasattr(value, 'pk') and value.pk:
        return str(value.pk)
    if hasattr(value, 'id') and value.id:
        return str(value.id)
    return str(value)


def dated_path(when=None):
    current = timezone.localtime(when or timezone.now())
    return current.strftime('%Y/%m/%d')


def safe_extension(filename, default):
    extension = Path(filename or '').suffix.lower()
    return extension or default


def media_cdn_url(path, prefix=''):
    cdn_base = (
        getattr(settings, 'MEDIA_CDN_BASE_URL', '')
        or getattr(settings, 'STREAMING_CDN_BASE_URL', '')
    ).rstrip('/')
    clean_path = str(path).lstrip('/')
    clean_prefix = str(prefix or '').strip('/')
    if cdn_base and clean_prefix:
        return f"{cdn_base}/{clean_prefix}/{clean_path}"
    if cdn_base:
        return f"{cdn_base}/{clean_path}"
    return ''


def save_internal_upload(uploaded_file, storage_path):
    try:
        if default_storage.exists(storage_path):
            default_storage.delete(storage_path)
    except Exception:
        pass
    return default_storage.save(storage_path, uploaded_file)


def copy_internal_to_final(internal_path, storage_alias, final_path, cdn_prefix=''):
    final_storage = storages[storage_alias]
    try:
        if final_storage.exists(final_path):
            final_storage.delete(final_path)
    except Exception:
        pass

    with default_storage.open(internal_path, 'rb') as source:
        saved_path = final_storage.save(final_path, File(source))

    cdn_url = media_cdn_url(saved_path, cdn_prefix)
    if cdn_url:
        return saved_path, cdn_url
    return saved_path, final_storage.url(saved_path)


def publish_uploaded_media(uploaded_file, internal_path, storage_alias, final_path, cdn_prefix=''):
    internal_saved_path = save_internal_upload(uploaded_file, internal_path)
    final_saved_path, public_url = copy_internal_to_final(
        internal_saved_path,
        storage_alias,
        final_path,
        cdn_prefix,
    )
    return {
        'temporary_path': internal_saved_path,
        'final_path': final_saved_path,
        'url': public_url,
    }
