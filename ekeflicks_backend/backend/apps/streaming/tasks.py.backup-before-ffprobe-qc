import subprocess
import tempfile
from pathlib import Path

from celery import shared_task
from django.conf import settings
from django.core.files import File
from django.core.files.storage import default_storage
from django.core.files.storage import storages
from django.utils import timezone

from apps.streaming.storage_paths import build_final_hls_path, build_processing_prefix
from core.models import VideoAsset, VideoRendition


DEFAULT_RENDITIONS = [
    {'quality': '360p', 'width': 640, 'height': 360, 'bandwidth': 800000},
    {'quality': '720p', 'width': 1280, 'height': 720, 'bandwidth': 2800000},
    {'quality': '1080p', 'width': 1920, 'height': 1080, 'bandwidth': 5000000},
]


def _final_video_storage():
    try:
        return storages['final_videos']
    except Exception:
        return storages['final_media']


def _storage_url(path, storage=None):
    cdn_base = getattr(settings, 'STREAMING_CDN_BASE_URL', '').rstrip('/')
    if cdn_base:
        return f"{cdn_base}/{path}"
    return (storage or _final_video_storage()).url(path)


def _source_input(asset, work_root):
    if asset.source_file_path:
        try:
            return default_storage.path(asset.source_file_path)
        except NotImplementedError:
            local_source = work_root / Path(asset.source_file_path).name
            with default_storage.open(asset.source_file_path, 'rb') as source_file:
                with local_source.open('wb') as destination:
                    for chunk in source_file.chunks():
                        destination.write(chunk)
            return str(local_source)
    return asset.source_file_url


def _processing_enabled():
    return getattr(settings, 'STREAMING_STORE_PROCESSING_ARTIFACTS', True)


def _delete_if_exists(storage, storage_path):
    try:
        if storage.exists(storage_path):
            storage.delete(storage_path)
    except Exception:
        pass


def _save_processing_file(storage_path, local_path):
    _delete_if_exists(default_storage, storage_path)
    with local_path.open('rb') as source:
        default_storage.save(storage_path, File(source))


def _store_processing_source(job_id, source_input):
    source_path = Path(source_input or '')
    if not source_path.exists():
        return

    extension = source_path.suffix or '.mp4'
    storage_path = f"{build_processing_prefix(job_id)}/source{extension}"
    _save_processing_file(storage_path, source_path)


def _store_processing_hls_tree(job_id, output_root):
    processing_prefix = f"{build_processing_prefix(job_id)}/hls"
    for file_path in output_root.rglob('*'):
        if not file_path.is_file():
            continue

        relative_path = file_path.relative_to(output_root).as_posix()
        _save_processing_file(f"{processing_prefix}/{relative_path}", file_path)


def _upload_hls_tree(asset, output_root):
    final_storage = _final_video_storage()
    uploaded_urls = {}

    for file_path in output_root.rglob('*'):
        if not file_path.is_file():
            continue

        relative_path = file_path.relative_to(output_root).as_posix()
        storage_path = build_final_hls_path(asset, relative_path)
        _delete_if_exists(final_storage, storage_path)

        with file_path.open('rb') as source:
            saved_path = final_storage.save(storage_path, File(source))
        uploaded_urls[relative_path] = _storage_url(saved_path, final_storage)

    return uploaded_urls


@shared_task(bind=True)
def transcode_video_asset_to_hls(self, asset_id):
    asset = VideoAsset.objects.select_related('content', 'episode__season').get(pk=asset_id)
    job_id = getattr(self.request, 'id', None) or str(asset.id)
    with tempfile.TemporaryDirectory(prefix=f"ekeflicks-hls-{asset.id}-") as tmp_dir:
        work_root = Path(tmp_dir)
        source_input = _source_input(asset, work_root)
        if not source_input:
            asset.status = 'failed'
            asset.save(update_fields=['status', 'updated_at'])
            raise ValueError('source_file_path or source_file_url is required to transcode a video asset')

        asset.status = 'processing'
        asset.save(update_fields=['status', 'updated_at'])

        if _processing_enabled():
            _store_processing_source(job_id, source_input)

        output_root = work_root / 'hls'
        output_root.mkdir(parents=True, exist_ok=True)

        segment_duration = str(getattr(settings, 'HLS_SEGMENT_DURATION_SECONDS', 6))
        master_lines = ['#EXTM3U', '#EXT-X-VERSION:3']
        rendition_payloads = []

        try:
            for index, rendition in enumerate(DEFAULT_RENDITIONS):
                rendition_dir = output_root / rendition['quality']
                rendition_dir.mkdir(parents=True, exist_ok=True)

                playlist_path = rendition_dir / 'index.m3u8'
                segment_pattern = rendition_dir / 'segment_%05d.ts'
                bitrate = str(rendition['bandwidth'])
                buffer_size = str(rendition['bandwidth'] * 2)

                command = [
                    'ffmpeg',
                    '-y',
                    '-i',
                    source_input,
                    '-vf',
                    f"scale=-2:{rendition['height']}",
                    '-c:v',
                    'h264',
                    '-profile:v',
                    'main',
                    '-preset',
                    'veryfast',
                    '-b:v',
                    bitrate,
                    '-maxrate',
                    bitrate,
                    '-bufsize',
                    buffer_size,
                    '-c:a',
                    'aac',
                    '-b:a',
                    '128k',
                    '-f',
                    'hls',
                    '-hls_time',
                    segment_duration,
                    '-hls_playlist_type',
                    'vod',
                    '-hls_segment_filename',
                    str(segment_pattern),
                    str(playlist_path),
                ]
                subprocess.run(command, check=True, capture_output=True, text=True)

                rendition_payloads.append((index, rendition))
                master_lines.extend([
                    f"#EXT-X-STREAM-INF:BANDWIDTH={rendition['bandwidth']},RESOLUTION={rendition['width']}x{rendition['height']}",
                    f"{rendition['quality']}/index.m3u8",
                ])

            master_path = output_root / 'master.m3u8'
            master_path.write_text('\n'.join(master_lines) + '\n', encoding='utf-8')

            if _processing_enabled():
                _store_processing_hls_tree(job_id, output_root)

            uploaded_urls = _upload_hls_tree(asset, output_root)

            for index, rendition in rendition_payloads:
                relative_playlist = f"{rendition['quality']}/index.m3u8"
                VideoRendition.objects.update_or_create(
                    asset=asset,
                    quality=rendition['quality'],
                    defaults={
                        'width': rendition['width'],
                        'height': rendition['height'],
                        'bandwidth': rendition['bandwidth'],
                        'codec': 'h264/aac',
                        'hls_playlist_url': uploaded_urls.get(relative_playlist, ''),
                        'display_order': index,
                    },
                )

            asset.hls_master_url = uploaded_urls.get('master.m3u8', '')
            asset.status = 'ready'
            asset.save(update_fields=['hls_master_url', 'status', 'updated_at'])
            return {'asset_id': str(asset.id), 'hls_master_url': asset.hls_master_url}
        except Exception:
            asset.status = 'failed'
            asset.save(update_fields=['status', 'updated_at'])
            raise
