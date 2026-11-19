"""Compare packet QC implementations on a local master, without DB writes."""

import json
import statistics
import time
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

from django.core.management.base import BaseCommand, CommandError


class Command(BaseCommand):
    help = "Compare legacy parallel probes and one shared scan of a local video."
    requires_system_checks = []

    def add_arguments(self, parser):
        parser.add_argument("source", type=Path)
        parser.add_argument("--repetitions", type=int, default=3)

    def handle(self, *args, **options):
        from apps.streaming.packet_probe import probe_video_packets
        from apps.streaming.tasks import _probe_frame_timing, _probe_keyframe_intervals

        source = options["source"]
        repetitions = options["repetitions"]
        if not source.is_file():
            raise CommandError("source must be an existing local video file")
        if not 1 <= repetitions <= 10:
            raise CommandError("repetitions must be between 1 and 10")

        def legacy():
            with ThreadPoolExecutor(max_workers=2) as pool:
                keys = pool.submit(_probe_keyframe_intervals, source)
                timing = pool.submit(_probe_frame_timing, source)
                return keys.result(), timing.result()

        runners = {
            "legacy_parallel": legacy,
            "shared": lambda: probe_video_packets(source),
        }
        samples = {mode: [] for mode in runners}
        reference = None
        for repetition in range(repetitions):
            # Alternate execution order to reduce cache/order bias.
            modes = list(runners)
            if repetition % 2:
                modes.reverse()
            for mode in modes:
                started = time.perf_counter()
                result = runners[mode]()
                samples[mode].append(time.perf_counter() - started)
                if not all(report["available"] for report in result):
                    raise CommandError(f"{mode}: unavailable QC; benchmark is invalid")
                if reference is None:
                    reference = result
                if result != reference:
                    raise CommandError("QC results differ; do not deploy this optimization")

        medians = {mode: statistics.median(values) for mode, values in samples.items()}
        self.stdout.write(json.dumps({
            "source_name": source.name,
            "size_bytes": source.stat().st_size,
            "repetitions": repetitions,
            "qc_equal": True,
            "frame_count": reference[1]["frame_count"],
            "keyframe_count": reference[0]["keyframe_count"],
            "samples_seconds": samples,
            "median_seconds": medians,
            "shared_reduction_percent": round(
                100 * (1 - medians["shared"] / medians["legacy_parallel"]), 2,
            ),
            "scope": "packet probes only; excludes upload, materialization, QC decode and AI",
        }, indent=2))
