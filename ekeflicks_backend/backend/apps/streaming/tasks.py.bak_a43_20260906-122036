import json
import re
import subprocess
import tempfile
from pathlib import Path

from celery import shared_task
from django.conf import settings

from django.core.files import File
from django.core.files.storage import default_storage
from django.core.files.storage import storages
from django.utils import timezone

from apps.streaming.storage_paths import (
    build_final_dash_path,
    build_final_hls_path,
    build_processing_prefix,
)
from apps.streaming.ai_moderation import (
    analyze_moderation_frames,
    extract_moderation_frames,
    load_moderation_session,
)
from apps.streaming.per_title import analyze_per_title_source_v2
from core.models import MediaAnalysisReport, VideoAsset, VideoRendition
from huggingface_hub import hf_hub_download


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


def _store_processing_dash_tree(job_id, output_root):
    processing_prefix = f"{build_processing_prefix(job_id)}/dash"

    for file_path in output_root.rglob('*'):
        if not file_path.is_file():
            continue

        relative_path = file_path.relative_to(output_root).as_posix()
        _save_processing_file(
            f"{processing_prefix}/{relative_path}",
            file_path,
        )


def _upload_dash_tree(asset, output_root):
    final_storage = _final_video_storage()
    uploaded_urls = {}

    for file_path in output_root.rglob('*'):
        if not file_path.is_file():
            continue

        relative_path = file_path.relative_to(output_root).as_posix()
        storage_path = build_final_dash_path(
            asset,
            relative_path,
        )

        _delete_if_exists(final_storage, storage_path)

        with file_path.open('rb') as source:
            saved_path = final_storage.save(
                storage_path,
                File(source),
            )

        uploaded_urls[relative_path] = _storage_url(
            saved_path,
            final_storage,
        )

    return uploaded_urls


def _safe_int(value, default=0):
    try:
        if value in (None, '', 'N/A'):
            return default
        return int(float(value))
    except (TypeError, ValueError):
        return default


def _frame_rate(value):
    if not value or value in {'0/0', 'N/A'}:
        return None

    try:
        numerator, denominator = value.split('/', 1)
        denominator = float(denominator)
        if denominator == 0:
            return None
        return round(float(numerator) / denominator, 3)
    except (TypeError, ValueError, ZeroDivisionError):
        try:
            return round(float(value), 3)
        except (TypeError, ValueError):
            return None



def _probe_output_media(source_input):
    command = [
        'ffprobe',
        '-v', 'error',
        '-show_streams',
        '-show_format',
        '-of', 'json',
        str(source_input),
    ]

    result = subprocess.run(
        command,
        check=True,
        capture_output=True,
        text=True,
        timeout=300,
    )

    return json.loads(result.stdout or '{}')


def _decode_output_media(source_input):
    """
    Decode the complete output to catch corrupt or unreadable segments.
    """
    command = [
        'ffmpeg',
        '-hide_banner',
        '-nostats',
        '-v', 'error',
        '-i', str(source_input),
        '-map', '0:v:0',
        '-map', '0:a:0?',
        '-f', 'null',
        '-',
    ]

    result = subprocess.run(
        command,
        capture_output=True,
        text=True,
        timeout=900,
    )

    if result.returncode != 0:
        raise RuntimeError(
            'Output decode QC failed: '
            + (result.stderr or '')[-1500:]
        )


def _output_duration(probe):
    format_data = probe.get('format') or {}

    try:
        return round(float(format_data.get('duration') or 0), 3)
    except (TypeError, ValueError):
        return 0.0


