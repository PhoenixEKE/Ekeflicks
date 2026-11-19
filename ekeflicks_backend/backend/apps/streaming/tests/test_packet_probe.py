import shutil
import subprocess
import tempfile
from pathlib import Path
from unittest import TestCase, skipUnless
from unittest.mock import patch

from apps.streaming.packet_probe import (
    frame_timing_from_lines, keyframes_from_lines,
    probe_video_packets,
)


class SharedPacketProbeTests(TestCase):
    def run_rows(self, rows):
        # Named fixture fields make missing values explicit; the real wire
        # format is CSV and is also exercised by RealPacketProbeTests.
        fields = ("pts_time", "dts_time", "duration_time", "flags")
        csv_rows = []
        for line in rows.splitlines():
            values = dict(part.split("=", 1) for part in line.split("|") if "=" in part)
            if not any(field in values for field in fields):
                csv_rows.append("")
                continue
            csv_rows.append(",".join(values.get(field, "N/A") for field in fields))
        def run(command, **kwargs):
            kwargs["stdout"].write("\n".join(csv_rows))
        with patch("apps.streaming.packet_probe.subprocess.run", side_effect=run) as call:
            result = probe_video_packets("/tmp/master.mp4")
        call.assert_called_once()
        self.assertEqual(call.call_args.kwargs["timeout"], 180)
        self.assertNotIn("-show_frames", call.call_args.args[0])
        return result

    def test_cfr_and_keyframes_share_one_scan(self):
        rows = "\n".join([
            "flags=K__|duration_time=0.04|pts_time=0|dts_time=-0.04|side_data_type=test",
            "pts_time=0.04|flags=___|dts_time=0|duration_time=0.04",
            "pts_time=0.08|dts_time=0.04|duration_time=0.04|flags=K__",
            "side_data_type=unrelated",
        ])
        keyframes, timing = self.run_rows(rows)
        self.assertTrue(timing["is_constant"])
        self.assertEqual(timing["frame_count"], 3)
        self.assertEqual(keyframes["timestamps"], [0.0, 0.08])
        self.assertEqual(keyframes["max_interval_seconds"], 0.08)

    def test_cfr_with_b_frames(self):
        rows = "\n".join(
            f"pts_time={pts}|dts_time={i * .04}|duration_time=.04|flags=K__"
            for i, pts in enumerate([0, .12, .04, .08, .24, .16, .20])
        )
        _, timing = self.run_rows(rows)
        self.assertTrue(timing["is_constant"])
        self.assertEqual(timing["timing_observation_source"], "packet_duration")

    def test_partial_durations_and_missing_pts_keep_fallback(self):
        rows = "\n".join([
            "pts_time=N/A|dts_time=0|duration_time=.04|flags=K__",
            "pts_time=.04|dts_time=.04|duration_time=N/A|flags=___",
            "pts_time=.12|dts_time=.12|duration_time=.04|flags=K__",
        ])
        _, timing = self.run_rows(rows)
        self.assertEqual(timing["timing_observation_source"], "timestamp_delta")
        self.assertFalse(timing["is_constant"])

    def test_anomaly_after_report_limit_is_detected(self):
        rows = "\n".join(
            f"pts_time={i * .04}|duration_time={'.08' if i == 1200 else '.04'}|flags=K__"
            for i in range(1500)
        )
        keyframes, timing = self.run_rows(rows)
        self.assertFalse(timing["is_constant"])
        self.assertEqual(timing["frame_count"], 1500)
        self.assertEqual(len(timing["timestamps"]), 500)
        self.assertTrue(keyframes["timestamps_truncated"])

    def test_projection_preserves_existing_numeric_decisions(self):
        rows = ["0,0,.04,K__", ".12,.04,.04,___", ".04,.08,N/A,___", ".08,.12,.04,K__"]
        compact = "\n".join("|".join(f"{k}={v}" for k, v in zip(
            ["pts_time", "dts_time", "duration_time", "flags"], row.split(","),
        )) for row in rows)
        keyframes, timing = self.run_rows(compact)
        self.assertEqual(timing, frame_timing_from_lines(row.rsplit(",", 1)[0] for row in rows))
        self.assertEqual(keyframes, keyframes_from_lines(
            ",".join([parts[0], parts[1], parts[3]]) for parts in map(lambda x: x.split(","), rows)
        ))

    def test_failed_scan_discards_partial_data_and_closes_output(self):
        for error in (subprocess.TimeoutExpired("ffprobe", 180),
                      subprocess.CalledProcessError(1, "ffprobe"), OSError("missing")):
            with self.subTest(error=type(error).__name__):
                outputs = []
                def fail(command, **kwargs):
                    outputs.append(kwargs["stdout"])
                    kwargs["stdout"].write("0,0,.04,K__\n" * 3)
                    raise error
                with patch("apps.streaming.packet_probe.subprocess.run", side_effect=fail):
                    keyframes, timing = probe_video_packets("master.mp4")
                self.assertFalse(keyframes["available"])
                self.assertFalse(timing["available"])
                self.assertEqual(timing["frame_count"], 0)
                self.assertTrue(outputs[0].closed)

    def test_empty_scan_is_unavailable(self):
        keyframes, timing = self.run_rows("")
        self.assertFalse(keyframes["available"])
        self.assertFalse(timing["available"])


@skipUnless(shutil.which("ffmpeg") and shutil.which("ffprobe"), "FFmpeg required")
class RealPacketProbeTests(TestCase):
    def test_real_cfr_b_frames_and_vfr_match_two_scans(self):
        from apps.streaming.tasks import _probe_frame_timing, _probe_keyframe_intervals
        with tempfile.TemporaryDirectory() as tmp:
            for name, size, extra in (
                ("cfr", "160x90", ["-bf", "0"]),
                ("bframes", "160x90", ["-bf", "3"]),
                ("vfr", "160x90", ["-vf", "setpts='if(lt(N,25),N,25+(N-25)*2)/(25*TB)'", "-fps_mode", "vfr"]),
                ("uhd", "3840x2160", ["-preset", "ultrafast"]),
            ):
                with self.subTest(name=name):
                    source = Path(tmp) / f"{name}.mp4"
                    subprocess.run([
                        "ffmpeg", "-v", "error", "-f", "lavfi", "-i",
                        f"testsrc2=size={size}:rate=25:duration=3", "-c:v", "libx264",
                        "-threads", "1", "-g", "25", *extra, str(source),
                    ], check=True, timeout=30)
                    actual = probe_video_packets(source)
                    expected = (_probe_keyframe_intervals(source), _probe_frame_timing(source))
                    self.assertEqual(actual, expected)
                    self.assertTrue(actual[0]["available"])
                    self.assertTrue(actual[1]["available"])
