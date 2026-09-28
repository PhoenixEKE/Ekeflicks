"""Packet QC calculations and a shared, non-decoding FFprobe scan."""

import subprocess
import tempfile


def _frame_lines_and_keyframes(stream, keyframe_lines):
    """Retain keyframes while streaming the same CSV fields as legacy probes.

    FFprobe emits pts_time, dts_time, duration_time, flags in packet field order.
    Extra side-data columns are ignored, as in the existing individual probes.
    Real FFprobe equivalence tests cover this wire format.
    """
    for line in stream:
        values = line.strip().split(",", 4)
        if len(values) < 4:
            continue
        pts, dts, _, flags = values[:4]
        if "K" in flags:
            keyframe_lines.append(f"{pts},{dts},{flags}")
        # Reuse the fields: splitting the same packet twice costs more than
        # the saved scan for small, highly compressed masters.
        yield values


def probe_video_packets(source_input):
    """Return (keyframe QC, frame timing QC) from one complete packet scan.

    FFprobe writes into an automatically removed temporary file instead of
    retaining two full stdout strings in RAM. Parsing still retains numeric
    samples for the existing exact median and timestamp fallback calculations.
    A failed or timed-out scan discards all partial observations.
    """
    command = [
        "ffprobe", "-v", "error", "-select_streams", "v:0",
        "-show_packets", "-show_entries",
        "packet=pts_time,dts_time,duration_time,flags",
        "-of", "csv=p=0", str(source_input),
    ]
    try:
        with tempfile.TemporaryFile(mode="w+t", encoding="utf-8") as output:
            subprocess.run(
                command, stdout=output, stderr=subprocess.DEVNULL,
                check=True, timeout=180,
            )
            output.seek(0)
            keyframe_lines = []
            frame_timing = frame_timing_from_lines(
                _frame_lines_and_keyframes(output, keyframe_lines),
                fields_are_split=True,
            )
            keyframes = keyframes_from_lines(keyframe_lines)
            return keyframes, frame_timing
    except (subprocess.SubprocessError, OSError):
        return {
            "available": False,
            "keyframe_count": 0,
            "timestamps": [],
            "max_interval_seconds": None,
            "average_interval_seconds": None,
            "probe_source": "packets",
        }, frame_timing_from_lines(())