def _run_output_qc(
    output_root,
    dash_manifest_path,
    selected_renditions,
    expected_duration=0,
):
    """
    Validate locally generated HLS renditions and DASH manifest
    before publishing them to final storage.
    """

    results = {
        'version': 'eke-output-qc-v1',
        'status': 'passed',
        'renditions': [],
        'dash': {},
        'flags': [],
    }

    durations = []

    for rendition in selected_renditions:
        playlist_path = (
            output_root
            / rendition['quality']
            / 'index.m3u8'
        )

        if not playlist_path.exists():
            raise RuntimeError(
                f"Missing HLS playlist: {rendition['quality']}"
            )

        _decode_output_media(playlist_path)
        probe = _probe_output_media(playlist_path)

        streams = probe.get('streams') or []

        video_stream = next(
            (
                stream
                for stream in streams
                if stream.get('codec_type') == 'video'
            ),
            None,
        )

        audio_stream = next(
            (
                stream
                for stream in streams
                if stream.get('codec_type') == 'audio'
            ),
            None,
        )

        if not video_stream:
            raise RuntimeError(
                f"Missing video stream: {rendition['quality']}"
            )

        actual_width = _safe_int(
            video_stream.get('width')
        )
        actual_height = _safe_int(
            video_stream.get('height')
        )

        expected_width = int(rendition['width'])
        expected_height = int(rendition['height'])

        if (
            actual_width != expected_width
            or actual_height != expected_height
        ):
            raise RuntimeError(
                f"Resolution mismatch for {rendition['quality']}: "
                f"{actual_width}x{actual_height} != "
                f"{expected_width}x{expected_height}"
            )

        duration = _output_duration(probe)

        if duration > 0:
            durations.append(duration)

        results['renditions'].append({
            'quality': rendition['quality'],
            'width': actual_width,
            'height': actual_height,
            'video_codec': (
                video_stream.get('codec_name') or ''
            ),
            'audio_codec': (
                audio_stream.get('codec_name')
                if audio_stream
                else ''
            ),
            'duration_seconds': duration,
            'decode_ok': True,
        })

    #
    # Duration coherence between renditions.
    #
    if durations:
        duration_spread = max(durations) - min(durations)

        results['duration_spread_seconds'] = round(
            duration_spread,
            3,
        )

        if duration_spread > 0.5:
            raise RuntimeError(
                'Output rendition duration mismatch: '
                f'{duration_spread:.3f}s'
            )

    #
    # Compare against source duration with a small tolerance.
    #
    try:
        expected_duration = float(expected_duration or 0)
    except (TypeError, ValueError):
        expected_duration = 0

    if expected_duration > 0 and durations:
        delta = abs(
            max(durations) - expected_duration
        )

        results['source_duration_delta_seconds'] = round(
            delta,
            3,
        )

        if delta > 1.0:
            raise RuntimeError(
                'Encoded duration differs from source by '
                f'{delta:.3f}s'
            )

    #
    # DASH validation.
    #
    if not dash_manifest_path.exists():
        raise RuntimeError('Missing DASH manifest')

    _decode_output_media(dash_manifest_path)
    dash_probe = _probe_output_media(
        dash_manifest_path
    )

    dash_streams = dash_probe.get('streams') or []

    dash_video_streams = [
        stream
        for stream in dash_streams
        if stream.get('codec_type') == 'video'
    ]

    dash_audio_streams = [
        stream
        for stream in dash_streams
        if stream.get('codec_type') == 'audio'
    ]

    if len(dash_video_streams) != len(selected_renditions):
        raise RuntimeError(
            'DASH video representation count mismatch: '
            f'{len(dash_video_streams)} != '
            f'{len(selected_renditions)}'
        )

    results['dash'] = {
        'manifest_ok': True,
        'decode_ok': True,
        'video_representations': len(
            dash_video_streams
        ),
        'audio_representations': len(
            dash_audio_streams
        ),
    }

    return results

def _parse_ffmpeg_events(stderr):
    events = []

    black_pattern = re.compile(
        r'black_start:(?P<start>[\d.]+)\s+'
        r'black_end:(?P<end>[\d.]+)\s+'
        r'black_duration:(?P<duration>[\d.]+)'
    )

    for match in black_pattern.finditer(stderr):
        events.append({
            'type': 'black',
            'start': round(float(match.group('start')), 3),
            'end': round(float(match.group('end')), 3),
            'duration': round(float(match.group('duration')), 3),
        })

    freeze_starts = [
        float(value)
        for value in re.findall(r'freeze_start:\s*([\d.]+)', stderr)
    ]
    freeze_ends = [
        float(value)
        for value in re.findall(r'freeze_end:\s*([\d.]+)', stderr)
    ]

    for index, start in enumerate(freeze_starts):
        end = freeze_ends[index] if index < len(freeze_ends) else None
        event = {
            'type': 'freeze',
            'start': round(start, 3),
        }

        if end is not None:
            event['end'] = round(end, 3)
            event['duration'] = round(max(0, end - start), 3)

        events.append(event)

    silence_starts = [
        float(value)
        for value in re.findall(r'silence_start:\s*([\d.]+)', stderr)
    ]

    silence_ends = re.findall(
        r'silence_end:\s*([\d.]+)\s*\|\s*silence_duration:\s*([\d.]+)',
        stderr,
    )

    for index, start in enumerate(silence_starts):
        event = {
            'type': 'silence',
            'start': round(start, 3),
        }

        if index < len(silence_ends):
            end, duration = silence_ends[index]
            event['end'] = round(float(end), 3)
            event['duration'] = round(float(duration), 3)

        events.append(event)

    return events


