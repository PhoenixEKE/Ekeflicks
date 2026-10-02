import json
import shutil
from io import StringIO
from unittest import skipUnless

from django.core.management import call_command
from django.test import SimpleTestCase


@skipUnless(shutil.which("ffmpeg") and shutil.which("ffprobe"), "FFmpeg required")
class BenchmarkVideoPipelineCommandTests(SimpleTestCase):
    def test_synthetic_benchmark_runs_without_database_access(self):
        output = StringIO()
        call_command(
            "benchmark_video_pipeline",
            "--synthetic",
            "--duration-seconds", "12",
            "--width", "160",
            "--height", "90",
            "--fps", "5",
            "--skip-moderation",
            stdout=output,
        )

        result = json.loads(output.getvalue())
        self.assertTrue(result["synthetic"])
        self.assertFalse(result["database_writes"])
        self.assertFalse(result["upload_and_storage_download_measured"])
        self.assertEqual(result["duration_seconds"], 12.0)
        self.assertGreater(result["source_size_bytes"], 0)
        self.assertTrue(result["packet_probe_available"])
        self.assertGreater(result["moderation_frames_extracted"], 0)