def frame_timing_from_lines(packet_lines, *, fields_are_split=False):
    timestamp_limit = 500

    def unavailable(
        frame_count=0,
        timestamps=None,
    ):
        return {
            "available": False,
            "frame_count": frame_count,
            "is_constant": None,
            "median_delta_seconds": None,
            "min_delta_seconds": None,
            "max_delta_seconds": None,
            "max_deviation_seconds": None,
            "relative_max_deviation": None,
            "timestamps": [
                round(value, 6)
                for value in (
                    timestamps or []
                )[:timestamp_limit]
            ],
            "timestamps_truncated": (
                frame_count > timestamp_limit
            ),
            "probe_source": "packets",
        }

    timestamps = []
    durations = []

    for raw_line in packet_lines:
        if fields_are_split:
            values = raw_line
        else:
            line = raw_line.strip()
            if not line:
                continue
            values = [value.strip() for value in line.split(",")]

        while len(values) < 3:
            values.append("")

        raw_pts = values[0]
        raw_dts = values[1]
        raw_duration = values[2]

        timestamp = None

        for candidate in (
            raw_pts,
            raw_dts,
        ):
            if candidate in {
                "",
                "N/A",
            }:
                continue

            try:
                timestamp = float(
                    candidate
                )
                break
            except (
                TypeError,
                ValueError,
            ):
                continue

        if timestamp is not None:
            timestamps.append(
                timestamp
            )

        if raw_duration not in {
            "",
            "N/A",
        }:
            try:
                duration = float(
                    raw_duration
                )
            except (
                TypeError,
                ValueError,
            ):
                duration = None

            if (
                duration is not None
                and duration > 0
            ):
                durations.append(
                    duration
                )

    frame_count = len(timestamps)

    if frame_count < 3:
        return unavailable(
            frame_count,
            timestamps,
        )

    # Packet PTS/DTS may be emitted in decode order.
    # With B-frames this order is legitimately non-monotonic,
    # so adjacent packet timestamps must not be interpreted as
    # presentation-frame intervals.
    #
    # When FFprobe provides a positive duration for every
    # observed video packet, packet duration is the direct
    # temporal observation used for CFR/VFR verification.
    #
    # The historical timestamp-delta path remains the fallback
    # for inputs where packet durations are incomplete.
    ordered = timestamps

    complete_packet_durations = (
        len(durations) == frame_count
        and frame_count >= 3
    )

    if complete_packet_durations:
        deltas = durations
        timing_observation_source = (
            "packet_duration"
        )
    else:
        deltas = [
            ordered[index]
            - ordered[index - 1]
            for index in range(
                1,
                len(ordered),
            )
            if (
                ordered[index]
                - ordered[index - 1]
            ) > 0
        ]
        timing_observation_source = (
            "timestamp_delta"
        )

    if len(deltas) < 2:
        return unavailable(
            frame_count,
            ordered,
        )

    sorted_deltas = sorted(deltas)
    count = len(sorted_deltas)
    middle = count // 2

    if count % 2:
        median_delta = (
            sorted_deltas[middle]
        )
    else:
        median_delta = (
            sorted_deltas[middle - 1]
            + sorted_deltas[middle]
        ) / 2.0

    tolerance_seconds = max(
        0.002,
        median_delta * 0.05,
    )

    min_delta = min(deltas)
    max_delta = max(deltas)

    max_deviation = max(
        abs(
            delta - median_delta
        )
        for delta in deltas
    )

    is_constant = (
        max_deviation
        <= tolerance_seconds
    )

    relative_max_deviation = (
        max_deviation
        / median_delta
        if median_delta > 0
        else None
    )

    return {
        "available": True,
        "frame_count": frame_count,
        "is_constant": is_constant,
        "median_delta_seconds": round(
            median_delta,
            6,
        ),
        "min_delta_seconds": round(
            min_delta,
            6,
        ),
        "max_delta_seconds": round(
            max_delta,
            6,
        ),
        "max_deviation_seconds": round(
            max_deviation,
            6,
        ),
        "relative_max_deviation": (
            round(
                relative_max_deviation,
                6,
            )
            if relative_max_deviation
            is not None
            else None
        ),
        "tolerance_seconds": round(
            tolerance_seconds,
            6,
        ),
        "timestamps": [
            round(value, 6)
            for value in ordered[
                :timestamp_limit
            ]
        ],
        "timestamps_truncated": (
            len(ordered)
            > timestamp_limit
        ),
        "probe_source": "packets",
        "timing_observation_source": (
            timing_observation_source
        ),
        "packet_duration_samples": (
            len(durations)
        ),
    }



def keyframes_from_lines(packet_lines):
    timestamps = []

    for raw_line in packet_lines:
        line = raw_line.strip()

        if not line:
            continue

        values = [
            value.strip()
            for value in line.split(",")
        ]

        while len(values) < 3:
            values.append("")

        raw_pts = values[0]
        raw_dts = values[1]
        flags = values[2]

        if "K" not in flags:
            continue

        raw_timestamp = None

        for candidate in (
            raw_pts,
            raw_dts,
        ):
            if candidate not in {
                "",
                "N/A",
            }:
                raw_timestamp = candidate
                break

        if raw_timestamp is None:
            continue

        try:
            value = float(
                raw_timestamp
            )
        except (
            TypeError,
            ValueError,
        ):
            continue

        if value < 0:
            continue

        timestamps.append(value)

    timestamps = sorted(
        set(timestamps)
    )

    intervals = [
        round(
            timestamps[index]
            - timestamps[index - 1],
            6,
        )
        for index in range(
            1,
            len(timestamps),
        )
        if (
            timestamps[index]
            - timestamps[index - 1]
        ) >= 0
    ]

    max_interval = (
        round(
            max(intervals),
            6,
        )
        if intervals
        else None
    )

    average_interval = (
        round(
            sum(intervals)
            / len(intervals),
            6,
        )
        if intervals
        else None
    )

    return {
        "available": bool(
            timestamps
        ),
        "keyframe_count": len(
            timestamps
        ),
        "timestamps": [
            round(value, 6)
            for value in timestamps[:500]
        ],
        "timestamps_truncated": (
            len(timestamps) > 500
        ),
        "max_interval_seconds": (
            max_interval
        ),
        "average_interval_seconds": (
            average_interval
        ),
        "probe_source": "packets",
    }