def _extract_loudnorm_metrics(stderr):
    decoder = json.JSONDecoder()

    candidates = [
        match.start()
        for match in re.finditer(r'\{', stderr)
    ]

    for start in reversed(candidates):
        try:
            data, _ = decoder.raw_decode(stderr[start:])
        except (json.JSONDecodeError, TypeError):
            continue

        if isinstance(data, dict) and 'input_i' in data:
            def number(name):
                try:
                    value = data.get(name)
                    if value in (None, '', '-inf', 'inf'):
                        return None
                    return round(float(value), 3)
                except (TypeError, ValueError):
                    return None

            return {
                'integrated_lufs': number('input_i'),
                'true_peak_dbtp': number('input_tp'),
                'lra': number('input_lra'),
                'threshold': number('input_thresh'),
            }

    return {
        'integrated_lufs': None,
        'true_peak_dbtp': None,
        'lra': None,
        'threshold': None,
    }


def _run_advanced_qc(source_input, has_video=True, has_audio=True):
    events = []
    qc = {
        'black_events': 0,
        'freeze_events': 0,
        'silence_events': 0,
        'integrated_lufs': None,
        'true_peak_dbtp': None,
        'lra': None,
        'threshold': None,
    }

    if has_video:
        video_command = [
            'ffmpeg',
            '-hide_banner',
            '-nostats',
            '-i', str(source_input),
            '-map', '0:v:0',
            '-vf',
            (
                'blackdetect=d=2.0:pix_th=0.10,'
                'freezedetect=n=-50dB:d=3.0'
            ),
            '-an',
            '-f', 'null',
            '-',
        ]

        video_result = subprocess.run(
            video_command,
            capture_output=True,
            text=True,
            timeout=900,
        )

        if video_result.returncode != 0:
            raise RuntimeError(
                'FFmpeg video QC failed: '
                + (video_result.stderr or '')[-1500:]
            )

        video_events = _parse_ffmpeg_events(video_result.stderr or '')
        events.extend(
            event
            for event in video_events
            if event.get('type') in {'black', 'freeze'}
        )

    if has_audio:
        audio_command = [
            'ffmpeg',
            '-hide_banner',
            '-nostats',
            '-i', str(source_input),
            '-map', '0:a:0',
            '-af',
            (
                'silencedetect=noise=-50dB:d=5.0,'
                'loudnorm=I=-16:TP=-1.5:LRA=11:print_format=json'
            ),
            '-vn',
            '-f', 'null',
            '-',
        ]

        audio_result = subprocess.run(
            audio_command,
            capture_output=True,
            text=True,
            timeout=900,
        )

        if audio_result.returncode != 0:
            raise RuntimeError(
                'FFmpeg audio QC failed: '
                + (audio_result.stderr or '')[-1500:]
            )

        audio_stderr = audio_result.stderr or ''

        events.extend(
            event
            for event in _parse_ffmpeg_events(audio_stderr)
            if event.get('type') == 'silence'
        )

        qc.update(_extract_loudnorm_metrics(audio_stderr))

    qc['black_events'] = sum(
        1 for event in events if event.get('type') == 'black'
    )
    qc['freeze_events'] = sum(
        1 for event in events if event.get('type') == 'freeze'
    )
    qc['silence_events'] = sum(
        1 for event in events if event.get('type') == 'silence'
    )

    return qc, events


