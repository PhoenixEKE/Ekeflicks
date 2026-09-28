import re
import shutil
import subprocess
import tempfile
from pathlib import Path
from unittest import skipUnless

from django.test import SimpleTestCase

from apps.streaming.tasks import _run_advanced_qc


@skipUnless(shutil.which("ffmpeg"), "FFmpeg required")
class VideoQcSamplingTests(SimpleTestCase):
    def _full_resolution_events(self, source):
        process = subprocess.run(
            [
                "ffmpeg", "-hide_banner", "-nostats", "-i", str(source),
                "-map", "0:v:0", "-vf",
                "blackdetect=d=2.0:pix_th=0.10,freezedetect=n=-50dB:d=3.0",
                "-an", "-f", "null", "-",
            ],
            capture_output=True, text=True, check=True, timeout=60,
        )
        black = [
            tuple(map(float, match))
            for match in re.findall(
                r"black_start:([\d.]+)\s+black_end:([\d.]+)\s+black_duration:([\d.]+)",
                process.stderr,
            )
        ]
        starts = list(map(float, re.findall(r"freeze_start:\s*([\d.]+)", process.stderr)))
        ends = list(map(float, re.findall(r"freeze_end:\s*([\d.]+)", process.stderr)))
        return black, starts, ends

    def test_5fps_qc_preserves_long_black_and_freeze_events(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            source = root / "master.mp4"
            moderation_frames = root / "moderation"
            subprocess.run(
                [
                    "ffmpeg", "-v", "error", "-f", "lavfi", "-i",
                    "testsrc2=size=1920x1080:rate=30:duration=12",
                    "-vf",
                    "drawbox=x=0:y=0:w=iw:h=ih:color=black:t=fill:enable='between(t,3.17,5.97)',tpad=stop_mode=clone:stop_duration=4.2",
                    "-an", "-c:v", "libx264", "-preset", "ultrafast",
                    "-crf", "30", "-threads", "4", "-y", str(source),
                ],
                check=True, timeout=120,
            )
            expected_black, expected_starts, expected_ends = self._full_resolution_events(source)
            qc, events = _run_advanced_qc(
                source,
                has_video=True,
                has_audio=False,
                moderation_output_dir=moderation_frames,
            )

            actual_black = [event for event in events if event["type"] == "black"]
            actual_freeze = [event for event in events if event["type"] == "freeze"]
            self.assertEqual(len(actual_black), len(expected_black))
            self.assertEqual(len(actual_freeze), len(expected_starts))
            for actual, expected in zip(actual_black, expected_black):
                self.assertLessEqual(abs(actual["start"] - expected[0]), 0.2)
                self.assertLessEqual(abs(actual["end"] - expected[1]), 0.2)
            for actual, expected in zip(actual_freeze, expected_starts):
                self.assertLessEqual(abs(actual["start"] - expected), 0.2)
            for actual, expected in zip(actual_freeze, expected_ends):
                self.assertIn("end", actual)
                self.assertLessEqual(abs(actual["end"] - expected), 0.2)
            self.assertEqual(qc["black_events"], len(expected_black))
            self.assertEqual(qc["freeze_events"], len(expected_starts))
            self.assertGreater(len(list(moderation_frames.glob("frame_*.jpg"))), 0)
