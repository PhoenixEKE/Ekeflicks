"""Measure the video analysis stages without creating or changing database rows."""

import json
import subprocess
import tempfile
import time
from pathlib import Path

from django.core.management.base import BaseCommand, CommandError
from huggingface_hub import hf_hub_download


class Command(BaseCommand):
    help = "Benchmark local video analysis stages without database writes."
    requires_system_checks = []

    def add_arguments(self, parser):
        parser.add_argument("source", nargs="?", type=Path)
        parser.add_argument("--synthetic", action="store_true")
        parser.add_argument("--duration-seconds", type=int, default=2400)
        parser.add_argument("--width", type=int, default=1920)
        parser.add_argument("--height", type=int, default=1080)
        parser.add_argument("--fps", type=int, default=25)
        parser.add_argument("--crf", type=int, default=30)
        parser.add_argument("--skip-moderation", action="store_true")

    def handle(self, *args, **options):
        from apps.streaming.ai_moderation import (
            DEFAULT_SAMPLE_INTERVAL_SECONDS,
            analyze_moderation_frames,
            load_moderation_session,
        )
        from apps.streaming.packet_probe import probe_video_packets
        from apps.streaming.tasks import QC_DETECTION_FPS, _run_advanced_qc

        source = options["source"]
        synthetic = options["synthetic"]
        if synthetic == (source is not None):
            raise CommandError("provide either SOURCE or --synthetic")
        if synthetic:
            duration = options["duration_seconds"]
            width, height, fps = options["width"], options["height"], options["fps"]
            if duration < 12 or duration > 7200:
                raise CommandError("synthetic duration must be between 12 and 7200 seconds")
            if width < 160 or width > 3840 or height < 90 or height > 2160:
                raise CommandError("synthetic resolution must be between 160x90 and 3840x2160")
            if fps < 1 or fps > 60 or options["crf"] < 0 or options["crf"] > 51:
                raise CommandError("fps must be 1–60 and CRF must be 0–51")
        elif not source.is_file():
            raise CommandError("SOURCE must be an existing local video file")

        with tempfile.TemporaryDirectory(prefix="eke-video-benchmark-") as temporary:
            root = Path(temporary)
            generation_seconds = None
            if synthetic:
                source = root / "synthetic-master.mp4"
                generation_started = time.monotonic()
                self._generate_synthetic(
                    source,
                    duration=duration,
                    width=width,
                    height=height,
                    fps=fps,
                    crf=options["crf"],
                )
                generation_seconds = round(time.monotonic() - generation_started, 3)

            result = {
                "synthetic": synthetic,
                "source_name": source.name,
                "source_size_bytes": source.stat().st_size,
                "duration_target_seconds": duration if synthetic else None,
                "resolution_target": f"{width}x{height}" if synthetic else None,
                "fps_target": fps if synthetic else None,
                "generation_seconds_excluded_from_analysis": generation_seconds,
                "database_writes": False,
                "upload_and_storage_download_measured": False,
            }

            analysis_started = time.monotonic()
            probe_started = time.monotonic()
            metadata_result = subprocess.run(
                [
                    "ffprobe", "-v", "error", "-show_format", "-show_streams",
                    "-of", "json", str(source),
                ],
                capture_output=True,
                text=True,
                check=True,
                timeout=300,
            )
            metadata = json.loads(metadata_result.stdout or "{}")
            result["initial_ffprobe_seconds"] = round(time.monotonic() - probe_started, 3)
            streams = metadata.get("streams") or []
            video = next((stream for stream in streams if stream.get("codec_type") == "video"), None)
            audio = next((stream for stream in streams if stream.get("codec_type") == "audio"), None)
            if not video:
                raise CommandError("the benchmark source has no video stream")
            result["duration_seconds"] = self._float_or_none(
                (metadata.get("format") or {}).get("duration") or video.get("duration")
            )
            result["video"] = {
                "codec": video.get("codec_name"),
                "width": video.get("width"),
                "height": video.get("height"),
                "frame_rate": video.get("avg_frame_rate"),
            }
            result["audio_present"] = audio is not None

            frames_dir = root / "moderation-frames"
            qc_started = time.monotonic()
            qc, events = _run_advanced_qc(
                source,
                has_video=True,
                has_audio=audio is not None,
                moderation_output_dir=frames_dir,
            )
            result["advanced_qc_with_frame_extraction_seconds"] = round(
                time.monotonic() - qc_started, 3
            )
            result["qc"] = qc
            result["event_count"] = len(events)
            frame_paths = sorted(frames_dir.glob("frame_*.jpg"))
            result["moderation_frames_extracted"] = len(frame_paths)

            if not options["skip_moderation"]:
                model_started = time.monotonic()
                model_path = hf_hub_download(
                    repo_id="OwenElliott/image-safety-classifier-xs",
                    filename="onnx/image-safety-classifier-xs.onnx",
                )
                result["moderation_model_resolve_seconds"] = round(
                    time.monotonic() - model_started, 3
                )
                model_started = time.monotonic()
                session = load_moderation_session(model_path)
                result["moderation_model_load_seconds"] = round(
                    time.monotonic() - model_started, 3
                )
                moderation_frames = [
                    {"path": path, "timestamp": float(index * DEFAULT_SAMPLE_INTERVAL_SECONDS)}
                    for index, path in enumerate(frame_paths)
                ]
                inference_started = time.monotonic()
                moderation = analyze_moderation_frames(session, moderation_frames)
                result["moderation_inference_seconds"] = round(
                    time.monotonic() - inference_started, 3
                )
                result["moderation_frames_analyzed"] = moderation["scores"].get("frames_analyzed", 0)

            packet_started = time.monotonic()
            keyframes, timing = probe_video_packets(source)
            result["shared_packet_probe_seconds"] = round(time.monotonic() - packet_started, 3)
            result["packet_probe_available"] = bool(keyframes.get("available") and timing.get("available"))
            result["total_local_analysis_seconds"] = round(
                time.monotonic() - analysis_started, 3
            )
            result["scope"] = (
                "Synthetic/local analysis only: excludes producer upload, object-storage download, "
                "source materialization and database commit. QC/AI/FFprobe do not update database rows."
            )
            self.stdout.write(json.dumps(result, ensure_ascii=False, indent=2))

    @staticmethod
    def _float_or_none(value):
        try:
            return round(float(value), 3)
        except (TypeError, ValueError):
            return None

    @staticmethod
    def _generate_synthetic(path, *, duration, width, height, fps, crf):
        # A moving test pattern exercises full-frame decoding. The filters add
        # one long black segment, a final freeze and a silent audio interval.
        video_duration = duration - 4
        half = duration // 2
        video_filter = (
            "drawbox=x=0:y=0:w=iw:h=ih:color=black:t=fill:"
            f"enable='between(t,{max(5, half - 5)},{half})',"
            "tpad=stop_mode=clone:stop_duration=4"
        )
        audio_filter = f"volume=0:enable='between(t,{max(10, duration // 4)},{max(20, duration // 4 + 10)})'"
        command = [
            "ffmpeg", "-hide_banner", "-loglevel", "error", "-y",
            "-f", "lavfi", "-i",
            f"testsrc2=size={width}x{height}:rate={fps}:duration={video_duration}",
            "-f", "lavfi", "-i",
            f"sine=frequency=440:sample_rate=48000:duration={duration}",
            "-vf", video_filter, "-af", audio_filter,
            "-t", str(duration), "-c:v", "libx264", "-preset", "ultrafast",
            "-crf", str(crf), "-threads", "2", "-g", str(fps * 10), "-bf", "3",
            "-c:a", "aac", "-b:a", "128k", str(path),
        ]
        try:
            subprocess.run(command, check=True, timeout=1800)
        except (subprocess.SubprocessError, OSError) as exc:
            raise CommandError(f"synthetic video generation failed: {exc}") from exc