@shared_task(bind=True)
def analyze_video_asset(self, asset_id):
    asset = VideoAsset.objects.get(pk=asset_id)

    report, _ = MediaAnalysisReport.objects.get_or_create(asset=asset)

    report.status = 'analyzing'
    report.error_message = ''
    report.flags = []
    report.save(update_fields=[
        'status',
        'error_message',
        'flags',
        'updated_at',
    ])

    try:
        with tempfile.TemporaryDirectory(
            prefix=f"ekeflicks-qc-{asset.id}-"
        ) as tmp_dir:
            work_root = Path(tmp_dir)
            source_input = _source_input(asset, work_root)

            if not source_input:
                raise ValueError(
                    'source_file_path or source_file_url is required'
                )

            command = [
                'ffprobe',
                '-v', 'error',
                '-show_format',
                '-show_streams',
                '-of', 'json',
                str(source_input),
            ]

            result = subprocess.run(
                command,
                capture_output=True,
                text=True,
                check=True,
                timeout=300,
            )

            metadata = json.loads(result.stdout or '{}')
            streams = metadata.get('streams') or []
            format_data = metadata.get('format') or {}

            video_stream = next(
                (
                    stream
                    for stream in streams
                    if stream.get('codec_type') == 'video'
                ),
                None,
            )

            audio_stream = next(
                (
                    stream
                    for stream in streams
                    if stream.get('codec_type') == 'audio'
                ),
                None,
            )

            flags = []

            if not video_stream:
                flags.append('video_stream_missing')

            if not audio_stream:
                flags.append('audio_stream_missing')

            width = _safe_int(
                (video_stream or {}).get('width')
            )

            height = _safe_int(
                (video_stream or {}).get('height')
            )

            if video_stream and (width < 1280 or height < 720):
                flags.append('resolution_below_720p')

            duration = (
                format_data.get('duration')
                or (video_stream or {}).get('duration')
                or 0
            )

            try:
                duration_value = round(float(duration), 3)
            except (TypeError, ValueError):
                duration_value = 0

            if duration_value <= 0:
                flags.append('invalid_duration')

            video_bitrate = _safe_int(
                (video_stream or {}).get('bit_rate')
                or format_data.get('bit_rate')
            )

            audio_bitrate = _safe_int(
                (audio_stream or {}).get('bit_rate')
            )

            qc_v2, detected_events = _run_advanced_qc(
                source_input,
                has_video=video_stream is not None,
                has_audio=audio_stream is not None,
            )

            # ---------------------------------------------------------
            # AI MODERATION V1
            # ---------------------------------------------------------
            moderation_scores = {}

            if video_stream is not None:
                model_path = hf_hub_download(
                    repo_id='OwenElliott/image-safety-classifier-xs',
                    filename='onnx/image-safety-classifier-xs.onnx',
                )

                moderation_session = load_moderation_session(model_path)

                moderation_frames = extract_moderation_frames(
                    source_input,
                    work_root / 'moderation_frames',
                )

                ai_result = analyze_moderation_frames(
                    moderation_session,
                    moderation_frames,
                )

                moderation_scores = ai_result['scores']

                moderation_scores['model'] = {
                    'provider': 'onnxruntime',
                    'repository': 'OwenElliott/image-safety-classifier-xs',
                    'file': 'onnx/image-safety-classifier-xs.onnx',
                    'pipeline_version': 'eke-ai-moderation-v1',
                }

                detected_events.extend(ai_result['events'])

                for ai_flag in ai_result['flags']:
                    if ai_flag not in flags:
                        flags.append(ai_flag)

            black_count = qc_v2.get('black_events', 0)
            freeze_count = qc_v2.get('freeze_events', 0)
            silence_count = qc_v2.get('silence_events', 0)

            loudness_lufs = qc_v2.get('integrated_lufs')
            true_peak_dbtp = qc_v2.get('true_peak_dbtp')

            if black_count:
                flags.append('long_black_frames_detected')

            if freeze_count:
                flags.append('freeze_frames_detected')

            if silence_count:
                flags.append('long_audio_silence_detected')

            if (
                loudness_lufs is not None
                and (
                    loudness_lufs < -30.0
                    or loudness_lufs > -10.0
                )
            ):
                flags.append('audio_loudness_out_of_range')

            if (
                true_peak_dbtp is not None
                and true_peak_dbtp > -0.1
            ):
                flags.append('audio_clipping_risk')

            technical_score = 100

            penalties = {
                'video_stream_missing': 60,
                'audio_stream_missing': 20,
                'resolution_below_720p': 15,
                'invalid_duration': 20,
                'long_black_frames_detected': 10,
                'freeze_frames_detected': 10,
                'long_audio_silence_detected': 5,
                'audio_loudness_out_of_range': 10,
                'audio_clipping_risk': 15,
            }

            for flag in set(flags):
                technical_score -= penalties.get(flag, 0)

            technical_score = max(0, technical_score)

            if flags:
                report_status = 'review_required'
            else:
                report_status = 'passed'

            report.status = report_status

            report.container = (
                format_data.get('format_name', '')[:50]
            )

            report.video_codec = (
                (video_stream or {}).get('codec_name', '')[:50]
            )

            report.audio_codec = (
                (audio_stream or {}).get('codec_name', '')[:50]
            )

            report.width = width
            report.height = height

            report.frame_rate = _frame_rate(
                (video_stream or {}).get('avg_frame_rate')
                or (video_stream or {}).get('r_frame_rate')
            )

            report.video_bitrate = video_bitrate
            report.audio_bitrate = audio_bitrate
            report.duration_seconds = duration_value

            report.audio_channels = _safe_int(
                (audio_stream or {}).get('channels')
            )

            report.sample_rate = _safe_int(
                (audio_stream or {}).get('sample_rate')
            )

            report.black_frame_count = black_count
            report.freeze_frame_count = freeze_count
            report.loudness_lufs = loudness_lufs

            report.technical_score = technical_score

            metadata['qc_v2'] = qc_v2
            report.technical_metadata = metadata

            report.moderation_scores = moderation_scores
            report.detected_events = detected_events
            report.flags = flags
            report.analysis_version = 'eke-qc-v2-ai-v1'
            report.analyzed_at = timezone.now()
            report.error_message = ''

            report.save()

            if duration_value > 0:
                asset.duration_seconds = int(round(duration_value))
                asset.save(update_fields=[
                    'duration_seconds',
                    'updated_at',
                ])

            return {
                'asset_id': str(asset.id),
                'status': report.status,
                'technical_score': technical_score,
                'flags': flags,
                'qc_v2': qc_v2,
                'moderation_scores': moderation_scores,
            }

    except Exception as exc:
        report.status = 'failed'
        report.error_message = str(exc)[:2000]
        report.analyzed_at = timezone.now()

        report.save(update_fields=[
            'status',
            'error_message',
            'analyzed_at',
            'updated_at',
        ])

        raise


@shared_task(bind=True)
def transcode_video_asset_to_hls(self, asset_id):
    asset = VideoAsset.objects.select_related(
        'content',
        'episode__season',
        'analysis_report',
    ).get(pk=asset_id)

    try:
        analysis_report = asset.analysis_report
    except MediaAnalysisReport.DoesNotExist:
        raise ValueError(
            'QC/AI analysis report is required before transcoding'
        )

    if analysis_report.status not in {'passed', 'review_required'}:
        raise ValueError(
            f'QC/AI analysis is not ready: {analysis_report.status}'
        )

    if asset.moderation_status != 'approved':
        raise ValueError(
            'Administrator approval is required before transcoding'
        )

    job_id = getattr(self.request, 'id', None) or str(asset.id)
    with tempfile.TemporaryDirectory(prefix=f"ekeflicks-hls-{asset.id}-") as tmp_dir:
        work_root = Path(tmp_dir)
        source_input = _source_input(asset, work_root)
        if not source_input:
            asset.status = 'failed'
            asset.save(update_fields=['status', 'updated_at'])
            raise ValueError('source_file_path or source_file_url is required to transcode a video asset')

        duration_for_per_title = (
            asset.duration_seconds
            or analysis_report.duration_seconds
            or 0
        )

        per_title = analyze_per_title_source_v2(
            source_input,
            duration_for_per_title,
        )

        selected_renditions = per_title['ladder']

        if not selected_renditions:
            raise ValueError(
                'Per-title analysis produced no rendition'
            )

        metadata = dict(
            analysis_report.technical_metadata or {}
        )

        metadata['per_title_v2'] = {
            'version': per_title['version'],
            'source': per_title['source'],
            'shot_count': per_title['shot_count'],
            'visual_complexity': per_title['visual_complexity'],
            'complexity_score': per_title['complexity_score'],
            'ladder': per_title['ladder'],
        }

        analysis_report.technical_metadata = metadata
        analysis_report.save(
            update_fields=[
                'technical_metadata',
                'updated_at',
            ]
        )

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
            for index, rendition in enumerate(selected_renditions):
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
                    '-force_key_frames',
                    f'expr:gte(t,n_forced*{segment_duration})',
                    '-sc_threshold',
                    '0',
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
            master_path.write_text('\\n'.join(master_lines) + '\\n', encoding='utf-8')

            # DASH / fragmented MP4
            dash_root = work_root / 'dash'
            dash_root.mkdir(parents=True, exist_ok=True)
            dash_manifest_path = dash_root / 'manifest.mpd'

            dash_command = [
                'ffmpeg',
                '-y',
                '-i',
                source_input,
            ]

            for rendition_index, rendition in enumerate(selected_renditions):
                bitrate = str(rendition['bandwidth'])
                buffer_size = str(rendition['bandwidth'] * 2)

                dash_command.extend([
                    '-map',
                    '0:v:0',
                    f'-filter:v:{rendition_index}',
                    f"scale=-2:{rendition['height']}",
                    f'-c:v:{rendition_index}',
                    'h264',
                    f'-profile:v:{rendition_index}',
                    'main',
                    f'-preset:v:{rendition_index}',
                    'veryfast',
                    f'-b:v:{rendition_index}',
                    bitrate,
                    f'-maxrate:v:{rendition_index}',
                    bitrate,
                    f'-bufsize:v:{rendition_index}',
                    buffer_size,
                    f'-force_key_frames:v:{rendition_index}',
                    f'expr:gte(t,n_forced*{segment_duration})',
                    f'-sc_threshold:v:{rendition_index}',
                    '0',
                ])

            has_audio = bool(analysis_report.audio_codec)

            if has_audio:
                dash_command.extend([
                    '-map',
                    '0:a:0?',
                    '-c:a',
                    'aac',
                    '-b:a',
                    '128k',
                ])

            adaptation_sets = (
                'id=0,streams=v id=1,streams=a'
                if has_audio
                else 'id=0,streams=v'
            )

            dash_command.extend([
                '-f',
                'dash',
                '-seg_duration',
                segment_duration,
                '-use_template',
                '1',
                '-use_timeline',
                '1',
                '-init_seg_name',
                'init_$RepresentationID$.m4s',
                '-media_seg_name',
                'chunk_$RepresentationID$_$Number%05d$.m4s',
                '-adaptation_sets',
                adaptation_sets,
                str(dash_manifest_path),
            ])

            subprocess.run(
                dash_command,
                check=True,
                capture_output=True,
                text=True,
            )

            output_qc = _run_output_qc(
                output_root=output_root,
                dash_manifest_path=dash_manifest_path,
                selected_renditions=selected_renditions,
                expected_duration=duration_for_per_title,
            )

            metadata = dict(
                analysis_report.technical_metadata or {}
            )

            metadata['output_qc_v1'] = output_qc

            analysis_report.technical_metadata = metadata
            analysis_report.save(
                update_fields=[
                    'technical_metadata',
                    'updated_at',
                ]
            )

            if _processing_enabled():
                _store_processing_hls_tree(job_id, output_root)
                _store_processing_dash_tree(job_id, dash_root)

            uploaded_urls = _upload_hls_tree(asset, output_root)
            uploaded_dash_urls = _upload_dash_tree(asset, dash_root)

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
            asset.dash_manifest_url = uploaded_dash_urls.get('manifest.mpd', '')
            asset.status = 'ready'
            asset.save(
                update_fields=[
                    'hls_master_url',
                    'dash_manifest_url',
                    'status',
                    'updated_at',
                ]
            )

            return {
                'asset_id': str(asset.id),
                'hls_master_url': asset.hls_master_url,
                'dash_manifest_url': asset.dash_manifest_url,
                'output_qc': output_qc,
            }
        except Exception:
            asset.status = 'failed'
            asset.save(update_fields=['status', 'updated_at'])
            raise
